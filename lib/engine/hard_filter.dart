import '../models/models.dart';

/// 天气温度档 → 可穿厚度范围（厚度 1 轻薄 - 5 加厚）
const Map<String, List<int>> temperatureThickness = {
  '热': [1, 2],
  '适中': [2, 3],
  '凉': [3, 4],
  '冷': [4, 5],
};

/// 硬约束过滤：一票否决，决定「能不能穿」
class HardFilter {
  /// 特定场合禁用的关键词（匹配单品 categoryName / styleTags）
  static const Map<String, List<String>> occasionExclude = {
    '运动': ['皮鞋', '高跟鞋', '乐福鞋', '靴子'],
    '宴会': ['运动鞋', '卫衣', 'T恤'],
    '面试': ['运动鞋', '卫衣', '吊带', '背心'],
  };

  List<WardrobeItem> filter({
    required List<WardrobeItem> wardrobe,
    required UserProfile profile,
    String? occasion,
    String? season,
    String? temperature,
  }) {
    final result = <WardrobeItem>[];
    final excludes = occasion == null ? const <String>[] : (occasionExclude[occasion] ?? const []);

    for (final item in wardrobe) {
      // 1. 性别
      if (item.gender != 'unisex' && item.gender != profile.gender) continue;

      // 2. 季节
      if (season != null &&
          season.isNotEmpty &&
          item.season.isNotEmpty &&
          !item.season.contains(season)) {
        continue;
      }

      // 2.5 天气温度（厚度硬约束，未填厚度不排除）
      if (temperature != null && temperature.isNotEmpty) {
        final range = temperatureThickness[temperature];
        if (range != null &&
            item.thickness != null &&
            (item.thickness! < range[0] || item.thickness! > range[1])) {
          continue;
        }
      }

      // 3. 用户禁忌
      final tabooHit = profile.taboo.any((t) =>
          item.styleTags.contains(t) ||
          item.material == t ||
          item.pattern == t ||
          item.categoryName == t);
      if (tabooHit) continue;

      // 特殊禁忌：高露肤按露肤度数值判断
      if (profile.taboo.contains('高露肤') && (item.exposure ?? 0) >= 3) {
        continue;
      }

      // 4. 场合禁用关键词
      final occHit = excludes.any((k) =>
          item.categoryName.contains(k) || item.styleTags.any((t) => t.contains(k)));
      if (occHit) continue;

      result.add(item);
    }
    return result;
  }
}
