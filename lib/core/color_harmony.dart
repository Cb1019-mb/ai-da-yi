// 智能穿搭搭配 App — 色彩和谐度算法（纯 Dart，无 Flutter 依赖）
// 运行：dart run lib/core/color_harmony.dart

import 'dart:math' as math;

/// 颜色 HSV 表示：色相 0-360，饱和度 0-1，明度 0-1
class HsvColor {
  final double h;
  final double s;
  final double v;
  const HsvColor(this.h, this.s, this.v);
}

/// 搭配单品：颜色 + 占全身面积比例(0-1)
class OutfitColorItem {
  final HsvColor color;
  final double areaRatio;
  const OutfitColorItem(this.color, this.areaRatio);
}

/// RGB(0-1) 转 HSV
HsvColor rgbToHsv(double r, double g, double b) {
  final mx = math.max(r, math.max(g, b));
  final mn = math.min(r, math.min(g, b));
  final delta = mx - mn;

  double h;
  if (delta == 0) {
    h = 0;
  } else if (mx == r) {
    h = 60 * (((g - b) / delta) % 6);
  } else if (mx == g) {
    h = 60 * ((b - r) / delta + 2);
  } else {
    h = 60 * ((r - g) / delta + 4);
  }
  final s = mx == 0 ? 0.0 : delta / mx;
  return HsvColor(h % 360, s, mx);
}

/// HEX(#RRGGBB 或 #RGB) 转 HSV
HsvColor hexToHsv(String hex) {
  var h = hex.replaceAll('#', '');
  if (h.length == 3) {
    h = h.split('').map((c) => '$c$c').join();
  }
  final r = int.parse(h.substring(0, 2), radix: 16) / 255.0;
  final g = int.parse(h.substring(2, 4), radix: 16) / 255.0;
  final b = int.parse(h.substring(4, 6), radix: 16) / 255.0;
  return rgbToHsv(r, g, b);
}

/// HSV 转 HEX(#RRGGBB)，用于配色盘工具生成方案色
String hsvToHex(double h, double s, double v) {
  final c = v * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = v - c;
  double r = 0, g = 0, b = 0;
  if (h < 60) {
    r = c;
    g = x;
  } else if (h < 120) {
    r = x;
    g = c;
  } else if (h < 180) {
    g = c;
    b = x;
  } else if (h < 240) {
    g = x;
    b = c;
  } else if (h < 300) {
    r = x;
    b = c;
  } else {
    r = c;
    b = x;
  }
  String to255(double d) =>
      ((d + m) * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${to255(r)}${to255(g)}${to255(b)}'.toUpperCase();
}

/// 色相环最短角度差，返回 0-180
double hueDistance(double h1, double h2) {
  final d = (h1 - h2).abs() % 360;
  return math.min(d, 360 - d);
}

/// 判断两色配色关系类型
String harmonyType(double h1, double h2) {
  final d = hueDistance(h1, h2);
  if (d < 15) return '同色系';
  if (d < 45) return '类比色';
  if (d < 75) return '过渡色';
  if (d >= 150) return '互补色';
  return '冲突区';
}

/// 两色和谐分 0-1
double hueHarmony(double h1, double h2) {
  final d = hueDistance(h1, h2);
  if (d < 15) return 1.0;
  if (d < 45) return 0.9;
  if (d < 75) return 0.6;
  if (d >= 150) return 0.7;
  return 0.3;
}

/// 是否中性基底色（不参与撞色惩罚）
bool isNeutral(HsvColor c) {
  if (c.s < 0.12) return true;                          // 黑白灰米
  if (c.h >= 20 && c.h <= 45 && c.s < 0.5) return true; // 驼/米/棕
  if (c.h >= 200 && c.h <= 240 && c.s < 0.5) return true; // 藏青/牛仔蓝
  return false;
}

/// 暖色判断
bool isWarm(double h) => h < 90 || h >= 330;

/// 冷色判断
bool isCold(double h) => h >= 150 && h < 300;

/// 整身配色和谐度打分 0-100
double outfitColorScore(List<OutfitColorItem> items) {
  if (items.isEmpty) return 0;

  final colorful = items.where((e) => !isNeutral(e.color)).toList();

  double harmony;
  if (colorful.length >= 2) {
    double sum = 0;
    var n = 0;
    for (var i = 0; i < colorful.length; i++) {
      for (var j = i + 1; j < colorful.length; j++) {
        sum += hueHarmony(colorful[i].color.h, colorful[j].color.h);
        n++;
      }
    }
    harmony = sum / n;
  } else {
    harmony = 0.9; // 只有一种有色单品，靠中性色撑，默认和谐
  }

  // 冷暖混搭减分
  final warmCount = colorful.where((e) => isWarm(e.color.h)).length;
  final coldCount = colorful.where((e) => isCold(e.color.h)).length;
  if (warmCount > 0 && coldCount > 0) harmony -= 0.15;

  // 三色原则：有色超过 3 种减分
  if (colorful.length > 3) harmony -= 0.2;

  // 面积比例 60-30-10 加分
  final areas = items.map((e) => e.areaRatio).toList()
    ..sort((a, b) => b.compareTo(a));
  double ratioBonus = 0;
  if (areas.length >= 2 &&
      areas[0] >= 0.55 &&
      areas[1] >= 0.25 &&
      areas[1] <= 0.35) {
    ratioBonus = 0.1;
  }

  final score = (harmony + ratioBonus).clamp(0.0, 1.0);
  return score * 100;
}

