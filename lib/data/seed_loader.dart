import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// 中文部位 → 引擎英文 slot
const Map<String, String> _slotMap = {
  '上装': 'top',
  '下装': 'bottom',
  '连衣裙': 'dress',
  '鞋靴': 'shoes',
  '配饰': 'accessory',
};

/// 解析后的种子数据
class SeedData {
  final List<Category> categories;
  final List<Style> styles;
  final List<BodyTypeRule> bodyTypeRules;

  const SeedData({
    required this.categories,
    required this.styles,
    required this.bodyTypeRules,
  });
}

/// 纯函数：把三个 JSON 字符串解析为结构化数据（不依赖数据库，便于测试）
SeedData parseSeeds({
  required String categoriesJson,
  required String stylesJson,
  required String bodyTypesJson,
}) {
  // ---- 品类树 ----
  final categories = <Category>[];
  final cats = jsonDecode(categoriesJson) as Map<String, dynamic>;
  var id = 1;
  for (final gender in ['male', 'female']) {
    final group = cats[gender] as Map<String, dynamic>?;
    if (group == null) continue;
    for (final entry in group.entries) {
      final bigName = entry.key; // 上装/下装/连衣裙/鞋靴/配饰
      final parentId = id;
      categories.add(Category(
        id: parentId,
        parentId: null,
        gender: gender,
        name: bigName,
      ));
      id++;
      final children = (entry.value as List).cast<String>();
      for (final leaf in children) {
        categories.add(Category(
          id: id,
          parentId: parentId,
          gender: gender,
          name: leaf,
        ));
        id++;
      }
    }
  }

  // ---- 风格库 ----
  final styles = <Style>[];
  final stylesMap = jsonDecode(stylesJson) as Map<String, dynamic>;
  for (final gender in ['male', 'female']) {
    final list = stylesMap[gender] as List?;
    if (list == null) continue;
    for (final s in list) {
      final m = s as Map<String, dynamic>;
      final exposure = (m['exposure'] as List?)?.cast<num>();
      styles.add(Style(
        name: m['name'] as String,
        gender: gender,
        formalLevel: (m['formal_level'] as num?)?.toInt(),
        colorTendency: (m['color_tendency'] as List?)?.cast<String>() ?? const [],
        requiredItems: (m['required_items'] as List?)?.cast<String>() ?? const [],
        exposureMin:
            exposure != null && exposure.isNotEmpty ? exposure[0].toDouble() : null,
        exposureMax:
            exposure != null && exposure.length > 1 ? exposure[1].toDouble() : null,
        features: (m['features'] as List?)?.cast<String>() ?? const [],
      ));
    }
  }

  // ---- 体型加分规则 ----
  final rules = <BodyTypeRule>[];
  final body = jsonDecode(bodyTypesJson) as Map<String, dynamic>;
  final scoring = (body['scoring'] as List).cast<Map<String, dynamic>>();
  for (final r in scoring) {
    rules.add(BodyTypeRule(
      gender: r['gender'] as String,
      bodyType: r['body_type'] as String,
      slot: _slotMap[r['slot']] ?? r['slot'] as String,
      attribute: r['attribute'] as String,
      effect: (r['effect'] as num).toInt(),
    ));
  }

  return SeedData(categories: categories, styles: styles, bodyTypeRules: rules);
}

/// 将 JSON 种子数据导入数据库（品类树 / 风格库 / 体型规则）
class SeedLoader {
  final Database db;
  SeedLoader(this.db);

  Future<void> seed({
    required String categoriesJson,
    required String stylesJson,
    required String bodyTypesJson,
  }) async {
    final data = parseSeeds(
      categoriesJson: categoriesJson,
      stylesJson: stylesJson,
      bodyTypesJson: bodyTypesJson,
    );

    final batch = db.batch();
    for (final c in data.categories) {
      batch.insert('category', c.toMap());
    }
    for (final s in data.styles) {
      batch.insert('style', s.toMap());
    }
    for (final r in data.bodyTypeRules) {
      batch.insert('body_type_rule', r.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// 从 assets 读取并导入（应用启动时调用）
  Future<void> seedFromAssets() async {
    final categories = await rootBundle.loadString('assets/data/categories.json');
    final styles = await rootBundle.loadString('assets/data/styles.json');
    final bodyTypes = await rootBundle.loadString('assets/data/body_types.json');
    await seed(
      categoriesJson: categories,
      stylesJson: styles,
      bodyTypesJson: bodyTypes,
    );
  }
}
