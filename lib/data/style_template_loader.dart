import 'dart:convert';

import '../models/style_template.dart';
import '../services/kb_sync.dart';

/// 纯函数：解析风格模板 JSON
List<StyleTemplate> parseStyleTemplates(String json) {
  final list = jsonDecode(json) as List;
  return list
      .cast<Map<String, dynamic>>()
      .map(StyleTemplate.fromJson)
      .toList();
}

/// 加载风格模板：优先 kb_override 覆盖文件，回退内置资产
Future<List<StyleTemplate>> loadStyleTemplates() async {
  final raw = await KbSync.load('style_templates');
  return parseStyleTemplates(raw);
}
