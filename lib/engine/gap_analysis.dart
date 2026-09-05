// 风格缺口分析（纯函数）：想穿某风格时，对比衣橱看缺什么品类

import '../models/models.dart';

/// 命中规则：品类名互为包含（如「基础T恤」可被衣橱中的「T恤」命中）
bool categorySatisfied(String required, Set<String> categoryNames) =>
    categoryNames.any((n) => n.contains(required) || required.contains(n));

/// 返回该风格必备品类中，衣橱里缺失的清单
List<String> missingForStyle(Style style, Iterable<WardrobeItem> wardrobe) {
  final names = wardrobe
      .map((e) => e.categoryName)
      .where((n) => n.isNotEmpty)
      .toSet();
  return style.requiredItems
      .where((req) => req.isNotEmpty && !categorySatisfied(req, names))
      .toList();
}
