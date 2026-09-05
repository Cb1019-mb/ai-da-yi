import 'dart:convert';

String? _listToJson(List<String>? l) =>
    (l == null || l.isEmpty) ? null : jsonEncode(l);

List<String> _listFromJson(dynamic v) {
  if (v == null) return const [];
  if (v is String) {
    final d = jsonDecode(v);
    return d is List ? d.cast<String>() : const [];
  }
  return v is List ? v.cast<String>() : const [];
}

/// 个人档案（单机自用，通常一行）
class UserProfile {
  final int? id;
  final String gender; // 'male' | 'female'
  final double? heightCm;
  final double? weightKg;
  final double? shoulderCm;
  final double? chestCm;
  final double? waistCm;
  final double? hipCm;
  final String? bodyType;
  final String? skinSeason;
  final List<String> stylePref;
  final List<String> taboo;

  const UserProfile({
    this.id,
    required this.gender,
    this.heightCm,
    this.weightKg,
    this.shoulderCm,
    this.chestCm,
    this.waistCm,
    this.hipCm,
    this.bodyType,
    this.skinSeason,
    this.stylePref = const [],
    this.taboo = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'gender': gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'shoulder_cm': shoulderCm,
        'chest_cm': chestCm,
        'waist_cm': waistCm,
        'hip_cm': hipCm,
        'body_type': bodyType,
        'skin_season': skinSeason,
        'style_pref': _listToJson(stylePref),
        'taboo': _listToJson(taboo),
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'] as int?,
        gender: m['gender'] as String,
        heightCm: (m['height_cm'] as num?)?.toDouble(),
        weightKg: (m['weight_kg'] as num?)?.toDouble(),
        shoulderCm: (m['shoulder_cm'] as num?)?.toDouble(),
        chestCm: (m['chest_cm'] as num?)?.toDouble(),
        waistCm: (m['waist_cm'] as num?)?.toDouble(),
        hipCm: (m['hip_cm'] as num?)?.toDouble(),
        bodyType: m['body_type'] as String?,
        skinSeason: m['skin_season'] as String?,
        stylePref: _listFromJson(m['style_pref']),
        taboo: _listFromJson(m['taboo']),
      );

  UserProfile copyWith({
    int? id,
    double? heightCm,
    double? weightKg,
    double? shoulderCm,
    double? chestCm,
    double? waistCm,
    double? hipCm,
    String? gender,
    String? bodyType,
    String? skinSeason,
    List<String>? stylePref,
    List<String>? taboo,
  }) =>
      UserProfile(
        id: id ?? this.id,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        shoulderCm: shoulderCm ?? this.shoulderCm,
        chestCm: chestCm ?? this.chestCm,
        waistCm: waistCm ?? this.waistCm,
        hipCm: hipCm ?? this.hipCm,
        gender: gender ?? this.gender,
        bodyType: bodyType ?? this.bodyType,
        skinSeason: skinSeason ?? this.skinSeason,
        stylePref: stylePref ?? this.stylePref,
        taboo: taboo ?? this.taboo,
      );
}

/// 品类（树形，分性别）
class Category {
  final int id;
  final int? parentId;
  final String gender;
  final String name;
  final int sort;

  const Category({
    required this.id,
    this.parentId,
    required this.gender,
    required this.name,
    this.sort = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'parent_id': parentId,
        'gender': gender,
        'name': name,
        'sort': sort,
      };

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as int,
        parentId: m['parent_id'] as int?,
        gender: m['gender'] as String,
        name: m['name'] as String,
        sort: (m['sort'] as num?)?.toInt() ?? 0,
      );
}

/// 风格库（分性别）
class Style {
  final int? id;
  final String name;
  final String gender;
  final int? formalLevel;
  final List<String> colorTendency;
  final List<String> requiredItems;
  final double? exposureMin;
  final double? exposureMax;
  final List<String> features;

