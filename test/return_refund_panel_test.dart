import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shupick_staff/auth/staff_session.dart';
import 'package:shupick_staff/dashboard/return_refund_panel.dart';
import 'package:shupick_staff/dashboard/staff_work_api.dart';

class RefundApi extends StaffWorkApi {
  bool testPayment = true;
  bool fail = false;
  int calls = 0;
  int? amount;
  @override
  Future<Map<String, dynamic>> returnRefund(int id) async => {
    'returnId': id,
    'orderNumber': 'ORD-10',
    'customerName': '환불 고객',
    'testPayment': testPayment,
    'refundAmount': 12345,
    'allocatedPoints': 500,
    'returnStatus': 'APPROVED',
    'refund': null,
    'items': [
      {
        'name': '긴 이름의 테스트 운동화 상품',
        'color': 'BLACK',
        'size': 260,
        'quantity': 1,
        'refundAmount': 12345,
        'allocatedPoints': 500,
      },
    ],
  };
  @override
  Future<Map<String, dynamic>> processTestReturnRefund(
    int id,
    int expectedAmount,
  ) async {
    calls++;
    amount = expectedAmount;
    if (fail) throw const StaffAuthException('환불 금액이 변경되었습니다. 내역을 다시 조회해주세요.');
    return {
      'refundStatus': 'SUCCEEDED',
      'refundNumber': 'RF-70',
      'refundAmount': 12345,
    };
  }
}

Future<void> showRefund(
  WidgetTester tester,
  RefundApi api, {
  double width = 800,
  Future<void> Function()? onProcessed,
}) async {
  tester.view.physicalSize = Size(width, 900);
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
            child: ReturnRefundPanel(
              api: api,
              returns: const [
                {
                  'id': 3,
                  'orderNumber': 'ORD-10',
                  'customerName': '환불 고객',
                  'status': 'APPROVED',
                },
              ],
              onProcessed: onProcessed ?? () async {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('refund-return-3')));
  await tester.pumpAndSettle();
}

Future<void> beginRefund(WidgetTester tester) async {
  final button = find.byKey(const Key('process-return-refund'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('확인한 환불 금액을 보내고 성공 후 다시 처리할 수 없다', (tester) async {
    final api = RefundApi();
    var refreshed = 0;
    await showRefund(
      tester,
      api,
      onProcessed: () async {
        refreshed++;
      },
    );
    expect(find.text('환불 금액 12,345원'), findsOneWidget);
    await beginRefund(tester);
    expect(api.calls, 0);
    await tester.tap(find.byKey(const Key('confirm-return-refund')));
    await tester.pumpAndSettle();
    expect(api.amount, 12345);
    expect(api.calls, 1);
    expect(refreshed, 1);
    expect(find.text('테스트 환불 완료 · RF-70'), findsOneWidget);
    expect(find.byKey(const Key('process-return-refund')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('취소 또는 서버 실패 시 환불 완료로 표시하지 않는다', (tester) async {
    final api = RefundApi()..fail = true;
    await showRefund(tester, api);
    await beginRefund(tester);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(api.calls, 0);
    await beginRefund(tester);
    await tester.tap(find.byKey(const Key('confirm-return-refund')));
    await tester.pumpAndSettle();
    expect(find.textContaining('금액이 변경되었습니다'), findsOneWidget);
    expect(find.textContaining('테스트 환불 완료'), findsNothing);
    expect(find.byKey(const Key('process-return-refund')), findsOneWidget);
  });
  testWidgets('실제 결제 거래에는 테스트 환불 버튼이 없다', (tester) async {
    await showRefund(tester, RefundApi()..testPayment = false);
    expect(find.byKey(const Key('process-return-refund')), findsNothing);
    expect(find.textContaining('실제 결제사 연동'), findsOneWidget);
  });
  testWidgets('작은 화면·큰 글자에서도 환불 내역과 확인 창이 넘치지 않는다', (tester) async {
    await showRefund(tester, RefundApi(), width: 360);
    expect(tester.takeException(), isNull);
    await beginRefund(tester);
    expect(tester.takeException(), isNull);
  });
}
