import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/db_helper.dart';
import '../../engine/matching_engine.dart';
import '../../engine/scoring.dart';
import '../../models/models.dart';
import '../../state/wardrobe_store.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class OutfitDetailSheet extends StatefulWidget {
  final OutfitCandidate candidate;
  final String? occasion;
  final Style? targetStyle;
  const OutfitDetailSheet({
    super.key,
    required this.candidate,
    this.occasion,
    this.targetStyle,
  });

  @override
  State<OutfitDetailSheet> createState() => _OutfitDetailSheetState();
}

class _OutfitDetailSheetState extends State<OutfitDetailSheet> {
  late Map<String, WardrobeItem> _slots;
  late OutfitScore _score;
  bool _saved = false;
  final Set<String> _lockedSlots = {};
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _slots = Map.of(widget.candidate.slots);
    _score = widget.candidate.score;
  }

  void _swap(String slot) {
    final store = WardrobeStore.instance;
    final current = _slots[slot];
    final all = store.items.where((i) => i.slot == slot).toList();
    if (all.length < 2) return;

    final idx = all.indexOf(current!);
    final next = all[(idx + 1) % all.length];

    setState(() {
      _slots[slot] = next;
      _score = scoreOutfit(
        slots: _slots,
        profile: store.profile,
        occasion: widget.occasion,
        targetStyle: widget.targetStyle,
        bodyTypeRules: store.bodyTypeRules,
        config: store.config,
      );
    });
  }

  /// 整身随机换：跳过锁定的部位，其余部位随机换一件
  void _rerollAll() {
    final store = WardrobeStore.instance;
    var changed = 0;
    for (final slot in _slots.keys.toList()) {
      if (_lockedSlots.contains(slot)) continue;
      final all = store.items.where((i) => i.slot == slot).toList();
      if (all.length < 2) continue;
      final alternatives =
          all.where((i) => !identical(i, _slots[slot])).toList();
      if (alternatives.isEmpty) continue;
      _slots[slot] = alternatives[_rnd.nextInt(alternatives.length)];
      changed++;
    }
    if (changed == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有可换的单品（或已全部锁定）')));
      return;
    }
    setState(() {
      _score = scoreOutfit(
        slots: _slots,
        profile: store.profile,
        occasion: widget.occasion,
        targetStyle: widget.targetStyle,
        bodyTypeRules: store.bodyTypeRules,
        config: store.config,
      );
    });
  }

  Future<void> _saveOutfit() async {
    try {
      await DatabaseHelper.instance.saveOutfit(
        occasion: widget.occasion,
        targetStyle: widget.targetStyle?.name,
        totalScore: _score.total,
        colorNote: _score.colorNote,
        slots: [for (final e in _slots.entries) (e.key, e.value)],
      );
      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已收藏并记录本次穿搭')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('收藏失败，请重试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = WardrobeStore.instance;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              ScoreRing(score: _score.total, size: 72),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_score.colorNote,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink)),
                    const SizedBox(height: 6),
                    Text('综合得分 ${_score.total.toStringAsFixed(0)} / 100',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.muted)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _rerollAll,
                  icon: const Icon(Icons.shuffle, size: 18),
                  label: const Text('整身随机换'),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            const Text('点 🔒 可锁定部位，整身换时保留',
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: AppSpacing.sm),
            const _SectionTitle('搭配明细'),
            const SizedBox(height: AppSpacing.sm),
            for (final e in _slots.entries) _slotRow(e.key, e.value),
            const SizedBox(height: AppSpacing.lg),
            const _SectionTitle('评分明细'),
            const SizedBox(height: AppSpacing.sm),
            _scoreBar('色彩和谐度', _score.color, store.config.color),
            _scoreBar('风格一致性', _score.style, store.config.style),
            _scoreBar('体型适配度', _score.bodyType, store.config.bodyType),
            _scoreBar('正式度匹配', _score.formal, store.config.formal),
            _scoreBar('露肤度/场合', _score.exposure, store.config.exposure),
            _scoreBar('用户偏好', _score.preference, store.config.preference),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saved ? null : _saveOutfit,
                icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border),
                label: Text(_saved ? '已收藏' : '收藏并记录今日穿搭'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotRow(String slot, WardrobeItem item) {
    final label = slotLabel(slot);
    final meta = [item.fit, ...item.styleTags]
        .where((e) => e != null && e.isNotEmpty)
        .join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        ColorDot(hex: item.colorMain, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Text(item.categoryName,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink)),
            ]),
            const SizedBox(height: 3),
            Text(meta,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
        IconButton(
          onPressed: () => setState(() {
            if (_lockedSlots.contains(slot)) {
              _lockedSlots.remove(slot);
            } else {
              _lockedSlots.add(slot);
            }
          }),
          icon: Icon(
            _lockedSlots.contains(slot) ? Icons.lock : Icons.lock_open,
            size: 18,
            color: _lockedSlots.contains(slot)
                ? AppColors.clay
                : AppColors.muted,
          ),
          tooltip: _lockedSlots.contains(slot) ? '已锁定' : '锁定该部位',
        ),
        TextButton(
          onPressed: () => _swap(slot),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.clay,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('换一换'),
        ),
      ]),
    );
  }

  Widget _scoreBar(String label, double value, double weight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(
          width: 96,
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.ink)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.line,
              color: AppColors.clay,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 76,
          child: Text(
            '${value.toStringAsFixed(0)} · ${(weight * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink));
}
