import 'package:flutter/material.dart';

import '../../engine/matching_engine.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

Color hexColor(String hex) {
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

String colorToHex(Color c) {
  final rgb = c.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// 部位 → 中文标签（全局统一）
const Map<String, String> kSlotLabels = {
  'top': '上装',
  'bottom': '下装',
  'dress': '连衣裙',
  'shoes': '鞋履',
  'accessory': '配饰',
};

String slotLabel(String slot) => kSlotLabels[slot] ?? slot;

/// 底部弹层顶部的小拖拽条
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.line,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// 统一白卡片：可选标题
class AppCard extends StatelessWidget {
  final String? title;
  final Widget child;
  const AppCard({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// 区块标题（眉题 + 主标题）
class SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  const SectionHeader({super.key, required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.clay,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(eyebrow,
              style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  color: AppColors.clay,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      ],
    );
  }
}

/// 可选中标签
class TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const TagChip({super.key, required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.clay : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: selected ? AppColors.clay : AppColors.line),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : AppColors.ink,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}

/// 可展开/收起的卡片：折叠时仅显示标题与摘要，点击展开完整内容
class ExpandableCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;
  const ExpandableCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = false,
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                        if (widget.subtitle != null &&
                            widget.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(widget.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.muted)),
                        ],
                      ]),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more,
                      color: AppColors.muted),
                ),
              ]),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

/// 颜色圆点
class ColorDot extends StatelessWidget {
  final String? hex;
  final double size;
  const ColorDot({super.key, this.hex, this.size = 22});

  @override
  Widget build(BuildContext context) {
    if (hex == null || hex!.isEmpty) {
      return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
              color: AppColors.line, shape: BoxShape.circle));
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hexColor(hex!),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
    );
  }
}

/// 环形评分
class ScoreRing extends StatelessWidget {
  final double score;
  final double size;
  const ScoreRing({super.key, required this.score, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppColors.good
        : (score >= 60 ? AppColors.mid : AppColors.muted);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: score / 100, color: color),
        child: Center(
          child: Text('${score.round()}',
              style: TextStyle(
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final rect = Offset.zero & size;
    final inset = rect.deflate(stroke / 2);

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.line;
    canvas.drawArc(inset, 0, 3.141592653589793 * 2, false, bg);

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(inset, -1.5708, 3.141592653589793 * 2 * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// 搭配结果卡片
class OutfitCard extends StatelessWidget {
  final OutfitCandidate candidate;
  const OutfitCard({super.key, required this.candidate});

  @override
  Widget build(BuildContext context) {
    final s = candidate.score;
    final colors = candidate.slots.values
        .map((e) => e.colorMain)
        .where((c) => c != null && c.isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ScoreRing(score: s.total),
            const SizedBox(width: 12),
            Expanded(
              child: Text(s.colorNote,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink)),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final e in candidate.slots.entries)
                _SlotPill(label: slotLabel(e.key), item: e.value),
            ],
          ),
          if (colors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              for (final c in colors.take(6))
                Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ColorDot(hex: c, size: 26)),
            ]),
          ],
        ],
      ),
    );
  }
}

class _SlotPill extends StatelessWidget {
  final String label;
  final WardrobeItem item;
  const _SlotPill({required this.label, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        ColorDot(hex: item.colorMain, size: 12),
        const SizedBox(width: 6),
        Text(item.categoryName,
            style: const TextStyle(
                fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
