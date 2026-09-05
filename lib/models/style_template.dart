import 'models.dart';

/// 风格模板中的单品规格
class StyleTemplateItem {
  final String slot;
  final String categoryName;
  final String colorMain;
  final String? colorSub;
  final String? pattern;
  final String? material;
  final String? fit;
  final String? length;
  final int thickness;
  final int formalLevel;
  final int exposure;
  final List<String> styleTags;

  const StyleTemplateItem({
    required this.slot,
    required this.categoryName,
    required this.colorMain,
    this.colorSub,
    this.pattern,
    this.material,
    this.fit,
    this.length,
    this.thickness = 3,
    this.formalLevel = 3,
    this.exposure = 1,
    this.styleTags = const [],
  });

  factory StyleTemplateItem.fromJson(Map<String, dynamic> m) =>
      StyleTemplateItem(
        slot: m['slot'] as String,
        categoryName: m['categoryName'] as String,
        colorMain: m['colorMain'] as String,
        colorSub: m['colorSub'] as String?,
        pattern: m['pattern'] as String?,
        material: m['material'] as String?,
        fit: m['fit'] as String?,
        length: m['length'] as String?,
        thickness: (m['thickness'] as num?)?.toInt() ?? 3,
        formalLevel: (m['formalLevel'] as num?)?.toInt() ?? 3,
        exposure: (m['exposure'] as num?)?.toInt() ?? 1,
        styleTags: (m['styleTags'] as List?)?.cast<String>() ?? const [],
      );

  /// 转成可参与搭配/评分的衣橱单品
  WardrobeItem toWardrobeItem(String gender) => WardrobeItem(
        slot: slot,
        gender: gender,
        categoryName: categoryName,
        colorMain: colorMain,
        colorSub: colorSub,
        pattern: pattern,
        material: material,
        fit: fit,
        length: length,
        thickness: thickness,
        formalLevel: formalLevel,
        exposure: exposure,
        styleTags: styleTags,
      );
}

/// 一个风格的示例搭配（模板）
class StyleTemplate {
  final String name;
  final String gender;
  final String description;
  final String image; // 图片文件名（位于 assets/images/templates/）
  final List<StyleTemplateItem> items;

  const StyleTemplate({
    required this.name,
    required this.gender,
    required this.description,
    required this.image,
    required this.items,
  });

  factory StyleTemplate.fromJson(Map<String, dynamic> m) => StyleTemplate(
        name: m['name'] as String,
        gender: m['gender'] as String,
        description: m['description'] as String? ?? '',
        image: m['image'] as String,
        items: (m['items'] as List)
            .cast<Map<String, dynamic>>()
            .map(StyleTemplateItem.fromJson)
            .toList(),
      );
}
