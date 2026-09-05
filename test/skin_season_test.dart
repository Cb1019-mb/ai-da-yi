import 'package:flutter_test/flutter_test.dart';

import 'package:ai_da_yi/engine/skin_season.dart';

void main() {
  test('全暖+浅 → 春季型', () {
    // 每题的暖选项下标：Q1暖(1), Q2暖(0), Q3暖(0), Q4浅(1), Q5米白(1), Q6番茄红(0), Q7晒黑(0), Q8亮(0)
    const choices = [1, 0, 0, 1, 1, 0, 0, 0];
    expect(diagnoseSkinSeason(choices), '春季型');
  });

  test('全冷+深 → 冬季型', () {
    // Q1蓝紫(0), Q2银(1), Q3粉(1), Q4深(0), Q5纯白(0), Q6宝石红(3), Q7晒红(1), Q8柔(1)
    const choices = [0, 1, 1, 0, 0, 3, 1, 1];
    expect(diagnoseSkinSeason(choices), '冬季型');
  });

  test('题目与选项数量一致', () {
    expect(skinSeasonQuestions.length, 8);
    for (final q in skinSeasonQuestions) {
      expect(q.options.length, greaterThanOrEqualTo(2));
    }
  });

  group('skinSeasonColorMatch 颜色季型匹配', () {
    test('春季型适合米白、忌纯黑', () {
      expect(skinSeasonColorMatch('春季型', '#F0E6D3'), 1);
      expect(skinSeasonColorMatch('春季型', '#111111'), -1);
    });

    test('冬季型适合宝蓝', () {
      expect(skinSeasonColorMatch('冬季型', '#2F5FA8'), 1);
    });

    test('夏季型适合薄荷', () {
      expect(skinSeasonColorMatch('夏季型', '#A8C9B0'), 1);
    });

    test('秋季型忌荧光色', () {
      expect(skinSeasonColorMatch('秋季型', '#39FF14'), -1);
    });

    test('未设置季型返回 0', () {
      expect(skinSeasonColorMatch(null, '#FF0000'), 0);
      expect(skinSeasonColorMatch('', '#FF0000'), 0);
    });
  });
}
