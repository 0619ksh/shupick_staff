import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shupick_staff/auth/staff_session.dart';
import 'package:shupick_staff/dashboard/staff_analytics_data.dart';
import 'package:shupick_staff/dashboard/staff_overview.dart';
import 'package:shupick_staff/dashboard/staff_pages.dart';
import 'package:shupick_staff/dashboard/staff_views.dart';
import 'package:shupick_staff/dashboard/staff_work_api.dart';

Map<String, dynamic> analytics() => {
  'quantity': '2',
  'revenue': '12345.0',
  'orderCount': '1',
  'byDay': [
    {'day': '2026-10-06', 'quantity': '2.0'},
  ],
  'byProduct': [
    {'productId': 5, 'productName': '테스트 상품', 'quantity': '2'},
  ],
  'products': [
    {'id': '5', 'name': '테스트 상품'},
  ],
  'branches': [],
};

class StringAnalyticsApi extends StaffWorkApi {
  int? requestedProduct;
  @override
  Future<Map<String, dynamic>> analytics({
    required int days,
    int? productId,
    int? branchId,
  }) async {
    requestedProduct = productId;
    return _data();
  }

  Map<String, dynamic> _data() => globalsAnalytics();
}

Map<String, dynamic> globalsAnalytics() => analytics();

void main() {
  test('집계 문자열과 숫자를 정수로 읽고 잘못된 금액은 오류로 알린다', () {
    final result = normalizeStaffAnalytics(analytics());
    expect(result['revenue'], 12345);
    expect(result['byDay'][0]['quantity'], 2);
    expect(result['products'][0]['id'], 5);
    expect(
      () =>
          normalizeStaffAnalytics({...analytics(), 'revenue': 'not-a-number'}),
      throwsA(isA<StaffAuthException>()),
    );
    final zero = normalizeStaffAnalytics({
      'quantity': '0',
      'revenue': 0,
      'orderCount': '0',
    });
    expect(zero['quantity'], 0);
  });
  test('임원 요약 카드도 문자열 매출을 표시한다', () {
    final result = executiveOverview(analytics(), [], {'rows': []});
    expect(result.metrics[1].value, '₩12,345');
  });
  testWidgets('문자열 수량의 판매 그래프와 상품 필터가 예외 없이 작동한다', (tester) async {
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = StringAnalyticsApi();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StaffPage(
              view: StaffView.analytics,
              roleKey: 'executive',
              isBranch: false,
              workApi: api,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('12345원'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('테스트 상품').last);
    await tester.pumpAndSettle();
    expect(api.requestedProduct, 5);
    expect(tester.takeException(), isNull);
  });
}
