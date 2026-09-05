import 'package:flutter/material.dart';

/// 设计令牌：色彩 / 排版 / 间距 / 圆角
class AppColors {
  AppColors._();

  static const background = Color(0xFFF6F4F0); // 暖纸底
  static const surface = Color(0xFFFFFFFF); // 卡片面
  static const ink = Color(0xFF1E1D1B); // 墨
  static const muted = Color(0xFF8A857E); // 弱灰
  static const line = Color(0xFFE7E2DB); // 描边

  static const clay = Color(0xFFB8604A); // 陶土（点缀）
  static const claySoft = Color(0xFFEAD9D1); // 陶土浅底
  static const clayInk = Color(0xFF7C3A2A); // 陶土深字

  static const good = Color(0xFF4C7A5B);
  static const mid = Color(0xFFC08A3E);
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadius {
  AppRadius._();
  static const card = 20.0;
  static const chip = 999.0;
}

/// 预设可选颜色（录入 / 展示用），按色系分组
class PaletteSwatch {
  final String name;
  final Color color;
  final String group;
  const PaletteSwatch(this.name, this.color, {this.group = '基础'});
}

const List<PaletteSwatch> appPalette = [
  // 中性
  PaletteSwatch('墨黑', Color(0xFF1E1D1B), group: '中性'),
  PaletteSwatch('纯白', Color(0xFFFFFFFF), group: '中性'),
  PaletteSwatch('米白', Color(0xFFF0E6D3), group: '中性'),
  PaletteSwatch('燕麦', Color(0xFFD8CFC0), group: '中性'),
  PaletteSwatch('暖灰', Color(0xFF9A948C), group: '中性'),
  PaletteSwatch('冷灰', Color(0xFF8A8D91), group: '中性'),
  PaletteSwatch('炭灰', Color(0xFF3A3A3A), group: '中性'),
  PaletteSwatch('藏青', Color(0xFF1F3A5F), group: '中性'),
  PaletteSwatch('卡其', Color(0xFFB7A68A), group: '中性'),
  PaletteSwatch('灰褐', Color(0xFF6B6256), group: '中性'),
  // 大地
  PaletteSwatch('驼色', Color(0xFFB08968), group: '大地'),
  PaletteSwatch('焦糖', Color(0xFFA96E3F), group: '大地'),
  PaletteSwatch('深棕', Color(0xFF5C4033), group: '大地'),
  PaletteSwatch('橄榄', Color(0xFF6B5B3E), group: '大地'),
  PaletteSwatch('军绿', Color(0xFF4C5B3F), group: '大地'),
  PaletteSwatch('苔绿', Color(0xFF7A8B72), group: '大地'),
  PaletteSwatch('陶土', Color(0xFFB8604A), group: '大地'),
  PaletteSwatch('砖红', Color(0xFF9E4A38), group: '大地'),
  // 冷色
  PaletteSwatch('雾蓝', Color(0xFF7D9BB5), group: '冷色'),
  PaletteSwatch('天蓝', Color(0xFF6FA8C9), group: '冷色'),
  PaletteSwatch('宝蓝', Color(0xFF2F5FA8), group: '冷色'),
  PaletteSwatch('海军蓝', Color(0xFF27344D), group: '冷色'),
  PaletteSwatch('墨绿', Color(0xFF2E4A3A), group: '冷色'),
  PaletteSwatch('青绿', Color(0xFF4E8D7C), group: '冷色'),
  PaletteSwatch('灰紫', Color(0xFF8D7FA8), group: '冷色'),
  PaletteSwatch('薰衣草', Color(0xFFB7A8D1), group: '冷色'),
  // 暖色
  PaletteSwatch('酒红', Color(0xFF7C3A2D), group: '暖色'),
  PaletteSwatch('正红', Color(0xFFB23A32), group: '暖色'),
  PaletteSwatch('珊瑚', Color(0xFFE07A5F), group: '暖色'),
  PaletteSwatch('芥末', Color(0xFFC08A3E), group: '暖色'),
  PaletteSwatch('姜黄', Color(0xFFC9972F), group: '暖色'),
  PaletteSwatch('杏色', Color(0xFFE8B58A), group: '暖色'),
  PaletteSwatch('蜜桃', Color(0xFFEDB29A), group: '暖色'),
  PaletteSwatch('玫红', Color(0xFFB5506E), group: '暖色'),
  // 个性
  PaletteSwatch('柠檬黄', Color(0xFFE6C83C), group: '个性'),
  PaletteSwatch('草绿', Color(0xFF7FA548), group: '个性'),
  PaletteSwatch('薄荷', Color(0xFFA8C9B0), group: '个性'),
  PaletteSwatch('天青', Color(0xFF4FA3B8), group: '个性'),
  PaletteSwatch('电光蓝', Color(0xFF3A6FD8), group: '个性'),
  PaletteSwatch('紫红', Color(0xFF8E3B6F), group: '个性'),
  PaletteSwatch('粉色', Color(0xFFE7A8B8), group: '个性'),
];

/// 按分组归类颜色（用于录入页分组展示）
Map<String, List<PaletteSwatch>> groupedPalette() {
  final map = <String, List<PaletteSwatch>>{};
  for (final s in appPalette) {
    map.putIfAbsent(s.group, () => []).add(s);
  }
  return map;
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.clay,
      surface: AppColors.surface,
    ).copyWith(
      primary: AppColors.clay,
      onSurface: AppColors.ink,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.clay,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.line),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.clay),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.ink,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    ),
  );
}
