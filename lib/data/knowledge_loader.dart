import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 体型指南条目（知识内容页展示用）
class BodyTypeGuide {
  final String gender;
  final String type;
  final String features;
  final String strategy;
  const BodyTypeGuide({
    required this.gender,
    required this.type,
    required this.features,
    required this.strategy,
  });
}

/// 纯函数：解析 body_types.json 中的体型描述部分
List<BodyTypeGuide> parseBodyTypeGuide(String json) {
  final m = jsonDecode(json) as Map<String, dynamic>;
  final result = <BodyTypeGuide>[];
  for (final gender in ['female', 'male']) {
    final list = (m[gender] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    for (final e in list) {
      result.add(BodyTypeGuide(
        gender: gender,
        type: e['type'] as String? ?? '',
        features: e['features'] as String? ?? '',
        strategy: e['strategy'] as String? ?? '',
      ));
    }
  }
  return result;
}

/// 从 assets 读取并解析
Future<List<BodyTypeGuide>> loadBodyTypeGuide() async {
  final raw = await rootBundle.loadString('assets/data/body_types.json');
  return parseBodyTypeGuide(raw);
}
