import 'package:flutter/material.dart';

import '../../data/db_helper.dart';
import '../../engine/gap_analysis.dart';
import '../../engine/matching_engine.dart';
import '../../models/models.dart';
import '../../models/style_template.dart';
import '../../state/wardrobe_store.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/template_card.dart';
import 'outfit_detail_sheet.dart';
import 'saved_outfits_page.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  String _occasion = '休闲';
  String? _season;
  String? _temperature;
  Style? _style;
  List<OutfitCandidate> _results = [];
  bool _generated = false;
  List<OutfitCandidate> _dailyPool = const [];
  int _dailyIndex = 0;
  bool _dailyReady = false;
  List<Set<String>> _recentFingerprints = const [];

  static const _occasions = ['休闲', '通勤', '约会', '宴会', '旅行', '运动', '居家', '面试'];
  static const _seasons = ['春', '夏', '秋', '冬'];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  /// 近期打卡/收藏记录 → 指纹，用于「避免重复」降权
  Future<void> _loadRecent() async {
    try {
      final saved = await DatabaseHelper.instance.getSavedOutfits();
      final fps = <Set<String>>[];
      for (final o in saved.take(10)) {
        fps.add(o.slots.map((e) => itemFingerprint(e.$2)).toSet());
      }
      if (mounted) setState(() => _recentFingerprints = fps);
    } catch (e) {
      debugPrint('[爱搭衣] 穿搭记录加载失败: $e');
    }
  }

  void _makeDailyPool() {
    final store = WardrobeStore.instance;
    final engine = MatchingEngine(config: store.config);
    final results = engine.generate(
      wardrobe: store.items,
      profile: store.profile,
      occasion: '休闲',
      avoidFingerprints: _recentFingerprints,
      limit: 12,
    );
    if (!mounted) return;
    setState(() {
      _dailyPool = results;
      _dailyIndex = 0;
    });
    if (results.isNotEmpty) {
      store.recordUsed(results.first.slots.values);
    }
  }

  void _nextDaily() {
    if (_dailyPool.isEmpty) return;
    setState(() => _dailyIndex = (_dailyIndex + 1) % _dailyPool.length);
    WardrobeStore.instance.recordUsed(_dailyPool[_dailyIndex].slots.values);
  }

  void _generate() {
    final store = WardrobeStore.instance;
    final engine = MatchingEngine(config: store.config);
    var wardrobe = store.items;
    // 空衣橱 + 已选风格 → 用风格模板兜底，也能出示例搭配
    if (wardrobe.isEmpty && _selectedTemplate != null) {
      wardrobe = _selectedTemplate!.items
          .map((e) => e.toWardrobeItem(store.profile.gender))
          .toList();
    }
    final results = engine.generate(
      wardrobe: wardrobe,
      profile: store.profile,
      occasion: _occasion,
      targetStyle: _style,
      season: _season,
      temperature: _temperature,
      bodyTypeRules: store.bodyTypeRules,
      avoidFingerprints: _recentFingerprints,
      limit: 8,
    );
    setState(() {
      _results = results;
      _generated = true;
    });
    if (results.isNotEmpty) {
      store.recordUsed(results.expand((r) => r.slots.values));
    }
  }

  StyleTemplate? get _selectedTemplate {
    final style = _style;
    if (style == null) return null;
    final store = WardrobeStore.instance;
    final matches = store.templates
        .where((t) => t.name == style.name && t.gender == store.profile.gender)
        .toList();
    return matches.isEmpty ? null : matches.first;
  }

  void _addTemplate(StyleTemplate t) {
    final store = WardrobeStore.instance;
    final gender = store.profile.gender;
    var added = 0;
    for (final item in t.items) {
      // 去重：同部位 + 同品类 + 同主色视为已有，避免重复堆数据
      final exists = store.items.any((e) =>
          e.slot == item.slot &&
          e.categoryName == item.categoryName &&
          (e.colorMain ?? '').toUpperCase() == item.colorMain.toUpperCase());
      if (exists) continue;
      store.addItem(item.toWardrobeItem(gender));
      added++;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(added == 0
          ? '「${t.name}」的单品都已在衣橱中'
          : '已将「${t.name}」的 $added 件单品加入衣橱'),
    ));
  }

  void _openDetail(OutfitCandidate c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => OutfitDetailSheet(
        candidate: c,
        occasion: _occasion,
        targetStyle: _style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = WardrobeStore.instance;
    final gender = store.profile.gender;
    final styleNames = store.styles
        .where((s) => s.gender == gender || s.gender == 'unisex')
        .toList();

    return SafeArea(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          // 衣橱就绪后自动生成一次今日推荐
          if (store.loaded && !_dailyReady) {
            _dailyReady = true;
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _makeDailyPool());
          }
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: Row(children: [
                    const Expanded(
                        child:
                            SectionHeader(eyebrow: 'MATCH', title: '智能搭配')),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SavedOutfitsPage()),
                      ),
                      icon: const Icon(Icons.bookmarks_outlined),
                      tooltip: '穿搭记录',
                    ),
                  ]),
                ),
              ),
              if (_dailyPool.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Expanded(child: _FieldLabel('今日推荐')),
                            TextButton.icon(
                              onPressed: _nextDaily,
                              icon: const Icon(Icons.shuffle, size: 16),
                              label: const Text('换一套'),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.clay),
                            ),
                          ]),
                          GestureDetector(
                            onTap: () => _openDetail(_dailyPool[_dailyIndex]),
                            child: OutfitCard(candidate: _dailyPool[_dailyIndex]),
                          ),
                        ]),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const _FieldLabel('场合'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in _occasions)
                          TagChip(
                              label: o,
                              selected: _occasion == o,
                              onTap: () => setState(() => _occasion = o)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('季节'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TagChip(
                            label: '不限',
                            selected: _season == null,
                            onTap: () => setState(() => _season = null)),
                        for (final s in _seasons)
                          TagChip(
                              label: s,
                              selected: _season == s,
                              onTap: () => setState(() => _season = s)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('天气'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TagChip(
                            label: '不限',
                            selected: _temperature == null,
                            onTap: () => setState(() => _temperature = null)),
                        for (final t in const ['热', '适中', '凉', '冷'])
                          TagChip(
                              label: t,
                              selected: _temperature == t,
                              onTap: () => setState(() => _temperature = t)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('风格'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TagChip(
                            label: '不限',
                            selected: _style == null,
                            onTap: () => setState(() => _style = null)),
                        for (final s in styleNames)
                          TagChip(
                              label: s.name,
                              selected: _style?.name == s.name,
                              onTap: () => setState(() => _style = s)),
                      ],
                    ),
                    if (_style != null) ...[
                      const SizedBox(height: 14),
                      _gapCard(store),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _generate,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('生成搭配'),
                      ),
                    ),
                  ]),
                ),
              ),
              if (_selectedTemplate != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                  sliver: SliverToBoxAdapter(
                    child: TemplateCard(
                      template: _selectedTemplate!,
                      onAdd: () => _addTemplate(_selectedTemplate!),
                    ),
                  ),
                ),
              if (_generated && _results.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text('没有符合条件的搭配，试试调整条件或先录入衣服',
                          style: TextStyle(color: AppColors.muted)),
                    ),
                  ),
                )
              else if (_results.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final c = _results[i];
                      return GestureDetector(
                        onTap: () => _openDetail(c),
                        child: OutfitCard(candidate: c),
                      );
                    },
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          );
        },
      ),
    );
  }
  Widget _gapCard(WardrobeStore store) {
    final style = _style!;
    final wardrobe = store.items.where(
        (i) => i.gender == store.profile.gender || i.gender == 'unisex');
    final names = wardrobe
        .map((e) => e.categoryName)
        .where((n) => n.isNotEmpty)
        .toSet();
    final missing = missingForStyle(style, wardrobe);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('「${style.name}」常备单品核查',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final req in style.requiredItems)
              _gapChip(req, categorySatisfied(req, names)),
          ],
        ),
        const SizedBox(height: 8),
        if (missing.isNotEmpty)
          Text('还缺 ${missing.length} 件：${missing.join('、')}，补齐后搭配更完整',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.clayInk, height: 1.4))
        else
          const Text('常备单品齐全 ✓',
              style: TextStyle(fontSize: 12, color: AppColors.good)),
      ]),
    );
  }

      Widget _gapChip(String label, bool ok) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ok ? Colors.transparent : AppColors.claySoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ok ? AppColors.line : AppColors.claySoft),
        ),
        child: Text('${ok ? '✓ ' : '缺 '}$label',
            style: TextStyle(
                fontSize: 12,
                color: ok ? AppColors.muted : AppColors.clayInk)),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink));
}
