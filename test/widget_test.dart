import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shupick_staff/main.dart';

Future<void> enterDashboard(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('role-branchStaff')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('직책별 대시보드 화면을 미리 볼 수 있다', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    expect(find.text('업무에 맞는 화면으로 시작하세요'), findsOneWidget);
    await enterDashboard(tester);
    expect(find.text('SHOEPICK'), findsOneWidget);
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
    await enterDashboard(tester);
    expect(find.text('오늘 입고 예정'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('태블릿 세로 화면에서 메뉴와 업무 화면이 표시된다', (tester) async {
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await enterDashboard(tester);
    expect(find.byKey(const Key('menu-pickup')), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
    await tester.tap(find.byKey(const Key('menu-pickup')));
    await tester.pumpAndSettle();
    expect(find.text('픽업 결제 코드 확인'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('직책별 업무 메뉴 화면을 열 수 있다', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await enterDashboard(tester);

    Future<void> open(String view, String heading) async {
      final menu = find.byKey(Key('menu-$view'));
      await tester.ensureVisible(menu);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(find.text(heading), findsWidgets);
      expect(tester.takeException(), isNull);
    }

    Future<void> chooseRole(String label) async {
      await tester.tap(find.byKey(const Key('role-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    await open('inbound', '입고 대상 주문');
    await open('pickup', '픽업 결제 코드 확인');
    await open('returns', '반품 대상 조회');
    await open('exchanges', '교환 요청 접수');
    await open('stockLookup', '현재 지점 재고');
    await open('communication', '새 대화');

    await chooseRole('대리점장');
    await open('inventory', '제품별 재고');

    await chooseRole('본사 사원');
    await open('orders', '주문 조회');
    await open('customers', '고객 목록');
    await open('shipping', '주문별 배송 단계');
    await open('exchanges', '교환품 발송 대기');
    await open('inventory', '제품별 본사 재고');
    await open('requests', '제조사 구매 품의 작성');
    await open('communication', '새 대화');

    await chooseRole('본사 팀장');
    await open('approvals', '1차 결재 대기');
    await open('customers', '혜택 승인 요청');

    await chooseRole('본사 이사');
    await open('approvals', '최종 결재 대기');

    await chooseRole('본사 임원');
    await open('analytics', '일자별 판매량');
    await open('approvals', '결재 현황');
  });

  testWidgets('픽업 결제 코드로 수령 대기 주문을 확인한다', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await enterDashboard(tester);
    await tester.tap(find.byKey(const Key('menu-pickup')));
    await tester.pumpAndSettle();

    final codeField = find.widgetWithText(TextField, '예: PICKUP-1038');
    await tester.enterText(codeField, 'WRONG-CODE');
    await tester.tap(find.text('코드 확인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('일치하는 수령 대기 주문이 없습니다.'), findsOneWidget);

    await tester.enterText(codeField, 'PICKUP-1038');
    await tester.tap(find.text('코드 확인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('코드 확인 완료'), findsOneWidget);
    expect(find.text('캔버스화 · 네이비 / 250'), findsWidgets);
  });

  testWidgets('모바일 메뉴에서 픽업 코드 확인 화면을 열 수 있다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await enterDashboard(tester);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-pickup')));
    await tester.pumpAndSettle();

    expect(find.text('픽업 결제 코드 확인'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
