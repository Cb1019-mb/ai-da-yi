import 'package:flutter_test/flutter_test.dart';

import 'package:ai_da_yi/engine/gap_analysis.dart';
import 'package:ai_da_yi/models/models.dart';

void main() {
  test('缺口分析：互为包含即命中', () {
    const style = Style(
        name: '通勤', gender: 'female', requiredItems: ['衬衫', '乐福鞋', '丝巾']);
    const wardrobe = [
      WardrobeItem(slot: 'top', gender: 'female', categoryName: '衬衫'),
      WardrobeItem(slot: 'shoes', gender: 'female', categoryName: '乐福鞋'),
    ];
    expect(missingForStyle(style, wardrobe), ['丝巾']);
  });

  test('「基础T恤」可被衣橱中的「T恤」命中', () {
    const style =
        Style(name: '极简', gender: 'female', requiredItems: ['基础T恤']);
    const wardrobe = [
      WardrobeItem(slot: 'top', gender: 'female', categoryName: 'T恤'),
    ];
    expect(missingForStyle(style, wardrobe), isEmpty);
  });

  test('必备为空则无缺口', () {
    const style = Style(name: '自由', gender: 'female', requiredItems: []);
    expect(
        missingForStyle(style, const [WardrobeItem(slot: 'top', gender: 'female')]),
        isEmpty);
  });
}
