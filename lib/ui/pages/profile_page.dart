import 'package:flutter/material.dart';

import '../../engine/body_type.dart';
import '../../engine/scoring.dart';
import '../../models/models.dart';
import '../../services/app_files.dart';
import '../../state/wardrobe_store.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';
import 'skin_quiz.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _femaleTypes = ['沙漏型', '梨形', '苹果形', '矩形', '倒三角'];
  static const _maleTypes = ['梯形', '倒三角', '矩形', '椭圆', '梨形'];
  static const _skinSeasons = ['春季型', '夏季型', '秋季型', '冬季型'];
  static const _tabooOptions = ['皮草', '皮革', '羽绒', '紧身', '高露肤', '荧光色', '动物纹', '亮片'];

  final _chestCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _hipCtrl = TextEditingController();
  bool _syncedMeasurements = false;

  @override
  void dispose() {
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    super.dispose();
  }

  void _update(
    WardrobeStore store, {
    String? gender,
    String? bodyType,
    String? skinSeason,
    List<String>? stylePref,
    List<String>? taboo,
    double? chestCm,
    double? waistCm,
    double? hipCm,
  }) {
    store.updateProfile(store.profile.copyWith(
      gender: gender,
      bodyType: bodyType,
      skinSeason: skinSeason,
      stylePref: stylePref,
      taboo: taboo,
      chestCm: chestCm,
      waistCm: waistCm,
      hipCm: hipCm,
    ));
  }

  void _openQuiz(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const SkinQuizSheet(),
    );
  }

  void _autoInfer(WardrobeStore store) {
    final chest = double.tryParse(_chestCtrl.text.trim());
    final waist = double.tryParse(_waistCtrl.text.trim());
    final hip = double.tryParse(_hipCtrl.text.trim());
    if (chest == null || waist == null || hip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请完整填写胸围 / 腰围 / 臀围')));
      return;
    }
    final type = inferBodyType(
        gender: store.profile.gender, chest: chest, waist: waist, hip: hip);
    _update(store,
        chestCm: chest, waistCm: waist, hipCm: hip, bodyType: type);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('已自动判型：$type（可手动修正）')));
  }

  /// 保存档案：把三围输入持久化（其余项改动已即时保存；留空的测量项保留原值）
  void _saveProfile(WardrobeStore store) {
    final chest = double.tryParse(_chestCtrl.text.trim());
    final waist = double.tryParse(_waistCtrl.text.trim());
    final hip = double.tryParse(_hipCtrl.text.trim());
    store.updateProfile(store.profile.copyWith(
      chestCm: chest,
      waistCm: waist,
      hipCm: hip,
    ));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('档案已保存')));
  }

  /// 档案加载完成后，把已存的三围同步进输入框（只执行一次）
  void _syncMeasurements(UserProfile p) {
    if (_syncedMeasurements || p.chestCm == null) return;
    _syncedMeasurements = true;
    final cv = p.chestCm!.toStringAsFixed(0);
    final wv = p.waistCm!.toStringAsFixed(0);
    final hv = p.hipCm!.toStringAsFixed(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _chestCtrl.text = cv;
      _waistCtrl.text = wv;
      _hipCtrl.text = hv;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = WardrobeStore.instance;
    return SafeArea(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final p = store.profile;
          final c = store.config;
          _syncMeasurements(p);
          final types = p.gender == 'male' ? _maleTypes : _femaleTypes;
          final styleNames = store.styles
              .where((s) => s.gender == p.gender || s.gender == 'unisex')
              .map((s) => s.name)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
            children: [
              const SectionHeader(eyebrow: 'PROFILE', title: '个人档案'),
              const SizedBox(height: AppSpacing.md),
              _card('性别', Wrap(spacing: 8, children: [
                TagChip(
                    label: '女',
                    selected: p.gender == 'female',
                    onTap: () => _update(store, gender: 'female')),
                TagChip(
                    label: '男',
                    selected: p.gender == 'male',
                    onTap: () => _update(store, gender: 'male')),
              ])),
              const SizedBox(height: 12),
              _card('体型', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: _numField(_chestCtrl, '胸围')),
                  const SizedBox(width: 8),
                  Expanded(child: _numField(_waistCtrl, '腰围')),
                  const SizedBox(width: 8),
                  Expanded(child: _numField(_hipCtrl, '臀围')),
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => _autoInfer(store),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.claySoft,
                      foregroundColor: AppColors.clayInk,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('按三围自动判型'),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final b in types)
                    TagChip(
                        label: b,
                        selected: p.bodyType == b,
                        onTap: () => _update(store, bodyType: b)),
                ]),
                const SizedBox(height: 8),
                const Text('单位 cm，自动判型后可直接点选标签修正',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ])),
              const SizedBox(height: 12),
              _card('肤色季型', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final s in _skinSeasons)
                    TagChip(
                        label: s,
                        selected: p.skinSeason == s,
                        onTap: () => _update(store, skinSeason: s)),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => _openQuiz(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.claySoft,
                      foregroundColor: AppColors.clayInk,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('开始诊断 · 8 道题定色系'),
                  ),
                ),
              ])),
              const SizedBox(height: 12),
              _card('风格偏好', Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in styleNames)
                  TagChip(
                      label: s,
                      selected: p.stylePref.contains(s),
                      onTap: () {
                        final next = List<String>.from(p.stylePref);
                        if (next.contains(s)) {
                          next.remove(s);
                        } else {
                          next.add(s);
                        }
                        _update(store, stylePref: next);
                      }),
              ])),
              const SizedBox(height: 12),
              _card('禁忌（参与硬约束过滤）',
                  Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in _tabooOptions)
                  TagChip(
                      label: t,
                      selected: p.taboo.contains(t),
                      onTap: () {
                        final next = List<String>.from(p.taboo);
                        if (next.contains(t)) {
                          next.remove(t);
                        } else {
                          next.add(t);
                        }
                        _update(store, taboo: next);
                      }),
              ])),
              const SizedBox(height: 20),
              const Text('设置',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 12),
              ExpandableCard(
                title: '搭配权重调教',
                subtitle:
                    '色彩 ${(c.color * 100).round()} · 风格 ${(c.style * 100).round()} · 体型 ${(c.bodyType * 100).round()} · 正式 ${(c.formal * 100).round()} · 露肤 ${(c.exposure * 100).round()} · 偏好 ${(c.preference * 100).round()}',
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _weightSlider(store, '色彩和谐度', 'color', c.color),
                      _weightSlider(store, '风格一致性', 'style', c.style),
                      _weightSlider(store, '体型适配度', 'bodyType', c.bodyType),
                      _weightSlider(store, '正式度匹配', 'formal', c.formal),
                      _weightSlider(store, '露肤度', 'exposure', c.exposure),
                      _weightSlider(store, '用户偏好', 'preference', c.preference),
                      const SizedBox(height: 4),
                      Text(
                        '合计 ${((c.color + c.style + c.bodyType + c.formal + c.exposure + c.preference) * 100).toStringAsFixed(0)}%（满分基准 100%）',
                        style: TextStyle(
                            fontSize: 12,
                            color: (c.color +
                                        c.style +
                                        c.bodyType +
                                        c.formal +
                                        c.exposure +
                                        c.preference -
                                        1)
                                    .abs() <
                                0.005
                                ? AppColors.muted
                                : AppColors.clayInk),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              store.updateConfig(const ScoringConfig()),
                          child: const Text('恢复默认'),
                        ),
                      ),
                    ]),
              ),
              const SizedBox(height: 12),
              ExpandableCard(
                title: '知识库热更新',
                subtitle: 'JSON 驱动 · 支持 kb_override 覆盖目录',
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          '风格 / 品类 / 体型规则 / 搭配模板均为 JSON 驱动。把同名 JSON 放入应用文档目录的 kb_override 文件夹，重启或点击下方按钮即生效：',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              height: 1.5)),
                      const SizedBox(height: 6),
                      const Text(
                          'categories.json · styles.json · body_types.json · style_templates.json',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.ink)),
                      const SizedBox(height: 6),
                      FutureBuilder<String>(
                        future: AppFiles.documentsPath(),
                        builder: (context, snap) => Text(
                            '文档目录：${snap.data ?? '…'}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.muted)),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: () async {
                            final changed = await store.resyncKnowledge();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(changed
                                        ? '知识库已重新导入'
                                        : '知识库无变化')));
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.claySoft,
                            foregroundColor: AppColors.clayInk,
                          ),
                          child: const Text('重新导入知识库'),
                        ),
                      ),
                    ]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _saveProfile(store),
                  icon: const Icon(Icons.save_outlined, size: 20),
                  label: const Text('保存档案'),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                  '性别 / 体型 / 肤色 / 偏好 / 禁忌改动即时生效；三围数据点「保存档案」持久化。档案会驱动搭配引擎的性别过滤、体型适配、肤色色域与禁忌排除。',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          );
        },
      ),
    );
  }

  Widget _weightSlider(
      WardrobeStore store, String label, String key, double value) {
    return Row(children: [
      SizedBox(
          width: 88,
          child: Text(label,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.ink))),
      Expanded(
        child: Slider(
          value: value.clamp(0.0, 0.5),
          min: 0,
          max: 0.5,
          divisions: 50,
          activeColor: AppColors.clay,
          onChanged: (v) =>
              store.updateConfig(_withWeight(store.config, key, v)),
        ),
      ),
      SizedBox(
          width: 44,
          child: Text('${(value * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.muted))),
    ]);
  }

  ScoringConfig _withWeight(ScoringConfig c, String key, double v) {
    switch (key) {
      case 'color':
        return ScoringConfig(
            color: v,
            style: c.style,
            bodyType: c.bodyType,
            formal: c.formal,
            exposure: c.exposure,
            preference: c.preference);
      case 'style':
        return ScoringConfig(
            color: c.color,
            style: v,
            bodyType: c.bodyType,
            formal: c.formal,
            exposure: c.exposure,
            preference: c.preference);
      case 'bodyType':
        return ScoringConfig(
            color: c.color,
            style: c.style,
            bodyType: v,
            formal: c.formal,
            exposure: c.exposure,
            preference: c.preference);
      case 'formal':
        return ScoringConfig(
            color: c.color,
            style: c.style,
            bodyType: c.bodyType,
            formal: v,
            exposure: c.exposure,
            preference: c.preference);
      case 'exposure':
        return ScoringConfig(
            color: c.color,
            style: c.style,
            bodyType: c.bodyType,
            formal: c.formal,
            exposure: v,
            preference: c.preference);
      case 'preference':
        return ScoringConfig(
            color: c.color,
            style: c.style,
            bodyType: c.bodyType,
            formal: c.formal,
            exposure: c.exposure,
            preference: v);
    }
    return c;
  }

  Widget _numField(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );

  Widget _card(String title, Widget child) =>
      AppCard(title: title, child: child);
}
