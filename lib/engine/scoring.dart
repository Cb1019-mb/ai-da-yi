import '../core/color_harmony.dart';
import '../models/models.dart';
import 'skin_season.dart';

/// 部位 → 面积占比（用于 60-30-10 配色面积法则）
const Map<String, double> slotAreaRatio = {
  'outer': 0.40,
  'top': 0.30,
  'bottom': 0.25,
  'dress': 0.55,
  'shoes': 0.08,
  'accessory': 0.05,
};

/// 场合 → 正式度
const Map<String, int> occasionFormalLevel = {
  '通勤': 4, '约会': 3, '休闲': 2, '运动': 1,
  '宴会': 5, '旅行': 2, '居家': 1, '面试': 5,
};

/// 场合 → 露肤度上限
const Map<String, int> occasionExposureMax = {
  '通勤': 2, '约会': 3, '休闲': 3, '运动': 3,
  '宴会': 4, '旅行': 3, '居家': 3, '面试': 1,
};

/// 评分权重配置
class ScoringConfig {
  final double color;
  final double style;
  final double bodyType;
  final double formal;
  final double exposure;
  final double preference;

  const ScoringConfig({
    this.color = 0.35,
    this.style = 0.25,
    this.bodyType = 0.15,
    this.formal = 0.10,
    this.exposure = 0.05,
    this.preference = 0.10,
  });
}

/// 单项得分汇总（0-100）
class OutfitScore {
  final double total;
  final double color;
  final double style;
  final double bodyType;
  final double formal;
  final double exposure;
  final double preference;
  final String colorNote;

  const OutfitScore({
    required this.total,
    required this.color,
    required this.style,
    required this.bodyType,
    required this.formal,
    required this.exposure,
    required this.preference,
    required this.colorNote,
  });
}

/// 色彩和谐度（35% 权重核心）
double colorScore(Map<String, WardrobeItem> slots) {
  final raw = <OutfitColorItem>[];
  for (final e in slots.entries) {
    final hex = e.value.colorMain;
    if (hex == null || hex.isEmpty) continue;
    raw.add(OutfitColorItem(hexToHsv(hex), slotAreaRatio[e.key] ?? 0.2));
  }
  if (raw.isEmpty) return 0;

  final total = raw.fold<double>(0, (s, i) => s + i.areaRatio);
  final norm = raw
      .map((i) => OutfitColorItem(i.color, total == 0 ? 1.0 / raw.length : i.areaRatio / total))
      .toList();
  return outfitColorScore(norm);
}

/// 配色说明（取前两个有色单品判断关系）
String colorNote(Map<String, WardrobeItem> slots) {
  final colored = slots.values
      .where((i) => i.colorMain != null && i.colorMain!.isNotEmpty)
      .toList();
  if (colored.isEmpty) return '无彩色信息';
  if (colored.length == 1) return '单色系搭配，靠中性色衬托';
  final h1 = hexToHsv(colored[0].colorMain!);
  final h2 = hexToHsv(colored[1].colorMain!);
  return '主配色关系：${harmonyType(h1.h, h2.h)}';
}

/// 风格一致性
double styleScore(Map<String, WardrobeItem> slots, Style target) {
  if (slots.isEmpty) return 0;
  var hits = 0;
  for (final item in slots.values) {
    final tags = item.styleTags.toSet();
    final match = tags.contains(target.name) ||
        tags.any((t) => target.features.contains(t));
    if (match) hits++;
  }
  return hits / slots.length * 100;
}

/// 体型适配度（由体型加分表驱动）
double bodyTypeScore(
  Map<String, WardrobeItem> slots,
  UserProfile profile,
  List<BodyTypeRule> rules,
) {
  if (profile.bodyType == null || slots.isEmpty) return 50;
  var sum = 0.0;
  var n = 0;
  for (final e in slots.entries) {
    final item = e.value;
    final slot = e.key;
    var itemScore = 0;
    for (final r in rules) {
      if (r.gender != profile.gender || r.bodyType != profile.bodyType) continue;
      if (r.slot != '任意' && r.slot != slot) continue;
      if (_matchesAttribute(r.attribute, item)) itemScore += r.effect;
    }
    sum += itemScore;
    n++;
  }
  if (n == 0) return 50;
  final normalized = (sum / n).clamp(-1.0, 1.0).toDouble();
  return (normalized + 1) / 2 * 100;
}

