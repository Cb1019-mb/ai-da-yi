import '../engine/matching_engine.dart';
import '../models/models.dart';
import 'app_files.dart';

/// 单品使用统计：以「指纹」记录每件单品出现在搭配结果中的次数（搭配结果反推利用率）
class UsageStats {
  UsageStats._();

  static const _fileName = 'usage_stats.json';

  static Future<Map<String, int>> loadCounts() async {
    final raw = await AppFiles.readMap(_fileName);
    return raw.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
  }

  static Future<Set<String>> usedFingerprints() async =>
      (await loadCounts()).keys.toSet();

  static Future<void> record(Iterable<WardrobeItem> items) async {
    final counts = await loadCounts();
    for (final i in items) {
      final k = itemFingerprint(i);
      counts[k] = (counts[k] ?? 0) + 1;
    }
    await AppFiles.writeMap(_fileName, {
      for (final e in counts.entries) e.key: e.value,
    });
  }
}
