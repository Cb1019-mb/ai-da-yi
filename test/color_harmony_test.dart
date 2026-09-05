import 'package:flutter_test/flutter_test.dart';

import 'package:ai_da_yi/core/color_harmony.dart';

void main() {
  group('hueDistance 色相环角度差', () {
    test('同色相为 0', () {
      expect(hueDistance(120, 120), 0);
    });

    test('跨 0 度取最短距离', () {
      expect(hueDistance(350, 10), closeTo(20, 0.001));
    });

    test('互补为 180', () {
      expect(hueDistance(0, 180), 180);
    });
  });

  group('harmonyType 配色关系', () {
    test('同色系 / 类比 / 互补', () {
      expect(harmonyType(220, 225), '同色系');
      expect(harmonyType(220, 250), '类比色');
      expect(harmonyType(220, 40), '互补色');
    });
  });

  group('outfitColorScore 整身配色', () {
    test('全中性搭配应得高分', () {
      final score = outfitColorScore([
        const OutfitColorItem(HsvColor(215, 0.6, 0.28), 0.6), // 藏青
        const OutfitColorItem(HsvColor(40, 0.14, 0.94), 0.3), // 米白
        const OutfitColorItem(HsvColor(30, 0.4, 0.62), 0.1), // 驼色
      ]);
      expect(score, greaterThan(80));
    });

    test('冲突区配色应得低分', () {
      final score = outfitColorScore([
        const OutfitColorItem(HsvColor(0, 0.9, 0.8), 0.5),
        const OutfitColorItem(HsvColor(90, 0.9, 0.8), 0.5),
      ]);
      expect(score, lessThan(60));
    });
  });

  group('hsvToHex', () {
    test('纯红', () {
      expect(hsvToHex(0, 1, 1), '#FF0000');
    });

    test('HSV→HEX→HSV 往返一致', () {
      const h = 214.7, s = 0.674, v = 0.373;
      final back = hexToHsv(hsvToHex(h, s, v));
      expect(hueDistance(back.h, h), lessThan(3));
      expect((back.s - s).abs(), lessThan(0.03));
      expect((back.v - v).abs(), lessThan(0.03));
    });
  });
}