bool _matchesAttribute(String attr, WardrobeItem item) {
  final hex = item.colorMain;
  if (attr.contains('颜色=深色')) return hex != null && _isDark(hex);
  if (attr.contains('颜色=浅色')) return hex != null && _isLight(hex);
  if (attr.contains('版型=紧身')) return item.fit == '紧身';
  if (attr.contains('版型=阔腿') || attr.contains('版型=A字')) {
    return item.fit == '阔腿' || item.fit == 'A字';
  }
  if (attr.contains('版型=直筒') || attr.contains('版型=微阔')) {
    return item.fit == '直筒' || item.fit == '微阔';
  }
  if (attr.contains('版型=廓形') || attr.contains('版型=垫肩')) {
    return item.fit == '廓形' || item.fit == '垫肩';
  }
  if (attr.contains('收腰') || attr.contains('高腰') || attr.contains('腰带')) {
    return item.fit == '收腰' || item.styleTags.contains('收腰');
  }
  if (attr.contains('有层次') || attr.contains('有外套')) {
    return item.slot == 'outer' || item.styleTags.contains('层次');
  }
  return false;
}

bool _isDark(String hex) => hexToHsv(hex).v < 0.5;
bool _isLight(String hex) => hexToHsv(hex).v > 0.7;

/// 正式度匹配
double formalScore(Map<String, WardrobeItem> slots, int occasionFormal) {
  if (slots.isEmpty) return 0;
  var sum = 0.0;
  var n = 0;
  for (final item in slots.values) {
    final fl = item.formalLevel;
    if (fl == null) continue;
    final diff = (fl - occasionFormal).abs();
    sum += (1 - diff / 4).clamp(0.0, 1.0).toDouble();
    n++;
  }
  return n == 0 ? 0 : sum / n * 100;
}

/// 露肤度匹配
double exposureScore(Map<String, WardrobeItem> slots, int occasionExposure) {
  if (slots.isEmpty) return 100;
  var sum = 0.0;
  var n = 0;
  for (final item in slots.values) {
    final ex = item.exposure;
    if (ex == null) continue;
    final over = ex - occasionExposure;
    sum += over <= 0 ? 1.0 : (1 - over / 5).clamp(0.0, 1.0).toDouble();
    n++;
  }
  return n == 0 ? 100 : sum / n * 100;
}

/// 用户偏好
double preferenceScore(Map<String, WardrobeItem> slots, UserProfile profile) {
  if (profile.stylePref.isEmpty || slots.isEmpty) return 50;
  var hits = 0;
  for (final item in slots.values) {
    if (item.styleTags.any((t) => profile.stylePref.contains(t))) hits++;
  }
  return hits / slots.length * 100;
}

/// 肤色季型适配分（颜色落在适合色域内加分）
double skinSeasonScore(Map<String, WardrobeItem> slots, UserProfile profile) {
  final season = profile.skinSeason;
  if (season == null || season.isEmpty) return 50;
  final hexes = slots.values
      .map((i) => i.colorMain)
      .where((h) => h != null && h.isNotEmpty)
      .cast<String>()
      .toList();
  if (hexes.isEmpty) return 50;
  var sum = 0;
  for (final h in hexes) {
    sum += skinSeasonColorMatch(season, h);
  }
  final avg = sum / hexes.length; // -1..1
  return (avg + 1) / 2 * 100;
}

/// 综合评分
OutfitScore scoreOutfit({
  required Map<String, WardrobeItem> slots,
  required UserProfile profile,
  String? occasion,
  Style? targetStyle,
  List<BodyTypeRule> bodyTypeRules = const [],
  ScoringConfig config = const ScoringConfig(),
}) {
  final occFormal = occasion == null ? 3 : (occasionFormalLevel[occasion] ?? 3);
  final occExposure = occasion == null ? 3 : (occasionExposureMax[occasion] ?? 3);

  final rawColor = colorScore(slots);
  // 已设置肤色季型时，把「肤色适配」按 25% 融入色彩和谐度
  final season = profile.skinSeason;
  final color = (season == null || season.isEmpty)
      ? rawColor
      : rawColor * 0.75 + skinSeasonScore(slots, profile) * 0.25;
  final style = targetStyle == null ? 0.0 : styleScore(slots, targetStyle);
  final body = bodyTypeScore(slots, profile, bodyTypeRules);
  final formal = formalScore(slots, occFormal);
  final exposure = exposureScore(slots, occExposure);
  final preference = preferenceScore(slots, profile);

  final total = config.color * color +
      config.style * style +
      config.bodyType * body +
      config.formal * formal +
      config.exposure * exposure +
      config.preference * preference;

  return OutfitScore(
    total: total,
    color: color,
    style: style,
    bodyType: body,
    formal: formal,
    exposure: exposure,
    preference: preference,
    colorNote: colorNote(slots),
  );
}
