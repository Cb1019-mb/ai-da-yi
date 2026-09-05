import 'package:flutter_test/flutter_test.dart';

import 'package:ai_da_yi/engine/scoring.dart';
import 'package:ai_da_yi/models/models.dart';

const _profile = UserProfile(gender: 'female', bodyType: '梨形');

void main() {
  group('colorScore 色彩和谐度', () {
    test('中性色组合得高分', () {
      final slots = {
        'top': const WardrobeItem(
            slot: 'top', gender: 'female', colorMain: '#F0E6D3'),
        'bottom': const WardrobeItem(
            slot: 'bottom', gender: 'female', colorMain: '#1F3A5F'),
      };
      expect(colorScore(slots), greaterThan(70));
    });
  });

  group('styleScore 风格一致性', () {
    test('风格命中率高', () {
      const style = Style(name: '法式', gender: 'female', features: ['优雅']);
      final slots = {
        'top': const WardrobeItem(
            slot: 'top', gender: 'female', styleTags: ['法式']),
        'bottom': const WardrobeItem(
            slot: 'bottom', gender: 'female', styleTags: ['法式']),
      };
      expect(styleScore(slots, style), 100);
    });
  });

  group('bodyTypeScore 体型适配', () {
    const rules = [
      BodyTypeRule(
          gender: 'female', bodyType: '梨形', slot: 'bottom', attribute: '颜色=深色', effect: 1),
    ];
    test('梨形 + 深色下装加分', () {
      final slots = {
        'top': const WardrobeItem(
            slot: 'top', gender: 'female', colorMain: '#FFFFFF'),
        'bottom': const WardrobeItem(
            slot: 'bottom', gender: 'female', colorMain: '#1F1F1F'),
      };
      expect(bodyTypeScore(slots, _profile, rules), greaterThan(50));
    });
  });

  group('scoreOutfit 综合评分', () {
    test('返回 0-100 且含配色说明', () {
      final slots = {
        'top': const WardrobeItem(
            slot: 'top', gender: 'female', colorMain: '#F0E6D3',
            formalLevel: 4, exposure: 1, styleTags: ['通勤']),
        'bottom': const WardrobeItem(
            slot: 'bottom', gender: 'female', colorMain: '#2F3E46',
            formalLevel: 4, exposure: 1, styleTags: ['通勤']),
      };
      const style = Style(name: '通勤', gender: 'female');
      final s = scoreOutfit(
          slots: slots, profile: _profile, occasion: '通勤', targetStyle: style);
      expect(s.total, inInclusiveRange(0, 100));
      expect(s.colorNote, isNotEmpty);
    });
  });

  group('skinSeasonScore 肤色季型驱动', () {
    test('设置季型后，适配色提升色彩分', () {
      final slots = {
        'top': const WardrobeItem(
            slot: 'top', gender: 'female', colorMain: '#F0E6D3'),
      };
      const p1 = UserProfile(gender: 'female');
      const p2 = UserProfile(gender: 'female', skinSeason: '春季型');
      final s1 = scoreOutfit(slots: slots, profile: p1);
      final s2 = scoreOutfit(slots: slots, profile: p2);
      expect(s2.color, greaterThan(s1.color));
    });
  });
}
