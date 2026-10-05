import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shupick_staff/auth/staff_session.dart';
import 'package:shupick_staff/main.dart';

const branchA = StaffBranch(
  id: 3,
  code: 'SEL-SD',
  name: 'SHOEPICK 성동점',
  districtCode: 'SEOUL-SEONGDONG',
);
const branchB = StaffBranch(
  id: 4,
  code: 'SEL-GN',
  name: 'SHOEPICK 강남점',
  districtCode: 'SEOUL-GANGNAM',
);

const branchProfile = StaffProfile(
  id: 7,
  code: 'EMP-0007',
  name: '테스트 직원',
  roles: [StaffRoleAssignment(code: 'BRANCH_STAFF', name: '대리점 직원')],
  branches: [branchA, branchB],
);

const allRolesProfile = StaffProfile(
  id: 8,
  code: 'EMP-0008',
  name: '전체 화면 검사',
  roles: [
    StaffRoleAssignment(code: 'BRANCH_STAFF', name: '대리점 직원'),
    StaffRoleAssignment(code: 'BRANCH_MANAGER', name: '대리점장'),
    StaffRoleAssignment(code: 'HQ_STAFF', name: '본사 사원'),
    StaffRoleAssignment(code: 'TEAM_LEAD', name: '본사 팀장'),
    StaffRoleAssignment(code: 'DIRECTOR', name: '본사 이사'),
    StaffRoleAssignment(code: 'EXECUTIVE', name: '본사 임원'),
  ],
  branches: [branchA],
);

class FakeStaffAuthRepository implements StaffAuthRepository {
  FakeStaffAuthRepository({this.restored, this.signInResult, this.signInError});

  StaffProfile? restored;
  StaffProfile? signInResult;
  StaffAuthException? signInError;
  int signOutCalls = 0;

  @override
  Future<StaffProfile?> restoreSession() async => restored;

  @override
  Future<StaffProfile> signIn(String email, String password) async {
    if (signInError case final StaffAuthException error) throw error;
    return signInResult!;
  }

  @override
  Future<void> signOut() async => signOutCalls++;
}

void setViewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> pumpSignedIn(
  WidgetTester tester, {
  StaffProfile profile = allRolesProfile,
}) async {
  await tester.pumpWidget(
    MyApp(authRepository: FakeStaffAuthRepository(restored: profile)),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('직원 프로필 응답에서 직책과 소속 지점을 읽는다', () {
    final profile = StaffProfile.fromJson({
      'employeeId': 7,
      'employeeCode': 'EMP-0007',
      'employeeName': '테스트 직원',
      'roles': [
        {'roleCode': 'BRANCH_STAFF', 'roleName': '대리점 직원'},
      ],
      'branches': [
        {
          'branchId': 3,
          'branchCode': 'SEL-SD',
          'branchName': 'SHOEPICK 성동점',
          'districtCode': 'SEOUL-SEONGDONG',
        },
      ],
    });
    expect(profile.name, '테스트 직원');
    expect(profile.roles.single.code, 'BRANCH_STAFF');
    expect(profile.branches.single.name, 'SHOEPICK 성동점');
  });

  testWidgets('로그인 후 서버가 허용한 직책과 지점만 표시한다', (tester) async {
    setViewSize(tester, const Size(1400, 900));
    final auth = FakeStaffAuthRepository(signInResult: branchProfile);
    await tester.pumpWidget(MyApp(authRepository: auth));
    await tester.pumpAndSettle();
    expect(find.text('직원 로그인'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('staff-email')),
      'staff@example.com',
    );
    await tester.enterText(find.byKey(const Key('staff-password')), 'password');
    await tester.tap(find.byKey(const Key('staff-sign-in')));
    await tester.pumpAndSettle();
    expect(find.textContaining('테스트 직원 · 대리점 직원'), findsOneWidget);
    expect(find.text('업무 현황'), findsOneWidget);

    await tester.tap(find.byKey(const Key('role-selector')));
    await tester.pumpAndSettle();
    expect(find.text('본사 사원'), findsNothing);
    await tester.tapAt(const Offset(700, 700));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('branch-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SHOEPICK 강남점').last);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('branch-selector')),
        matching: find.text('SHOEPICK 강남점'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('로그아웃').last);
    await tester.pumpAndSettle();
    expect(auth.signOutCalls, 1);
    expect(find.text('직원 로그인'), findsOneWidget);
  });

  testWidgets('지점 배정이 없는 대리점 직원은 업무 화면에 들어가지 못한다', (tester) async {
    setViewSize(tester, const Size(900, 1200));
    final auth = FakeStaffAuthRepository(
      signInResult: const StaffProfile(
        id: 9,
        code: 'EMP-0009',
        name: '미배정 직원',
        roles: [StaffRoleAssignment(code: 'BRANCH_STAFF', name: '대리점 직원')],
        branches: [],
      ),
    );
    await tester.pumpWidget(MyApp(authRepository: auth));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('staff-email')),
      'staff@example.com',
    );
    await tester.enterText(find.byKey(const Key('staff-password')), 'password');
    await tester.tap(find.byKey(const Key('staff-sign-in')));
    await tester.pumpAndSettle();
    expect(find.textContaining('소속 지점이 없습니다'), findsOneWidget);
    expect(auth.signOutCalls, 1);
  });

  testWidgets('태블릿 세로 화면에서 서버 지점과 메뉴가 표시된다', (tester) async {
    setViewSize(tester, const Size(800, 1280));
    await pumpSignedIn(tester, profile: branchProfile);
    expect(find.byKey(const Key('menu-pickup')), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
    await tester.tap(find.byKey(const Key('menu-pickup')));
    await tester.pumpAndSettle();
    expect(find.text('픽업 결제 코드 확인'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('직책별 업무 메뉴 화면을 열 수 있다', (tester) async {
    setViewSize(tester, const Size(1400, 900));
    await pumpSignedIn(tester);

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
    await open('returns', '반품 진행 현황');
    await open('stockLookup', '현재 지점 보관 상품');
    expect(find.byKey(const Key('menu-exchanges')), findsNothing);
    expect(find.byKey(const Key('menu-communication')), findsNothing);

    await chooseRole('대리점장');
    await open('inventory', '현재 지점 보관 상품');

    await chooseRole('본사 사원');
    await open('orders', '주문 조회');
    await open('customers', '고객 목록');
    await open('shipping', '주문별 배송 단계');
    await open('returns', '본사 반품 검수');
    await open('inventory', '제품별 본사 재고');
    await open('requests', '제조사 구매 품의 작성');

    await chooseRole('본사 팀장');
    await open('approvals', '1차 결재 대기');
    expect(find.byKey(const Key('menu-customers')), findsNothing);

    await chooseRole('본사 이사');
    await open('approvals', '최종 결재 대기');

    await chooseRole('본사 임원');
    await open('analytics', '일자별 판매량');
    await open('approvals', '결재 현황');
  });

  testWidgets('모바일 메뉴에서 픽업 코드 확인 화면을 열 수 있다', (tester) async {
    setViewSize(tester, const Size(390, 844));
    await pumpSignedIn(tester, profile: branchProfile);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-pickup')));
    await tester.pumpAndSettle();
    expect(find.text('픽업 결제 코드 확인'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
