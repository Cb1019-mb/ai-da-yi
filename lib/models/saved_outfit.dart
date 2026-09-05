import 'dart:convert';

import 'models.dart';

/// 已收藏 / 已打卡的穿搭记录
class SavedOutfit {
  final int id;
  final String? occasion;
  final String? targetStyle;
  final double? totalScore;
  final String? colorNote;
  final String? createdAt;
  final List<(String, WardrobeItem)> slots; // (部位, 单品)

  const SavedOutfit({
    required this.id,
    this.occasion,
    this.targetStyle,
    this.totalScore,
    this.colorNote,
    this.createdAt,
    this.slots = const [],
  });

  factory SavedOutfit.fromMap(Map<String, dynamic> m) {
    final slots = <(String, WardrobeItem)>[];
    final raw = m['snapshot'];
    if (raw is String && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        for (final e in list) {
          final map = e as Map<String, dynamic>;
          slots.add((
            (map['slot'] as String?) ?? 'top',
            WardrobeItem.fromMap((map['item'] as Map).cast<String, dynamic>()),
          ));
        }
      } catch (_) {}
    }
    return SavedOutfit(
      id: m['id'] as int,
      occasion: m['occasion'] as String?,
      targetStyle: m['target_style'] as String?,
      totalScore: (m['total_score'] as num?)?.toDouble(),
      colorNote: m['color_note'] as String?,
      createdAt: m['created_at'] as String?,
      slots: slots,
    );
  }
}
