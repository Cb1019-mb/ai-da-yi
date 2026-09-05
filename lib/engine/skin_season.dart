import '../core/color_harmony.dart';

// 四季型肤色诊断（纯规则，便于测试）

class SkinSeasonOption {
  final String label;
  final int warm; // +1 暖，-1 冷，0 中性
  final int light; // +1 浅/亮，-1 深/柔，0 中性
  const SkinSeasonOption(this.label, {this.warm = 0, this.light = 0});
}

class SkinSeasonQuestion {
  final String text;
  final List<SkinSeasonOption> options;
  const SkinSeasonQuestion(this.text, this.options);
}

const List<SkinSeasonQuestion> skinSeasonQuestions = [
  SkinSeasonQuestion('手腕内侧的血管颜色更接近？', [
    SkinSeasonOption('蓝紫色', warm: -1),
    SkinSeasonOption('绿色/橄榄色', warm: 1),
    SkinSeasonOption('看不太清'),
  ]),
  SkinSeasonQuestion('金色和银色首饰，哪个更衬你？', [
    SkinSeasonOption('金色', warm: 1),
    SkinSeasonOption('银色', warm: -1),
    SkinSeasonOption('都差不多'),
  ]),
  SkinSeasonQuestion('素颜时，你的肤色基调偏？', [
    SkinSeasonOption('黄调/蜜桃', warm: 1),
    SkinSeasonOption('粉调/玫瑰', warm: -1),
  ]),
  SkinSeasonQuestion('你的发色与眼珠对比？', [
    SkinSeasonOption('深发色、对比鲜明', light: -1),
    SkinSeasonOption('浅发色、整体柔和', light: 1),
    SkinSeasonOption('中等'),
  ]),
  SkinSeasonQuestion('纯白和米白，哪个更显气色？', [
    SkinSeasonOption('纯白', warm: -1, light: 1),
    SkinSeasonOption('米白/奶油色', warm: 1, light: -1),
  ]),
  SkinSeasonQuestion('哪种红色最衬你？', [
    SkinSeasonOption('番茄红/珊瑚红', warm: 1, light: 1),
    SkinSeasonOption('酒红/砖红', warm: 1, light: -1),
    SkinSeasonOption('玫红/樱桃红', warm: -1, light: 1),
    SkinSeasonOption('正红/宝石红', warm: -1, light: -1),
  ]),
  SkinSeasonQuestion('晒太阳后的反应？', [
    SkinSeasonOption('容易晒黑、变古铜', warm: 1),
    SkinSeasonOption('容易晒红、发烫', warm: -1),
  ]),
  SkinSeasonQuestion('眼白与瞳孔的对比？', [
    SkinSeasonOption('黑白分明、眼珠亮', light: 1),
    SkinSeasonOption('偏柔和', light: -1),
  ]),
];

/// 各季型推荐色（展示用）
const Map<String, List<String>> skinSeasonAdvice = {
  '春季型': ['珊瑚', '杏色', '暖黄', '奶油'],
  '夏季型': ['灰粉', '雾蓝', '薰衣草', '薄荷'],
  '秋季型': ['驼色', '橄榄', '酒红', '芥末'],
  '冬季型': ['正红', '纯白', '宝蓝', '玫红'],
};

/// 根据每题选择的选项下标，判定四季型
String diagnoseSkinSeason(List<int> choices) {
  var warm = 0;
  var light = 0;
  for (var i = 0; i < choices.length; i++) {
    final q = skinSeasonQuestions[i];
    final opt = q.options[choices[i]];
    warm += opt.warm;
    light += opt.light;
  }
  if (warm >= 0 && light >= 0) return '春季型';
  if (warm >= 0 && light < 0) return '秋季型';
  if (warm < 0 && light >= 0) return '夏季型';
  return '冬季型';
}

/// 判断某颜色是否适合某季型：+1 适合 / -1 冲突 / 0 中性
/// 规则基于色相冷暖 + 明度 + 饱和度（纯数学，无模型）
int skinSeasonColorMatch(String? season, String hex) {
  if (season == null || season.isEmpty) return 0;
  final c = hexToHsv(hex);
  final warm = isWarm(c.h); // h<90 或 h>=330
  final cold = isCold(c.h); // 150<=h<300

  switch (season) {
    case '春季型': // 暖 + 亮净
      if (warm && c.v >= 0.55) return 1;
      if (c.v < 0.25 && c.s < 0.2) return -1; // 纯黑/冷灰压气色
      return 0;

    case '夏季型': // 冷 + 柔
      if ((cold || c.s < 0.35) && c.s <= 0.55 && c.v >= 0.5) return 1;
      if (c.h >= 15 && c.h < 55 && c.s > 0.6) return -1; // 纯橙/土黄
      return 0;

    case '秋季型': // 暖 + 深
      if (warm && c.v <= 0.8) return 1;
      if (c.s > 0.75 && c.v > 0.85) return -1; // 荧光色
      if (c.h >= 180 && c.h < 240 && c.v > 0.75 && c.s < 0.4) return -1; // 冰蓝
      return 0;

    case '冬季型': // 冷 + 净
      if ((cold || c.h < 15 || c.h >= 330) &&
          (c.s >= 0.55 || c.v >= 0.85)) {
        return 1;
      }
      if (c.h >= 25 &&
          c.h < 55 &&
          c.s >= 0.15 &&
          c.s <= 0.5 &&
          c.v >= 0.45 &&
          c.v <= 0.85) {
        return -1; // 卡其/浑浊色
      }
      return 0;
  }
  return 0;
}
