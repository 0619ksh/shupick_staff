import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shupick_staff/auth/staff_session.dart';
import 'package:shupick_staff/dashboard/dashboard_page.dart';
import 'package:shupick_staff/dashboard/staff_order_api.dart';
import 'package:shupick_staff/dashboard/staff_views.dart';
import 'package:shupick_staff/dashboard/staff_work_api.dart';
import 'package:shupick_staff/view/login.dart';

class LayoutOrders implements StaffOrderRepository {
  @override
  Future<List<StaffOrder>> listOrders({int? branchId}) async => [
    const StaffOrder(
      id: 1,
      number: 'ORD-20261006-123456789',
      status: 'IN_TRANSIT',
      customerName: '테스트 고객',
      branchName: 'SHOEPICK 강남점',
      products: ['긴 상품명을 가진 운동화 상품'],
      fulfillmentId: 1,
      fulfillmentStatus: 'IN_TRANSIT',
    ),
  ];
  @override
  Future<void> completePickup(StaffOrder order, String code) async {}
  @override
  Future<void> markArrived(int fulfillmentId) async {}
  @override
  Future<void> shipFulfillment(int fulfillmentId) async {}
  @override
  Future<StaffOrder> verifyPickup(String code) async =>
      (await listOrders()).first;
}

class LayoutWork extends StaffWorkApi {
  @override
  Future<Map<String, dynamic>> inventory({
    int? branchId,
    DateTime? asOf,
  }) async => {
    'branchName': 'SHOEPICK 강남점',
    'rows': [
      {
        'product_variant_id': 1,
        'product_name': '긴 상품명을 가진 운동화 상품',
        'product_code': 'SHOE-001',
        'color_name': '블랙',
        'size_mm': 260,
        'quantity': 7,
        'available_quantity': 2,
        'reserved_quantity': 5,
        'target_quantity': 20,
      },
    ],
  };
  @override
  Future<List<Map<String, dynamic>>> returns({int? branchId}) async => [
    {
      'id': 1,
      'orderNumber': 'ORD-20261006-123456789',
      'customerName': '고객',
      'branchName': 'SHOEPICK 강남점',
      'status': 'REQUESTED',
      'reason': '사이즈가 맞지 않습니다.',
    },
  ];
  @override
  Future<List<Map<String, dynamic>>> inquiries() async => [
    {
      'id': 1,
      'customerName': '고객',
      'title': '상품 수령 관련 문의입니다.',
      'type': 'DELIVERY',
      'status': 'OPEN',
      'body': '대리점에서 상품을 언제 받을 수 있나요?',
    },
  ];
  @override
  Future<List<Map<String, dynamic>>> customers() async => [
    {'id': 1, 'name': '고객', 'email': 'customer@example.com'},
  ];
  @override
  Future<List<Map<String, dynamic>>> requisitions() async => [
    for (final status in ['PENDING_TEAM_LEAD', 'PENDING_DIRECTOR'])
      {
        'id': status == 'PENDING_TEAM_LEAD' ? 1 : 2,
        'status': status,
        'title': '운동화 재고 보충 요청',
        'branchName': 'SHOEPICK 강남점',
        'employeeName': '본사 직원',
        'reason': '재고를 보충해주세요.',
        'items': [
          {
            'productName': '운동화',
            'colorName': '블랙',
            'sizeMm': 260,
            'quantity': 10,
          },
        ],
      },
  ];
  @override
  Future<List<Map<String, dynamic>>> branches() async => [];
  @override
  Future<Map<String, dynamic>> analytics({
    int days = 28,
    int? productId,
    int? branchId,
  }) async => {
    'quantity': 10,
    'revenue': 123456789,
    'orderCount': 3,
    'products': [],
    'branches': [],
    'byDay': [
      for (var day = 1; day <= 28; day++)
        {'day': '2026-09-${day.toString().padLeft(2, '0')}', 'quantity': day},
    ],
    'byProduct': [
      {'productName': '긴 상품명을 가진 운동화 상품', 'quantity': 10},
    ],
  };
}

class BrokenInventory extends LayoutWork {
  @override
  Future<Map<String, dynamic>> inventory({
    int? branchId,
    DateTime? asOf,
  }) async => throw const StaffAuthException('재고 API 조회 실패');
}

Widget screen(StaffRole role, {StaffWorkApi? work, double textScale = 1.5}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563C6),
          surface: Colors.white,
        ),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: DashboardPage(
        key: ValueKey(role),
        initialRole: role,
        availableRoles: [role],
        employeeName: '이름이 긴 테스트 대리점 직원',
        branch: 'SHOEPICK 강남구 테스트 대리점',
        selectedBranchId: 4,
        availableBranches: const {4: 'SHOEPICK 강남구 테스트 대리점'},
        onSelectBranch: (_) {},
        onSignOut: () {},
        orderRepository: LayoutOrders(),
        workApi: work ?? LayoutWork(),
      ),
    );

void main() {
  testWidgets('작은 화면과 큰 글자에서 로그인·직원 등록도 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
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
        home: Login(onSignIn: (_, _) async {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('staff-register')));
    await tester.tap(find.byKey(const Key('staff-register')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final size in [
    const Size(360, 640),
    const Size(800, 1024),
    const Size(1024, 600),
    const Size(1280, 800),
    const Size(700, 320),
  ]) {
    testWidgets('크기 $size, 큰 글자에서 모든 직책의 업무 화면이 넘치지 않는다', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final role in StaffRole.values) {
        await tester.pumpWidget(screen(role));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$role overview $size');
        if (role.isBranch) {
          expect(find.text('입고 확인 대기'), findsOneWidget);
          expect(find.text('현재 보관 수량'), findsOneWidget);
        }
        for (final menu in menusForRole(role.name).skip(1)) {
          if (size.width < 700) {
            await tester.tap(find.byIcon(Icons.menu));
            await tester.pumpAndSettle();
          }
          final target = find.byKey(Key('menu-${menu.view.name}'));
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          await tester.tap(target);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$role ${menu.view} $size',
          );
        }
      }
    });
  }
  for (final role in [StaffRole.branchStaff, StaffRole.branchManager]) {
    testWidgets('$role 재고 조회가 실패해도 지점 대시보드와 주문 집계는 표시한다', (tester) async {
      tester.view.physicalSize = const Size(800, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(screen(role, work: BrokenInventory()));
      await tester.pumpAndSettle();
      expect(find.text('입고 확인 대기'), findsOneWidget);
      expect(find.text('1건'), findsWidgets);
      expect(find.text('현재 보관 수량'), findsOneWidget);
      expect(find.textContaining('재고 API 조회 실패'), findsOneWidget);
      expect(find.text('빠른 업무'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
