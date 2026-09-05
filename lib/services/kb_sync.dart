import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import '../data/seed_loader.dart';
import 'app_files.dart';

/// 知识库同步：
/// 1. 覆盖目录热更新：把同名 JSON 放到 应用文档目录/kb_override/ 即可替换内置知识库
/// 2. 基于内容哈希：内容变化时自动清空知识表（品类/风格/体型规则）并重新导入，
///    不影响衣橱单品、档案、收藏等用户数据
class KbSync {
  KbSync._();

  static const _metaFile = 'kb_meta.json';
  static const _overrideDir = 'kb_override';

  static const _assets = <String, String>{
    'categories': 'assets/data/categories.json',
    'styles': 'assets/data/styles.json',
    'body_types': 'assets/data/body_types.json',
    'style_templates': 'assets/data/style_templates.json',
  };

  static String overrideName(String key) => _assets[key]!.split('/').last;

  /// 读取知识库内容：优先 kb_override 覆盖文件
  static Future<String> load(String key) async {
    try {
      final f = await AppFiles.file('$_overrideDir/${overrideName(key)}');
      if (f.existsSync()) return f.readAsStringSync();
    } catch (_) {}
    return rootBundle.loadString(_assets[key]!);
  }

  static String _hash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16);
  }

  static Future<Map<String, String>> currentHashes() async {
    final out = <String, String>{};
    for (final k in _assets.keys) {
      out[k] = _hash(await load(k));
    }
    return out;
  }

  /// 内容有变化（首次运行 / 覆盖文件变更 / force）→ 重导知识表，返回是否重导
  static Future<bool> syncIfNeeded(Database db, {bool force = false}) async {
    final hashes = await currentHashes();
    final saved = await AppFiles.readMap(_metaFile);
    final changed = force || _assets.keys.any((k) => saved[k] != hashes[k]);
    if (!changed) return false;

    final batch = db.batch();
    batch.delete('category');
    batch.delete('style');
    batch.delete('body_type_rule');
    await batch.commit(noResult: true);

    await SeedLoader(db).seed(
      categoriesJson: await load('categories'),
      stylesJson: await load('styles'),
      bodyTypesJson: await load('body_types'),
    );

    await AppFiles.writeMap(_metaFile, hashes);
    return true;
  }
}
