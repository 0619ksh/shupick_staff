import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shupick_staff/firebase_options.dart';

class StaffRoleAssignment {
  const StaffRoleAssignment({required this.code, required this.name});

  final String code;
  final String name;

  factory StaffRoleAssignment.fromJson(Map<String, dynamic> json) =>
      StaffRoleAssignment(
        code: json['roleCode'] as String,
        name: json['roleName'] as String,
      );
}

class StaffBranch {
  const StaffBranch({
    required this.id,
    required this.code,
    required this.name,
    required this.districtCode,
  });

  final int id;
  final String code;
  final String name;
  final String districtCode;

  factory StaffBranch.fromJson(Map<String, dynamic> json) => StaffBranch(
    id: json['branchId'] as int,
    code: json['branchCode'] as String,
    name: json['branchName'] as String,
    districtCode: json['districtCode'] as String,
  );
}

class StaffProfile {
  const StaffProfile({
    required this.id,
    required this.code,
    required this.name,
    required this.roles,
    required this.branches,
  });

  final int id;
  final String code;
  final String name;
  final List<StaffRoleAssignment> roles;
  final List<StaffBranch> branches;

  factory StaffProfile.fromJson(Map<String, dynamic> json) => StaffProfile(
    id: json['employeeId'] as int,
    code: json['employeeCode'] as String,
    name: json['employeeName'] as String,
    roles: (json['roles'] as List<dynamic>)
        .map(
          (role) => StaffRoleAssignment.fromJson(role as Map<String, dynamic>),
        )
        .toList(),
    branches: (json['branches'] as List<dynamic>)
        .map((branch) => StaffBranch.fromJson(branch as Map<String, dynamic>))
        .toList(),
  );
}

class StaffAuthException implements Exception {
  const StaffAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class StaffAuthRepository {
  Future<StaffProfile?> restoreSession();
  Future<StaffProfile> signIn(String email, String password);
  Future<void> signOut();
}

class FirebaseStaffAuthRepository implements StaffAuthRepository {
  FirebaseStaffAuthRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static String get _apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override.replaceFirst(RegExp(r'/$'), '');
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on UnsupportedError {
      throw const StaffAuthException('이 플랫폼의 Firebase 앱 설정이 없습니다.');
    } on FirebaseException {
      throw const StaffAuthException('Firebase 앱을 초기화하지 못했습니다. 앱 설정을 확인해주세요.');
    }
  }

  Future<StaffProfile> _fetchProfile(User user) async {
    Future<http.Response> request(String token) => _client
        .get(
          Uri.parse('$_apiBaseUrl/auth/employee/me'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 12));

    try {
      var response = await request((await user.getIdToken())!);
      if (response.statusCode == 401) {
        response = await request((await user.getIdToken(true))!);
      }
      if (response.statusCode == 403 || response.statusCode == 404) {
        throw const StaffAuthException('등록된 직원 계정 또는 활성 직책을 찾지 못했습니다.');
      }
      if (response.statusCode != 200) {
        throw StaffAuthException('직원 정보를 불러오지 못했습니다. (${response.statusCode})');
      }
      return StaffProfile.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } on StaffAuthException {
      rethrow;
    } on FormatException {
      throw const StaffAuthException('직원 정보 응답 형식이 올바르지 않습니다.');
    } catch (_) {
      throw const StaffAuthException('서버에 연결할 수 없습니다. 네트워크와 API 주소를 확인해주세요.');
    }
  }

  @override
  Future<StaffProfile?> restoreSession() async {
    await _initializeFirebase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      return await _fetchProfile(user);
    } on StaffAuthException catch (error) {
      if (error.message.contains('등록된 직원 계정')) {
        await FirebaseAuth.instance.signOut();
      }
      rethrow;
    }
  }

  @override
  Future<StaffProfile> signIn(String email, String password) async {
    await _initializeFirebase();
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const StaffAuthException('로그인 정보를 확인하지 못했습니다.');
      try {
        return await _fetchProfile(user);
      } on StaffAuthException {
        await FirebaseAuth.instance.signOut();
        rethrow;
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'invalid-email') {
        throw const StaffAuthException('올바른 이메일 주소를 입력해주세요.');
      }
      throw const StaffAuthException('이메일 또는 비밀번호를 확인해주세요.');
    }
  }

  @override
  Future<void> signOut() async {
    if (Firebase.apps.isNotEmpty) await FirebaseAuth.instance.signOut();
  }
}
