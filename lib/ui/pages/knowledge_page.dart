import 'package:flutter/material.dart';

import '../../core/color_harmony.dart';
import '../../data/knowledge_loader.dart';
import '../../engine/skin_season.dart';
import '../../state/wardrobe_store.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

/// 配色盘交互工具 + 知识内容（配色法则 / 体型指南 / 肤色四季）
class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  Color _base = const Color(0xFF1F3A5F); // 默认藏青
  List<BodyTypeGuide> _guides = const [];

  static const _rules = <(String, String)>[
    ('60-30-10 法则', '主色 60%（外套/下装）+ 辅助色 30%（上装）+ 点缀色 10%（配饰）'),
    ('三色原则', '全身主色不超过 3 种（中性色不计），避免杂乱'),
    ('同色系层次', '同一色相变化明度（Tone-on-Tone），显高显瘦'),
    ('冷暖一致', '全身尽量统一冷暖调，刻意撞色除外'),
  ];

  @override
  void initState() {
    super.initState();
    loadBodyTypeGuide()
        .then((g) {
          if (mounted) setState(() => _guides = g);
        })
        .catchError((e) {
          debugPrint('[爱搭衣] 体型指南加载失败: $e');
        });
  }

  List<({String title, String desc, List<Color> colors})> _schemes() {
    final hsv = hexToHsv(colorToHex(_base));
    final h = hsv.h;
    final s = hsv.s;
    final v = hsv.v;
    Color at(double hh, [double? ss, double? vv]) =>
        hexColor(hsvToHex(hh, ss ?? s, vv ?? v));

    return [
      (
        title: '单色系',
        desc: '同一色相变化明度，高级统一',
        colors: [at(h, s * 0.6, (v + 0.25).clamp(0.0, 1.0)), _base,
            at(h, s, (v - 0.25).clamp(0.0, 1.0))],
      ),
      (
        title: '类比色',
        desc: '相邻 30°，柔和自然',
        colors: [at((h - 30 + 360) % 360), _base, at((h + 30) % 360)],
      ),
      (
        title: '互补色',
        desc: '相差 180°，对比醒目，注意面积比',
        colors: [_base, at((h + 180) % 360)],
      ),
      (
        title: '分裂互补',
        desc: '取对面两侧 30°，对比但更协调',
        colors: [_base, at((h + 150) % 360), at((h + 210) % 360)],
      ),
      (
        title: '三角色',
        desc: '相隔 120°，丰富有活力',
        colors: [_base, at((h + 120) % 360), at((h + 240) % 360)],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final store = WardrobeStore.instance;
    return SafeArea(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final gender = store.profile.gender;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
            children: [
              const SectionHeader(eyebrow: 'KNOWLEDGE', title: '配色与知识'),
              const SizedBox(height: AppSpacing.md),

              // ---- 配色盘工具 ----
              _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('配色盘工具',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                const Text('选一个基础色，自动生成科学配色方案',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final sw in appPalette)
                      GestureDetector(
                        onTap: () => setState(() => _base = sw.color),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: sw.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _base == sw.color
                                    ? AppColors.ink
                                    : Colors.white,
                                width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                for (final scheme in _schemes())
                  _schemeCard(scheme.title, scheme.desc, scheme.colors),
              ])),
              const SizedBox(height: 12),

              // ---- 配色法则 ----
              ExpandableCard(
                title: '穿搭配色法则',
                subtitle: '60-30-10 · 三色原则 · 同色系 · 冷暖一致',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final (title, desc) in _rules) ...[
                    Text('· $title',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(desc,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            height: 1.4)),
                    const SizedBox(height: 8),
                  ],
                ]),
              ),
              const SizedBox(height: 12),

              // ---- 体型指南 ----
              ExpandableCard(
                title: '体型穿搭指南',
                subtitle: store.profile.bodyType != null
                    ? '你的体型：${store.profile.bodyType}'
                    : '按体型给出扬长避短策略',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final g in _guides.where((g) => g.gender == gender))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(g.type,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.clayInk)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(g.features,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted))),
                            ]),
                            const SizedBox(height: 2),
                            Text('策略：${g.strategy}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.ink,
                                    height: 1.4)),
                          ]),
                    ),
                  if (_guides.isEmpty)
                    const Text('加载中…',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.muted)),
                ]),
              ),
              const SizedBox(height: 12),

              // ---- 肤色四季 ----
              ExpandableCard(
                title: '肤色四季推荐色',
                subtitle: store.profile.skinSeason != null
                    ? '你的季型：${store.profile.skinSeason}'
                    : '春夏秋冬各自的适合色系',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final e in skinSeasonAdvice.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        SizedBox(
                            width: 64,
                            child: Text(e.key,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink))),
                        Expanded(
                            child: Text(e.value.join(' · '),
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted))),
                      ]),
                    ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _card(Widget child) => AppCard(child: child);

  Widget _schemeCard(String title, String desc, List<Color> colors) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 2),
        Text(desc,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 10),
        Row(children: [
          for (final c in colors)
            Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(colors.map(colorToHex).join(' · '),
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ),
        ]),
      ]),
    );
  }
}
