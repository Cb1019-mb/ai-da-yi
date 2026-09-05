import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 应用本地文件读写（设置 / 使用统计 / 知识库元信息）
class AppFiles {
  AppFiles._();

  static Future<File> file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name');
  }

  static Future<Map<String, dynamic>> readMap(String name) async {
    final f = await file(name);
    if (!f.existsSync()) return {};
    try {
      final data = jsonDecode(f.readAsStringSync());
      return data is Map<String, dynamic> ? data : {};
    } catch (_) {
      return {};
    }
  }

  static Future<void> writeMap(String name, Map<String, dynamic> data) async {
    final f = await file(name);
    await f.writeAsString(jsonEncode(data));
  }

  static Future<String> documentsPath() async =>
      (await getApplicationDocumentsDirectory()).path;
}
