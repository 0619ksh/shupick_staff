import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shupick_staff/auth/staff_session.dart';
import 'package:shupick_staff/dashboard/branch_return_registration.dart';
import 'package:shupick_staff/dashboard/staff_work_api.dart';

class ReturnApi extends StaffWorkApi {
  int? lookedUpBranch;
  Map<String, dynamic>? submitted;
  int? submittedOrder;
  bool fail = false;
  @override
  Future<Map<String, dynamic>> lookupReturnOrder(
    int branchId,
    String code,
  ) async {
    lookedUpBranch = branchId;
    return {
      'orderId': 10,
      'orderNumber': 'ORD-10',
      'customerName': '고객',
      'branchName': 'SHOEPICK 강남점',
      'pickedUpAt': '2026-10-05T10:00:00',
      'returnDeadlineAt': '2026-10-12T10:00:00',
      'items': [
        {
          'itemKey': '5-260-BLACK',
          'name': '이름이 긴 테스트 운동화',
          'color': 'BLACK',
          'size': 260,
          'quantity': 2,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> registerReturn(
    int orderId,
    Map<String, dynamic> details,
  ) async {
    if (fail) throw const StaffAuthException('소속 지점 직원만 접수할 수 있습니다.');
    submittedOrder = orderId;
    submitted = details;
    return {'id': 70, 'status': 'REQUESTED'};
  }
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> lookup(
  WidgetTester tester,
  ReturnApi api, {
  double width = 800,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.5)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BranchReturnRegistration(
              branchId: 4,
              api: api,
              onRegistered: () async {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.enterText(find.byKey(const Key('return-order-code')), 'ORD-10');
  await tapKey(tester, 'return-order-lookup');
}

void main() {
  testWidgets('상품·조건을 확인한 직원 접수 내용을 보내고 접수번호를 표시한다', (tester) async {
    final api = ReturnApi();
    await lookup(tester, api);
    expect(api.lookedUpBranch, 4);
    await tapKey(tester, 'branch-return-submit');
    expect(api.submitted, isNull);
    expect(find.text('반품 상품·수량을 선택하고 사유를 입력해주세요.'), findsOneWidget);
    await tapKey(tester, 'return-quantity-5-260-BLACK');
    await tester.tap(find.text('1켤레').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('return-reason')),
      '사이즈가 맞지 않습니다.',
    );
    await tapKey(tester, 'branch-return-submit');
    expect(api.submitted, isNull);
    for (final text in ['미착용 확인', '상품 훼손 없음 확인', '구성품 및 포장 유지 확인']) {
      await tester.ensureVisible(find.text(text));
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }
    await tapKey(tester, 'branch-return-submit');
    expect(api.submittedOrder, 10);
    expect(api.submitted!['items'], [
      {'itemKey': '5-260-BLACK', 'quantity': 1},
    ]);
    expect(api.submitted!['unworn'], true);
    expect(api.submitted!['reasonCode'], 'CUSTOMER_CHANGE');
    expect(find.text('반품 #70 접수 완료 · 본사 검수 대기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('하자 접수의 서버 실패 사유를 표시하고 입력 내용을 유지한다', (tester) async {
    final api = ReturnApi()..fail = true;
    await lookup(tester, api);
    await tapKey(tester, 'return-reason-code');
    await tester.tap(find.text('상품 하자').last);
    await tester.pumpAndSettle();
    await tapKey(tester, 'return-quantity-5-260-BLACK');
    await tester.tap(find.text('2켤레').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('return-reason')), '밑창 불량');
    await tapKey(tester, 'branch-return-submit');
    expect(find.text('소속 지점 직원만 접수할 수 있습니다.'), findsOneWidget);
    expect(find.text('밑창 불량'), findsOneWidget);
    expect(find.text('접수 사유'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('작은 화면·큰 글자에서 접수 폼이 넘치지 않고 주문번호 변경 시 선택을 지운다', (tester) async {
    await lookup(tester, ReturnApi(), width: 360);
    expect(find.text('반품할 상품과 수량'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const Key('return-order-code')),
      'ORD-11',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('branch-return-submit')), findsNothing);
  });
}
