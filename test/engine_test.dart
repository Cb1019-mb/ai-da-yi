import 'package:flutter_test/flutter_test.dart';

import 'package:ai_da_yi/engine/hard_filter.dart';
import 'package:ai_da_yi/engine/matching_engine.dart';
import 'package:ai_da_yi/models/models.dart';

void main() {
  const female = UserProfile(gender: 'female', bodyType: '梨形');
  final filter = HardFilter();

  group('HardFilter 硬约束', () {
    test('性别过滤：男装不进女装方案', () {
      const wardrobe = [
        WardrobeItem(slot: 'top', gender: 'male', categoryName: '衬衫'),
        WardrobeItem(slot: 'top', gender: 'female', categoryName: '针织衫'),
        WardrobeItem(slot: 'top', gender: 'unisex', categoryName: 'T恤'),
      ];
      final out = filter.filter(wardrobe: wardrobe, profile: female);
      expect(out.length, 2);
      expect(out.every((i) => i.gender != 'male'), isTrue);
    });

    test('季节过滤：冬装不进夏季方案', () {
      const wardrobe = [
        WardrobeItem(slot: 'top', gender: 'female', season: ['夏']),
        WardrobeItem(slot: 'top', gender: 'female', season: ['冬']),
      ];
      final out =
          filter.filter(wardrobe: wardrobe, profile: female, season: '夏');
      expect(out.length, 1);
      expect(out.first.season, contains('夏'));
    });

    test('用户禁忌过滤', () {
      const wardrobe = [
        WardrobeItem(slot: 'top', gender: 'female', categoryName: '皮衣'),
        WardrobeItem(
            slot: 'top', gender: 'female', categoryName: '衬衫',
            styleTags: ['通勤']),
      ];
      const tabooProfile = UserProfile(gender: 'female', taboo: ['皮衣']);
      final out = filter.filter(wardrobe: wardrobe, profile: tabooProfile);
      expect(out.length, 1);
      expect(out.first.categoryName, '衬衫');
    });

    test('场合过滤：运动场合排除皮鞋', () {
      const wardrobe = [
        WardrobeItem(slot: 'shoes', gender: 'female', categoryName: '皮鞋'),
        WardrobeItem(slot: 'shoes', gender: 'female', categoryName: '运动鞋'),
      ];
      final out =
          filter.filter(wardrobe: wardrobe, profile: female, occasion: '运动');
      expect(out.length, 1);
      expect(out.first.categoryName, '运动鞋');
    });

    test('天气过滤：热天排除厚衣物，未填厚度不排除', () {
      const wardrobe = [
        WardrobeItem(slot: 'top', gender: 'female', thickness: 5),
        WardrobeItem(slot: 'top', gender: 'female', thickness: 2),
        WardrobeItem(slot: 'top', gender: 'female'),
      ];
      final out =
          filter.filter(wardrobe: wardrobe, profile: female, temperature: '热');
      expect(out.length, 2);
      expect(out.every((i) => i.thickness == null || i.thickness! <= 2),
          isTrue);
    });
  });

  group('MatchingEngine 组合生成', () {
    test('上装×下装×鞋 组合并按总分降序', () {
      const wardrobe = [
        WardrobeItem(
            slot: 'top', gender: 'female', colorMain: '#FFFFFF',
            formalLevel: 4, styleTags: ['通勤']),
        WardrobeItem(
            slot: 'bottom', gender: 'female', colorMain: '#1F3A5F',
            formalLevel: 4, styleTags: ['通勤']),
        WardrobeItem(
            slot: 'bottom', gender: 'female', colorMain: '#B7A68A',
            formalLevel: 2, styleTags: ['日系']),
        WardrobeItem(
            slot: 'shoes', gender: 'female', colorMain: '#1E1D1B',
            formalLevel: 4, styleTags: ['通勤']),
      ];
      final results = MatchingEngine().generate(
          wardrobe: wardrobe, profile: female, occasion: '通勤', limit: 8);
      expect(results.length, 2);
      for (final r in results) {
        expect(r.slots.keys, containsAll(['top', 'bottom', 'shoes']));
      }
      expect(results.first.score.total >= results.last.score.total, isTrue);
    });

    test('连衣裙单独成套', () {
      const wardrobe = [
        WardrobeItem(slot: 'dress', gender: 'female', colorMain: '#B8604A'),
        WardrobeItem(slot: 'shoes', gender: 'female', colorMain: '#FFFFFF'),
      ];
      final results =
          MatchingEngine().generate(wardrobe: wardrobe, profile: female);
      expect(results.length, 1);
      expect(results.first.slots.keys, containsAll(['dress', 'shoes']));
    });

    test('空衣橱无结果', () {
      final results =
          MatchingEngine().generate(wardrobe: const [], profile: female);
      expect(results, isEmpty);
    });

    test('配饰会附加到方案', () {
      const wardrobe = [
        WardrobeItem(slot: 'top', gender: 'female'),
        WardrobeItem(slot: 'bottom', gender: 'female'),
        WardrobeItem(slot: 'accessory', gender: 'female', categoryName: '丝巾'),
      ];
      final results =
          MatchingEngine().generate(wardrobe: wardrobe, profile: female);
      expect(results, isNotEmpty);
      expect(results.first.slots.keys, contains('accessory'));
    });

    test('避免重复：与近期记录完全重合的方案被降权', () {
      const topA = WardrobeItem(
          slot: 'top', gender: 'female', categoryName: '白衬衫',
          colorMain: '#FFFFFF', formalLevel: 4);
      const topB = WardrobeItem(
          slot: 'top', gender: 'female', categoryName: '白T恤',
          colorMain: '#FFFFFF', formalLevel: 4);
      const bottom = WardrobeItem(
          slot: 'bottom', gender: 'female', categoryName: '黑裤',
          colorMain: '#1E1D1B', formalLevel: 4);
      const shoes = WardrobeItem(
          slot: 'shoes', gender: 'female', categoryName: '黑鞋',
          colorMain: '#1E1D1B', formalLevel: 4);

      final recent = {topA, bottom, shoes}.map(itemFingerprint).toSet();
      final results = MatchingEngine().generate(
        wardrobe: const [topA, topB, bottom, shoes],
        profile: female,
        avoidFingerprints: [recent],
      );
      expect(results.length, 2);
      // 与近期记录完全重合（扣 12 分）的方案不应排第一
      expect(results.first.slots['top']!.categoryName, isNot('白衬衫'));
      expect(results.last.slots['top']!.categoryName, '白衬衫');
      expect(results.last.penalty, greaterThan(results.first.penalty));
    });
  });
}
