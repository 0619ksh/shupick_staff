import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shupick_staff/auth/staff_registration_service.dart';
import 'package:shupick_staff/auth/staff_session.dart';

class RegistrationUser implements User {
  bool refreshed = false;
  bool tokenFailure = false;
  bool profileFailed = false;
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    refreshed = forceRefresh;
    if (tokenFailure) {
      throw FirebaseAuthException(code: 'network-request-failed');
    }
    return 'test-token';
  }

  @override
  Future<void> updateDisplayName(String? name) async {
    profileFailed = true;
    throw FirebaseAuthException(code: 'network-request-failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RegistrationCredential implements UserCredential {
  RegistrationCredential(this.user);
  @override
  final User user;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RegistrationAuth implements FirebaseAuth {
  RegistrationAuth(this.staffUser);
  final RegistrationUser staffUser;
  bool existing = false;
  bool signedIn = false;
  @override
  User? currentUser;
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (existing) throw FirebaseAuthException(code: 'email-already-in-use');
    currentUser = staffUser;
    return RegistrationCredential(staffUser);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signedIn = true;
    currentUser = staffUser;
    return RegistrationCredential(staffUser);
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> register(FirebaseStaffRegistrationRepository repo) =>
    repo.register(
      email: 'staff@example.com',
      password: 'test-only-password',
      name: '중랑구 직원',
      affiliation: 'BRANCH',
      districtCode: 'SEOUL-JUNGNANG',
      roleCode: 'BRANCH_STAFF',
    );

void main() {
  test('Firebase 표시 이름 설정이 실패해도 MySQL 등록은 먼저 완료한다', () async {
    final user = RegistrationUser();
    final auth = RegistrationAuth(user);
    var saved = false;
    final repo = FirebaseStaffRegistrationRepository(
      auth: auth,
      initialize: () async {},
      client: MockClient((request) async {
        expect(user.profileFailed, false);
        expect(jsonDecode(request.body)['districtCode'], 'SEOUL-JUNGNANG');
        saved = true;
        return http.Response('{"status":"ACTIVE","employeeId":7}', 201);
      }),
    );
    await register(repo);
    expect(saved, true);
    expect(user.profileFailed, true);
    expect(user.refreshed, true);
    expect(auth.currentUser, isNull);
  });
  test('Firebase에만 존재하는 동일 계정은 로그인 후 DB 등록을 재시도한다', () async {
    final auth = RegistrationAuth(RegistrationUser())..existing = true;
    var requests = 0;
    final repo = FirebaseStaffRegistrationRepository(
      auth: auth,
      initialize: () async {},
      client: MockClient((_) async {
        requests++;
        return http.Response('{"status":"ACTIVE","employeeId":7}', 201);
      }),
    );
    await register(repo);
    expect(auth.signedIn, true);
    expect(requests, 1);
  });
  test('토큰 발급 오류의 단계와 코드를 표시하고 DB 요청은 보내지 않는다', () async {
    final user = RegistrationUser()..tokenFailure = true;
    final repo = FirebaseStaffRegistrationRepository(
      auth: RegistrationAuth(user),
      initialize: () async {},
      client: MockClient(
        (_) async => throw StateError('Token failure must not reach MySQL API'),
      ),
    );
    await expectLater(
      register(repo),
      throwsA(
        isA<StaffAuthException>().having(
          (e) => e.message,
          'message',
          allOf(contains('인증 토큰 발급'), contains('network-request-failed')),
        ),
      ),
    );
  });
  test('서버 인증 오류를 Firebase 계정 생성 실패로 잘못 표시하지 않는다', () async {
    final repo = FirebaseStaffRegistrationRepository(
      auth: RegistrationAuth(RegistrationUser()),
      initialize: () async {},
      client: MockClient(
        (_) async => http.Response('{"detail":"Invalid token"}', 401),
      ),
    );
    await expectLater(
      register(repo),
      throwsA(
        isA<StaffAuthException>().having(
          (e) => e.message,
          'message',
          contains('(401)'),
        ),
      ),
    );
  });
}
