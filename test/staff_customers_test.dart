import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shupick_staff/dashboard/staff_pages.dart';
import 'package:shupick_staff/dashboard/staff_views.dart';
import 'package:shupick_staff/dashboard/staff_work_api.dart';

class CustomersApi extends StaffWorkApi {
  @override
  Future<List<Map<String, dynamic>>> inquiries() async => [];
  @override
  Future<List<Map<String, dynamic>>> customers() async => [
    {
      'id': 1,
      'name': '다 고객',
      'orderCount': 5,
      'paidTotal': '900',
      'lastOrderedAt': '2026-10-01T10:00:00',
    },
    {
      'id': 2,
      'name': '가 고객',
      'orderCount': 1,
      'paidTotal': 100,
      'lastOrderedAt': '2026-10-04T10:00:00',
      'pointBalance': 3000,
    },
    {
      'id': 3,
      'name': '나 고객',
      'orderCount': 2,
      'paidTotal': '1000',
      'lastOrderedAt': null,
    },
  ];
  @override
  Future<Map<String, dynamic>> customerDetail(int id) async => {
    'id': id,
    'name': '가 고객',
    'email': 'customer.with.a.long.email@example.com',
    'phone': null,
    'orders': [
      {
        'id': 10,
        'number': 'ORD-20261006-123456789',
        'status': 'COMPLETED',
        'paidTotal': '12345',
        'orderedAt': '2026-10-04T10:00:00',
        'branchName': 'SHOEPICK 강남점',
      },
    ],
    'returns': [
      {
        'id': 7,
        'orderId': 10,
        'status': 'REQUESTED',
        'reason': '사이즈가 맞지 않습니다.',
      },
    ],
  };
}

Future<void> showCustomers(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
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
            child: StaffPage(
              view: StaffView.customers,
              roleKey: 'hqStaff',
              isBranch: false,
              workApi: CustomersApi(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('정렬 드롭다운이 날짜·이름·숫자 기준으로 목록을 정렬하고 검색에도 유지된다', (tester) async {
    await showCustomers(tester, const Size(1100, 1600));
    void check(List<int> ids) {
      final offsets = [
        for (final id in ids)
          tester.getTopLeft(find.byKey(Key('customer-$id'))).dy,
      ];
      expect(offsets[0], lessThan(offsets[1]));
      expect(offsets[1], lessThan(offsets[2]));
    }

    check([2, 1, 3]);
    for (final choice in {
      '이름순 (가나다)': [2, 3, 1],
      '누적 결제액 높은순': [3, 1, 2],
      '주문 횟수 많은순': [1, 3, 2],
    }.entries) {
      final sorting = find.byKey(const Key('customer-sort'));
      await tester.ensureVisible(sorting);
      await tester.tap(
        find.descendant(
          of: sorting,
          matching: find.byType(DropdownButtonFormField<String>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(choice.key).last);
      await tester.pumpAndSettle();
      check(choice.value);
    }
    await tester.enterText(find.byType(TextField).first, '가');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('customer-2')), findsOneWidget);
    expect(find.byKey(const Key('customer-1')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final width in [360.0, 1100.0]) {
    testWidgets('고객 상세는 너비 $width, 큰 글자에서도 연락처·결제·반품 기록을 표시한다', (tester) async {
      await showCustomers(tester, Size(width, 1000));
      final customer = find.byKey(const Key('customer-2'));
      await tester.ensureVisible(customer);
      await tester.tap(customer);
      await tester.pumpAndSettle();
      expect(find.text('고객 ID #2'), findsOneWidget);
      expect(find.text('연락처 미등록'), findsOneWidget);
      expect(find.text('결제 금액 12,345원'), findsOneWidget);
      expect(find.text('수령 완료'), findsOneWidget);
      expect(find.text('반품 접수'), findsOneWidget);
      expect(find.text('사이즈가 맞지 않습니다.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
