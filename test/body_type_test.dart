import 'package:flutter_test/flutter_test.dart';

import 'package:ai_da_yi/engine/body_type.dart';

void main() {
  group('女性体型判型', () {
    test('沙漏型：腰臀比小且胸臀接近', () {
      expect(
          inferBodyType(gender: 'female', chest: 88, waist: 66, hip: 92),
          '沙漏型');
    });
    test('梨形：臀围明显大于胸围', () {
      expect(
          inferBodyType(gender: 'female', chest: 84, waist: 70, hip: 96),
          '梨形');
    });
    test('苹果形：腰腹接近臀围', () {
      expect(
          inferBodyType(gender: 'female', chest: 92, waist: 88, hip: 96),
          '苹果形');
    });
    test('倒三角：胸围明显大于臀围', () {
      expect(
          inferBodyType(gender: 'female', chest: 92, waist: 72, hip: 84),
          '倒三角');
    });
    test('矩形：其余情况', () {
      expect(
          inferBodyType(gender: 'female', chest: 86, waist: 74, hip: 90),
          '矩形');
    });
  });

  group('男性体型判型', () {
    test('梯形：有肩腰差的匀称型', () {
      expect(
          inferBodyType(gender: 'male', chest: 96, waist: 80, hip: 96),
          '梯形');
    });
    test('椭圆：腰围接近胸围', () {
      expect(
          inferBodyType(gender: 'male', chest: 100, waist: 98, hip: 100),
          '椭圆');
    });
    test('矩形：直线型', () {
      expect(
          inferBodyType(gender: 'male', chest: 88, waist: 78, hip: 90),
          '矩形');
    });
    test('倒三角：胸围明显大于臀围', () {
      expect(
          inferBodyType(gender: 'male', chest: 104, waist: 82, hip: 92),
          '倒三角');
    });
    test('数据不全返回 null', () {
      expect(
          inferBodyType(gender: 'male', chest: 96, waist: null, hip: 90),
          isNull);
    });
  });
}