  const Style({
    this.id,
    required this.name,
    required this.gender,
    this.formalLevel,
    this.colorTendency = const [],
    this.requiredItems = const [],
    this.exposureMin,
    this.exposureMax,
    this.features = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'gender': gender,
        'formal_level': formalLevel,
        'color_tendency': _listToJson(colorTendency),
        'required_items': _listToJson(requiredItems),
        'exposure_min': exposureMin,
        'exposure_max': exposureMax,
        'features': _listToJson(features),
      };

  factory Style.fromMap(Map<String, dynamic> m) => Style(
        id: m['id'] as int?,
        name: m['name'] as String,
        gender: m['gender'] as String,
        formalLevel: (m['formal_level'] as num?)?.toInt(),
        colorTendency: _listFromJson(m['color_tendency']),
        requiredItems: _listFromJson(m['required_items']),
        exposureMin: (m['exposure_min'] as num?)?.toDouble(),
        exposureMax: (m['exposure_max'] as num?)?.toDouble(),
        features: _listFromJson(m['features']),
      );
}

/// 衣橱单品
class WardrobeItem {
  final int? id;
  final int? categoryId;
  final String categoryName; // 叶子品类名，如「衬衫」
  final String slot; // top/bottom/dress/shoes/accessory
  final String gender; // male/female/unisex
  final String? colorMain; // 主色 HEX
  final String? colorSub; // 辅色 HEX
  final String? hsvMain; // "h,s,v"
  final String? hsvSub;
  final String? pattern;
  final String? material;
  final int? thickness; // 1-5
  final List<String> season;
  final String? fit; // 版型：修身/标准/宽松/oversize...
  final String? length;
  final List<String> styleTags;
  final int? formalLevel; // 1-5
  final int? exposure; // 0-5
  final String? imagePath;

  const WardrobeItem({
    this.id,
    this.categoryId,
    this.categoryName = '',
    required this.slot,
    required this.gender,
    this.colorMain,
    this.colorSub,
    this.hsvMain,
    this.hsvSub,
    this.pattern,
    this.material,
    this.thickness,
    this.season = const [],
    this.fit,
    this.length,
    this.styleTags = const [],
    this.formalLevel,
    this.exposure,
    this.imagePath,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'category_id': categoryId,
        'category_name': categoryName,
        'slot': slot,
        'gender': gender,
        'color_main': colorMain,
        'color_sub': colorSub,
        'hsv_main': hsvMain,
        'hsv_sub': hsvSub,
        'pattern': pattern,
        'material': material,
        'thickness': thickness,
        'season': _listToJson(season),
        'fit': fit,
        'length': length,
        'style_tags': _listToJson(styleTags),
        'formal_level': formalLevel,
        'exposure': exposure,
        'image_path': imagePath,
      };

  factory WardrobeItem.fromMap(Map<String, dynamic> m) => WardrobeItem(
        id: m['id'] as int?,
        categoryId: m['category_id'] as int?,
        categoryName: (m['category_name'] as String?) ?? '',
        slot: (m['slot'] as String?) ?? 'top',
        gender: m['gender'] as String,
        colorMain: m['color_main'] as String?,
        colorSub: m['color_sub'] as String?,
        hsvMain: m['hsv_main'] as String?,
        hsvSub: m['hsv_sub'] as String?,
        pattern: m['pattern'] as String?,
        material: m['material'] as String?,
        thickness: (m['thickness'] as num?)?.toInt(),
        season: _listFromJson(m['season']),
        fit: m['fit'] as String?,
        length: m['length'] as String?,
        styleTags: _listFromJson(m['style_tags']),
        formalLevel: (m['formal_level'] as num?)?.toInt(),
        exposure: (m['exposure'] as num?)?.toInt(),
        imagePath: m['image_path'] as String?,
      );

  WardrobeItem copyWith({
    int? id,
    String? colorMain,
    String? colorSub,
    String? hsvMain,
    String? hsvSub,
    String? imagePath,
  }) =>
      WardrobeItem(
        id: id ?? this.id,
        categoryId: categoryId,
        categoryName: categoryName,
        slot: slot,
        gender: gender,
        colorMain: colorMain ?? this.colorMain,
        colorSub: colorSub ?? this.colorSub,
        hsvMain: hsvMain ?? this.hsvMain,
        hsvSub: hsvSub ?? this.hsvSub,
        pattern: pattern,
        material: material,
        thickness: thickness,
        season: season,
        fit: fit,
        length: length,
        styleTags: styleTags,
        formalLevel: formalLevel,
        exposure: exposure,
        imagePath: imagePath ?? this.imagePath,
      );
}

/// 体型加分规则
class BodyTypeRule {
  final int? id;
  final String gender;
  final String bodyType;
  final String slot;
  final String attribute;
  final int effect;

  const BodyTypeRule({
    this.id,
    required this.gender,
    required this.bodyType,
    required this.slot,
    required this.attribute,
    required this.effect,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'gender': gender,
        'body_type': bodyType,
        'slot': slot,
        'attribute': attribute,
        'effect': effect,
      };

  factory BodyTypeRule.fromMap(Map<String, dynamic> m) => BodyTypeRule(
        id: m['id'] as int?,
        gender: m['gender'] as String,
        bodyType: m['body_type'] as String,
        slot: m['slot'] as String,
        attribute: m['attribute'] as String,
        effect: (m['effect'] as num).toInt(),
      );
}
