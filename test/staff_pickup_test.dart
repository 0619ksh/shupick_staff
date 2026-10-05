import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shupick_staff/dashboard/staff_order_api.dart';
import 'package:shupick_staff/dashboard/staff_pages.dart';
import 'package:shupick_staff/dashboard/staff_views.dart';

class FakeStaffOrders implements StaffOrderRepository {
  final order = const StaffOrder(
    id: 10,
    number: 'ORD-10',
    status: 'READY_FOR_PICKUP',
    customerName: '테스트 고객',
    branchName: '강남점',
    products: ['운동화 · 검정 / 260 × 1'],
  );
  String? verifiedCode;
  String? completedCode;

  @override
  Future<List<StaffOrder>> listOrders({int? branchId}) async => [order];

  @override
  Future<StaffOrder> verifyPickup(String code) async {
    verifiedCode = code;
    return order;
  }

  @override
  Future<void> completePickup(StaffOrder order, String code) async {
    completedCode = code;
  }

  @override
  Future<void> markArrived(int fulfillmentId) async {}

  @override
  Future<void> shipFulfillment(int fulfillmentId) async {}
}

void main() {
  testWidgets('픽업 코드를 확인한 뒤 고객 수령을 완료한다', (tester) async {
    tester.view.physicalSize = const Size(1100, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final orders = FakeStaffOrders();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StaffPage(
              view: StaffView.pickup,
              roleKey: 'branchStaff',
              isBranch: true,
              selectedBranchId: 2,
              orderRepository: orders,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'ord-10');
    await tester.tap(find.text('코드 확인'));
    await tester.pumpAndSettle();
    expect(orders.verifiedCode, 'ORD-10');
    expect(find.text('고객 수령 완료'), findsOneWidget);

    await tester.tap(find.text('고객 수령 완료'));
    await tester.pumpAndSettle();
    expect(orders.completedCode, isNull);
    await tester.tap(find.text('인도 완료'));
    await tester.pumpAndSettle();
    expect(orders.completedCode, 'ORD-10');
  });
}
