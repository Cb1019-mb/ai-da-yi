import 'package:flutter_test/flutter_test.dart';

import 'package:ai_da_yi/main.dart';

void main() {
  testWidgets('App 冒烟测试：首页渲染底部导航', (WidgetTester tester) async {
    await tester.pumpWidget(const AiDaYiApp());
    await tester.pump();

    expect(find.text('衣橱'), findsOneWidget);
    expect(find.text('搭配'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });
}
