import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shupick_staff/auth/staff_registration_service.dart';
import 'package:shupick_staff/view/staff_registration.dart';

class FakeRegistrationRepository implements StaffRegistrationRepository {
  Map<String, String?>? submitted;

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String affiliation,
    required String? districtCode,
    required String roleCode,
  }) async {
    submitted = {
      'email': email,
      'password': password,
      'name': name,
      'affiliation': affiliation,
      'districtCode': districtCode,
      'roleCode': roleCode,
    };
  }
}

void main() {
  testWidgets('필수 입력을 검증하고 선택한 지점·직책으로 등록을 요청한다', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeRegistrationRepository();
    await tester.pumpWidget(
      MaterialApp(home: StaffRegistrationPage(repository: repository)),
    );

    await tester.ensureVisible(find.byKey(const Key('registration-submit')));
    await tester.tap(find.byKey(const Key('registration-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.submitted, isNull);
    expect(find.text('올바른 이메일을 입력해주세요.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('registration-email')),
      'staff@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('registration-name')),
      '강남 대리점 직원',
    );
    await tester.enterText(
      find.byKey(const Key('registration-password')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('registration-password-confirmation')),
      'password123',
    );

    await tester.tap(
      find.byKey(const Key('registration-affiliation-detail-대리점')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('강남구').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('registration-role-대리점')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대리점 직원').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('registration-submit')));
    await tester.tap(find.byKey(const Key('registration-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.submitted, {
      'email': 'staff@example.com',
      'password': 'password123',
      'name': '강남 대리점 직원',
      'affiliation': 'BRANCH',
      'districtCode': 'SEOUL-GANGNAM',
      'roleCode': 'BRANCH_STAFF',
    });
    expect(find.text('직원 등록 완료'), findsOneWidget);
    expect(find.text('직원 계정이 등록되었습니다. 바로 로그인할 수 있습니다.'), findsOneWidget);
  });

  testWidgets('본사를 선택하면 지점이 비활성화되고 지점 없이 등록한다', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeRegistrationRepository();
    await tester.pumpWidget(
      MaterialApp(home: StaffRegistrationPage(repository: repository)),
    );

    await tester.enterText(
      find.byKey(const Key('registration-email')),
      'hq@example.com',
    );
    await tester.enterText(find.byKey(const Key('registration-name')), '본사 직원');
    await tester.enterText(
      find.byKey(const Key('registration-password')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('registration-password-confirmation')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('registration-affiliation')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('본사').last);
    await tester.pumpAndSettle();

    final branchDropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const Key('registration-affiliation-detail-본사')),
    );
    expect(branchDropdown.onChanged, isNull);
    expect(find.text('본사는 지점 없음'), findsOneWidget);

    await tester.tap(find.byKey(const Key('registration-role-본사')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('본사 사원').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('registration-submit')));
    await tester.tap(find.byKey(const Key('registration-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.submitted?['affiliation'], 'HQ');
    expect(repository.submitted?['districtCode'], isNull);
    expect(repository.submitted?['roleCode'], 'HQ_STAFF');
    expect(find.text('직원 등록 완료'), findsOneWidget);
  });
}
