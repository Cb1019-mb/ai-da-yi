// 体型自动判型（纯规则）：由胸围/腰围/臀围比例推断，可手动修正

/// 推断体型；数据不全时返回 null
String? inferBodyType({
  required String gender,
  double? chest,
  double? waist,
  double? hip,
}) {
  if (chest == null || waist == null || hip == null) return null;
  if (chest <= 0 || waist <= 0 || hip <= 0) return null;

  final whr = waist / hip; // 腰臀比
  final chr = chest / hip; // 胸臀比

  if (gender == 'female') {
    // 1) 腰腹接近臀围 → 苹果形
    if (waist >= hip * 0.9) return '苹果形';
    // 2) 腰臀比小且胸臀接近 → 沙漏形
    if (whr <= 0.78 && (chr - 1).abs() <= 0.08) return '沙漏型';
    // 3) 臀围明显大于胸围 → 梨形
    if (hip > chest * 1.08) return '梨形';
    // 4) 胸围明显大于臀围 → 倒三角
    if (chest > hip * 1.08) return '倒三角';
    return '矩形';
  }

  // male
  // 1) 腰围接近胸围 → 椭圆（腰腹突出）
  if (waist >= chest * 0.95) return '椭圆';
  // 2) 臀围明显大于胸围 → 梨形
  if (hip > chest * 1.06) return '梨形';
  // 3) 胸围明显大于臀围 → 倒三角
  if (chest > hip * 1.10) return '倒三角';
  // 4) 有明显肩腰差 → 梯形（匀称）
  if (chest - waist >= 12 && waist < hip) return '梯形';
  return '矩形';
}
