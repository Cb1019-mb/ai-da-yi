import '../models/models.dart';
import 'hard_filter.dart';
import 'scoring.dart';

/// 单品指纹：用于使用统计与「避免重复」判定
String itemFingerprint(WardrobeItem i) =>
    '${i.slot}|${i.categoryName}|${(i.colorMain ?? '').toUpperCase()}';

/// 一个候选搭配方案
class OutfitCandidate {
  final Map<String, WardrobeItem> slots;
  final OutfitScore score;

  /// 因与近期穿搭记录重叠而被扣掉的分数
  final double penalty;

  const OutfitCandidate(this.slots, this.score, {this.penalty = 0.0});

  double get effectiveTotal => score.total - penalty;
}

/// 搭配引擎：硬约束过滤 → 组合生成 → 软约束评分 → 排序
class MatchingEngine {
  final HardFilter hardFilter;
  final ScoringConfig config;

  MatchingEngine({HardFilter? hardFilter, this.config = const ScoringConfig()})
      : hardFilter = hardFilter ?? HardFilter();

  List<OutfitCandidate> generate({
    required List<WardrobeItem> wardrobe,
    required UserProfile profile,
    String? occasion,
    Style? targetStyle,
    String? season,
    String? temperature,
    List<BodyTypeRule> bodyTypeRules = const [],
    List<Set<String>> avoidFingerprints = const [],
    double avoidPenalty = 12.0,
    int limit = 10,
  }) {
    final eligible = hardFilter.filter(
      wardrobe: wardrobe,
      profile: profile,
      occasion: occasion,
      season: season,
      temperature: temperature,
    );

    final bySlot = <String, List<WardrobeItem>>{};
    for (final it in eligible) {
      bySlot.putIfAbsent(it.slot, () => []).add(it);
    }

    final top = bySlot['top'] ?? const <WardrobeItem>[];
    final bottom = bySlot['bottom'] ?? const <WardrobeItem>[];
    final dress = bySlot['dress'] ?? const <WardrobeItem>[];
    final shoes = bySlot['shoes'] ?? const <WardrobeItem>[];
    final accessory = bySlot['accessory'] ?? const <WardrobeItem>[];

    final combos = <Map<String, WardrobeItem>>[];

    // 上装 + 下装（+鞋/配饰）
    for (final t in top) {
      for (final b in bottom) {
        if (shoes.isNotEmpty) {
          for (final s in shoes) {
            final m = <String, WardrobeItem>{'top': t, 'bottom': b, 'shoes': s};
            if (accessory.isNotEmpty) m['accessory'] = accessory.first;
            combos.add(m);
          }
        } else {
          final m = <String, WardrobeItem>{'top': t, 'bottom': b};
          if (accessory.isNotEmpty) m['accessory'] = accessory.first;
          combos.add(m);
        }
      }
    }

    // 连衣裙（+鞋/配饰）
    for (final d in dress) {
      if (shoes.isNotEmpty) {
        for (final s in shoes) {
          final m = <String, WardrobeItem>{'dress': d, 'shoes': s};
          if (accessory.isNotEmpty) m['accessory'] = accessory.first;
          combos.add(m);
        }
      } else {
        final m = <String, WardrobeItem>{'dress': d};
        if (accessory.isNotEmpty) m['accessory'] = accessory.first;
        combos.add(m);
      }
    }

    final scored = <OutfitCandidate>[];
    for (final c in combos) {
      final s = scoreOutfit(
        slots: c,
        profile: profile,
        occasion: occasion,
        targetStyle: targetStyle,
        bodyTypeRules: bodyTypeRules,
        config: config,
      );
      // 避免重复：与近期穿搭记录重叠越多，扣分越多
      var penalty = 0.0;
      if (avoidFingerprints.isNotEmpty) {
        final fps = c.values.map(itemFingerprint).toSet();
        var maxOverlap = 0.0;
        for (final recent in avoidFingerprints) {
          if (recent.isEmpty) continue;
          final overlap = fps.intersection(recent).length / fps.length;
          if (overlap > maxOverlap) maxOverlap = overlap;
        }
        penalty = maxOverlap * avoidPenalty;
      }
      scored.add(OutfitCandidate(c, s, penalty: penalty));
    }
    scored.sort((a, b) => b.effectiveTotal.compareTo(a.effectiveTotal));

    return scored.take(limit).toList();
  }
}
