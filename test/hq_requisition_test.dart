import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shupick_staff/dashboard/staff_pages.dart';
import 'package:shupick_staff/dashboard/staff_views.dart';
import 'package:shupick_staff/dashboard/staff_work_api.dart';

class HeadquartersApi extends StaffWorkApi {
  Map<String, dynamic>? created;
  int? submitted;
  @override
  Future<Map<String, dynamic>> inventory({
    int? branchId,
    DateTime? asOf,
  }) async => {
    'rows': [
      {
        'product_variant_id': 5,
        'product_name': '운동화',
        'color_name': 'BLACK',
        'size_mm': 260,
        'quantity': 1,
        'target_quantity': 20,
      },
    ],
  };
  @override
  Future<List<Map<String, dynamic>>> requisitions() async => [];
  @override
  Future<List<Map<String, dynamic>>> branches() async =>
      throw StateError('품의 작성은 지점 API를 호출하면 안 됩니다.');
  @override
  Future<Map<String, dynamic>> createRequisition({
    required int productVariantId,
    required int quantity,
    required String title,
    required String reason,
  }) async {
    created = {
      'productVariantId': productVariantId,
      'quantity': quantity,
      'title': title,
      'reason': reason,
    };
    return {'purchaseRequisitionId': 70};
  }

  @override
  Future<void> submitRequisition(int id) async {
    submitted = id;
  }
}

void main() {
  testWidgets('대리점 없이 제품·수량·제목·사유만 입력해 품의를 상신한다', (tester) async {
    final api = HeadquartersApi();
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StaffPage(
              view: StaffView.requests,
              roleKey: 'hqStaff',
              isBranch: false,
              workApi: api,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('관련 대리점'), findsNothing);
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('운동화 · BLACK / 260').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '10');
    await tester.enterText(find.byType(TextField).at(1), '본사 재고 보충');
    await tester.enterText(find.byType(TextField).at(2), '운동화 재고 부족');
    final submit = find.text('품의 상신');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(api.created, {
      'productVariantId': 5,
      'quantity': 10,
      'title': '본사 재고 보충',
      'reason': '운동화 재고 부족',
    });
    expect(api.submitted, 70);
    expect(find.text('구매 품의를 상신했습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
