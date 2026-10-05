import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shupick_staff/dashboard/staff_order_api.dart';
import 'package:shupick_staff/dashboard/staff_overview.dart';
import 'package:shupick_staff/dashboard/staff_views.dart';
import 'package:shupick_staff/dashboard/staff_work_api.dart';

StaffOrder order(String status, String fulfillment, {int id = 1}) => StaffOrder(
  id: id,
  number: 'ORD-$id',
  status: status,
  customerName: '고객',
  branchName: '강남점',
  products: const ['운동화'],
  fulfillmentStatus: fulfillment,
);

Map<String, dynamic> hqInventory() => {
  'rows': [
    {'product_name': '운동화', 'available_quantity': 2, 'target_quantity': 20},
    {'product_name': '구두', 'available_quantity': 18, 'target_quantity': 20},
  ],
};

class FakeOrderRepository implements StaffOrderRepository {
  final requestedBranches = <int?>[];

  @override
  Future<List<StaffOrder>> listOrders({int? branchId}) async {
    requestedBranches.add(branchId);
    return branchId == 4
        ? [order('READY_FOR_PICKUP', 'READY_FOR_PICKUP')]
        : [order('IN_TRANSIT', 'IN_TRANSIT')];
  }

  @override
  Future<void> completePickup(StaffOrder order, String code) async {}
  @override
  Future<void> markArrived(int fulfillmentId) async {}
  @override
  Future<void> shipFulfillment(int fulfillmentId) async {}
  @override
  Future<StaffOrder> verifyPickup(String code) async =>
      order('READY_FOR_PICKUP', 'READY_FOR_PICKUP');
}

class FakeWorkApi extends StaffWorkApi {
  final requestedBranches = <int?>[];

  @override
  Future<Map<String, dynamic>> inventory({
    int? branchId,
    DateTime? asOf,
  }) async => {
    'rows': [
      {'quantity': branchId == 4 ? 7 : 3},
    ],
  };

  @override
  Future<List<Map<String, dynamic>>> returns({int? branchId}) async {
    requestedBranches.add(branchId);
    return branchId == 4
        ? []
        : [
            {'status': 'REQUESTED'},
          ];
  }
}

void main() {
  test('지점 대시보드는 입고·픽업·반품·보관 수량을 실제 조회 결과로 집계한다', () {
    final snapshot = branchOverview(
      [
        order('IN_TRANSIT', 'IN_TRANSIT'),
        order('READY_FOR_PICKUP', 'READY_FOR_PICKUP', id: 2),
      ],
      [
        {'status': 'REQUESTED'},
        {'status': 'APPROVED'},
      ],
      {
        'rows': [
          {'quantity': 2},
          {'quantity': 5},
        ],
      },
    );
    expect(snapshot.metrics.map((metric) => metric.value), [
      '1건',
      '1건',
      '1건',
      '7켤레',
    ]);
    expect(snapshot.alerts.map((alert) => alert.view), [
      StaffView.inbound,
      StaffView.pickup,
      StaffView.returns,
    ]);
  });

  test('본사·결재·임원 요약은 각 직책의 실제 데이터만 사용한다', () {
    final hq = headquartersStaffOverview(
      [order('PREPARING', 'PREPARING')],
      [
        {'status': 'OPEN'},
        {'status': 'ANSWERED'},
      ],
      [
        {'status': 'REQUESTED'},
      ],
      hqInventory(),
    );
    expect(hq.metrics.map((metric) => metric.value), ['1건', '1건', '1건', '1종']);

    final requisitions = [
      {'status': 'PENDING_TEAM_LEAD'},
      {'status': 'PENDING_DIRECTOR'},
      {'status': 'APPROVED'},
    ];
    final leader = approverOverview('teamLeader', requisitions, hqInventory());
    final director = approverOverview('director', requisitions, hqInventory());
    expect(leader.metrics.first.value, '1건');
    expect(director.metrics.first.value, '1건');
    expect(leader.alerts.first.view, StaffView.approvals);

    final executive = executiveOverview(
      {'quantity': 3, 'revenue': 123000, 'orderCount': 2},
      requisitions,
      hqInventory(),
    );
    expect(executive.metrics[0].value, '3켤레');
    expect(executive.metrics[1].value, '₩123,000');
    expect(executive.alerts.length, 2);
  });

  testWidgets('선택 지점 변경 시 새 지점 데이터를 다시 불러오고 알림을 연결한다', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final orders = FakeOrderRepository();
    final work = FakeWorkApi();
    StaffView? opened;

    Widget screen(int branchId) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StaffOverview(
            roleKey: 'branchStaff',
            selectedBranchId: branchId,
            orderRepository: orders,
            workApi: work,
            onOpenView: (view) => opened = view,
          ),
        ),
      ),
    );

    await tester.pumpWidget(screen(3));
    await tester.pumpAndSettle();
    expect(find.text('입고 확인 필요'), findsOneWidget);
    expect(find.text('3켤레'), findsOneWidget);
    await tester.tap(find.text('입고 확인 필요'));
    expect(opened, StaffView.inbound);

    await tester.pumpWidget(screen(4));
    await tester.pumpAndSettle();
    expect(find.text('고객 수령 대기'), findsWidgets);
    expect(find.text('7켤레'), findsOneWidget);
    expect(orders.requestedBranches, [3, 4]);
    expect(work.requestedBranches, [3, 4]);
  });
}
