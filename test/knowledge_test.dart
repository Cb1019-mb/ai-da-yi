import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_da_yi/data/knowledge_loader.dart';

void main() {
  test('体型指南解析：女5男5', () {
    final raw = File('assets/data/body_types.json').readAsStringSync();
    final guides = parseBodyTypeGuide(raw);
    expect(guides.length, 10);
    expect(guides.where((g) => g.gender == 'female').length, 5);
    expect(guides.where((g) => g.gender == 'male').length, 5);
    for (final g in guides) {
      expect(g.type, isNotEmpty);
      expect(g.strategy, isNotEmpty);
    }
  });
}
