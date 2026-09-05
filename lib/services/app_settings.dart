import '../engine/scoring.dart';
import 'app_files.dart';

/// 轻量应用设置（当前仅评分权重），存 JSON 文件
class AppSettings {
  AppSettings._();

  static const _fileName = 'settings.json';

  static Future<ScoringConfig> loadConfig() async {
    try {
      final m = await AppFiles.readMap(_fileName);
      final w = m['weights'];
      if (w is! Map<String, dynamic>) return const ScoringConfig();
      double v(String k, double d) => (w[k] as num?)?.toDouble() ?? d;
      return ScoringConfig(
        color: v('color', 0.35),
        style: v('style', 0.25),
        bodyType: v('bodyType', 0.15),
        formal: v('formal', 0.10),
        exposure: v('exposure', 0.05),
        preference: v('preference', 0.10),
      );
    } catch (_) {
      return const ScoringConfig();
    }
  }

  static Future<void> saveConfig(ScoringConfig c) async {
    await AppFiles.writeMap(_fileName, {
      'weights': {
        'color': c.color,
        'style': c.style,
        'bodyType': c.bodyType,
        'formal': c.formal,
        'exposure': c.exposure,
        'preference': c.preference,
      },
    });
  }
}
