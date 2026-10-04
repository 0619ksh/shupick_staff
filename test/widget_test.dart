import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shupick_staff/main.dart';

void main() {
  testWidgets('직책별 대시보드 화면을 미리 볼 수 있다', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    expect(find.text('SOLE OPS'), findsOneWidget);
    expect(find.text('오늘 입고 예정'), findsOneWidget);

    await tester.tap(find.byKey(const Key('role-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('본사 사원').last);
    await tester.pumpAndSettle();
    expect(find.text('발송 대기'), findsWidgets);
    expect(find.text('고객 구매 요청'), findsOneWidget);
  });

  testWidgets('좁은 화면에서도 대시보드가 표시된다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    expect(find.text('오늘 입고 예정'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
