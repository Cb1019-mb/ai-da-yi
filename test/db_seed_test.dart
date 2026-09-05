import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_da_yi/data/seed_loader.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('解析种子数据：品类/风格/体型规则数量正确', () {
    final data = parseSeeds(
      categoriesJson: _read('assets/data/categories.json'),
      stylesJson: _read('assets/data/styles.json'),
      bodyTypesJson: _read('assets/data/body_types.json'),
    );

    expect(data.categories.length, greaterThan(10));
    expect(data.styles.length, greaterThan(15));
    expect(data.bodyTypeRules.length, greaterThan(10));
  });

  test('体型规则部位已映射为英文 slot', () {
    final data = parseSeeds(
      categoriesJson: _read('assets/data/categories.json'),
      stylesJson: _read('assets/data/styles.json'),
      bodyTypesJson: _read('assets/data/body_types.json'),
    );

    const validSlots = {'top', 'bottom', 'dress', 'shoes', 'accessory', '任意'};
    for (final r in data.bodyTypeRules) {
      expect(validSlots.contains(r.slot), isTrue,
          reason: '非法 slot: ${r.slot}');
    }
  });
}
