import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shupick_staff/auth/staff_session.dart';

abstract class StaffRegistrationRepository {
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String affiliation,
    required String? districtCode,
    required String roleCode,
  });
}

class FirebaseStaffRegistrationRepository
    implements StaffRegistrationRepository {
  FirebaseStaffRegistrationRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String affiliation,
    required String? districtCode,
    required String roleCode,
  }) async {
    await FirebaseStaffAuthRepository.initializeFirebase();
    final firebaseAuth = FirebaseAuth.instance;
    User? user;
    try {
      try {
        final credential = await firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = credential.user;
      } on FirebaseAuthException catch (error) {
        if (error.code != 'email-already-in-use') rethrow;
        // A previous API failure may have left the Firebase account in place.
        // The backend registration endpoint is safe to retry for the same UID.
        final credential = await firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = credential.user;
      }
      if (user == null) {
        throw const StaffAuthException('Firebase 계정을 확인하지 못했습니다.');
      }

      await user.updateDisplayName(name);
      final token = await user.getIdToken();
      if (token == null) {
        throw const StaffAuthException('Firebase 인증 토큰을 가져오지 못했습니다.');
      }
      final response = await _client
          .post(
            Uri.parse(
              '${FirebaseStaffAuthRepository.apiBaseUrl}/auth/employee/register',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode({
              'employeeName': name,
              'affiliation': affiliation,
              'districtCode': districtCode,
              'roleCode': roleCode,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 409) {
        throw const StaffAuthException('이미 등록된 직원 계정이거나 다른 계정에 연결된 이메일입니다.');
      }
      if (response.statusCode == 422) {
        throw const StaffAuthException('선택한 지점 또는 직책을 확인해주세요.');
      }
      if (response.statusCode == 404) {
        throw const StaffAuthException(
          '직원 등록 API를 찾지 못했습니다. FastAPI 서버를 최신 코드로 재시작해주세요.',
        );
      }
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw StaffAuthException('직원 정보를 저장하지 못했습니다. (${response.statusCode})');
      }
      if (jsonDecode(response.body)['status'] != 'ACTIVE') {
        throw const StaffAuthException('직원 계정이 활성화되지 않았습니다. 서버 설정을 확인해주세요.');
      }
    } on StaffAuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'weak-password') {
        throw const StaffAuthException('비밀번호가 너무 약합니다. 6자 이상 입력해주세요.');
      }
      if (error.code == 'invalid-email') {
        throw const StaffAuthException('올바른 이메일 주소를 입력해주세요.');
      }
      if (error.code == 'wrong-password' ||
          error.code == 'invalid-credential') {
        throw const StaffAuthException('이미 사용 중인 이메일입니다. 기존 비밀번호를 확인해주세요.');
      }
      throw const StaffAuthException('Firebase 계정 생성에 실패했습니다. 다시 시도해주세요.');
    } catch (_) {
      throw const StaffAuthException(
        '서버에 연결하지 못했습니다. Firebase 계정이 만들어졌다면 같은 정보로 다시 시도해주세요.',
      );
    } finally {
      try {
        if (firebaseAuth.currentUser != null) await firebaseAuth.signOut();
      } on FirebaseAuthException {
        // A sign-out failure must not hide the registration result.
      }
    }
  }
}
