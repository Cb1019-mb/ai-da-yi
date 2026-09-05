import 'package:flutter/material.dart';

import '../../data/db_helper.dart';
import '../../models/models.dart';
import '../../models/saved_outfit.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

/// 收藏 / OOTD 穿搭记录列表
class SavedOutfitsPage extends StatefulWidget {
  const SavedOutfitsPage({super.key});

  @override
  State<SavedOutfitsPage> createState() => _SavedOutfitsPageState();
}

class _SavedOutfitsPageState extends State<SavedOutfitsPage> {
  late Future<List<SavedOutfit>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseHelper.instance.getSavedOutfits();
  }

  Future<void> _delete(int id) async {
    await DatabaseHelper.instance.deleteOutfit(id);
    if (!mounted) return;
    setState(() => _future = DatabaseHelper.instance.getSavedOutfits());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('穿搭记录')),
      body: FutureBuilder<List<SavedOutfit>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? const <SavedOutfit>[];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border,
                      size: 48, color: AppColors.clay.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text('还没有穿搭记录',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink)),
                  const SizedBox(height: 6),
                  const Text('去「搭配」页生成并收藏一套吧',
                      style: TextStyle(fontSize: 13, color: AppColors.muted)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: list.length,
            itemBuilder: (context, i) => _recordCard(list[i]),
          );
        },
      ),
    );
  }

  Widget _recordCard(SavedOutfit o) {
    final date = (o.createdAt != null && o.createdAt!.length >= 10)
        ? o.createdAt!.substring(0, 10)
        : (o.createdAt ?? '');
    final tags = [
      if (o.occasion != null && o.occasion!.isNotEmpty) o.occasion!,
      if (o.targetStyle != null && o.targetStyle!.isNotEmpty) o.targetStyle!,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (o.totalScore != null) ScoreRing(score: o.totalScore!, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(date,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              if (tags.isNotEmpty)
                Text(tags,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.muted)),
            ]),
          ),
          IconButton(
            onPressed: () => _delete(o.id),
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppColors.muted),
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (slot, item) in o.slots)
              _itemChip(slotLabel(slot), item),
          ],
        ),
        if (o.colorNote != null && o.colorNote!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(o.colorNote!,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ]),
    );
  }

  Widget _itemChip(String slotLabel, WardrobeItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(slotLabel,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        ColorDot(hex: item.colorMain, size: 12),
        const SizedBox(width: 6),
        Text(item.categoryName,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.ink,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
