import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_da_yi/data/style_template_loader.dart';

void main() {
  final raw = File('assets/data/style_templates.json').readAsStringSync();
  final templates = parseStyleTemplates(raw);

  test('模板数量正确（女10 + 男8）', () {
    expect(templates.length, 18);
    expect(templates.where((t) => t.gender == 'female').length, 10);
    expect(templates.where((t) => t.gender == 'male').length, 8);
  });

  test('每个模板都有图片文件名和至少 3 件单品', () {
    for (final t in templates) {
      expect(t.image, isNotEmpty);
      expect(t.items.length, greaterThanOrEqualTo(3));
    }
  });

  test('模板单品可转成衣橱单品', () {
    final t = templates.first;
    final item = t.items.first.toWardrobeItem(t.gender);
    expect(item.gender, t.gender);
    expect(item.slot, isNotEmpty);
    expect(item.categoryName, isNotEmpty);
    expect(item.colorMain, isNotEmpty);
  });

  test('图片文件实际存在', () {
    for (final t in templates) {
      final f = File('assets/images/templates/${t.image}');
      expect(f.existsSync(), isTrue, reason: '缺少图片 ${t.image}');
    }
  });
}
