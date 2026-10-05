import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shupick_staff/auth/staff_session.dart';

class StaffWorkApi {
  StaffWorkApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const StaffAuthException('직원 로그인이 필요합니다.');
    final token = await user.getIdToken();
    if (token == null) throw const StaffAuthException('로그인 토큰을 가져오지 못했습니다.');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
    };
  }

  Future<dynamic> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    try {
      final uri = Uri.parse('${FirebaseStaffAuthRepository.apiBaseUrl}$path');
      final headers = await _headers();
      final response =
          await (method == 'GET'
                  ? _client.get(uri, headers: headers)
                  : _client.post(
                      uri,
                      headers: headers,
                      body: jsonEncode(body ?? {}),
                    ))
              .timeout(const Duration(seconds: 12));
      if (response.statusCode == 401) {
        throw const StaffAuthException('로그인이 만료되었습니다. 다시 로그인해주세요.');
      }
      if (response.statusCode == 403) {
        throw const StaffAuthException('이 업무를 처리할 권한이 없습니다.');
      }
      if (response.statusCode == 404) {
        throw const StaffAuthException('요청한 데이터를 찾지 못했습니다.');
      }
      if (response.statusCode == 409) {
        throw const StaffAuthException('현재 상태에서는 처리할 수 없습니다. 목록을 새로고침해주세요.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StaffAuthException('요청 처리에 실패했습니다. (${response.statusCode})');
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on StaffAuthException {
      rethrow;
    } catch (_) {
      throw const StaffAuthException('서버에 연결하지 못했습니다.');
    }
  }

  Future<Map<String, dynamic>> inventory({
    int? branchId,
    DateTime? asOf,
  }) async {
    final query = <String, String>{
      if (branchId != null) 'branchId': '$branchId',
      if (asOf != null)
        'asOf':
            '${asOf.year}-${asOf.month.toString().padLeft(2, '0')}-${asOf.day.toString().padLeft(2, '0')}',
    };
    final suffix = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    return (await _request('GET', '/staff/inventory$suffix'))
        as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> requisitions() async =>
      (await _request('GET', '/staff/procurement/requisitions')
              as List<dynamic>)
          .cast<Map<String, dynamic>>();

  Future<List<Map<String, dynamic>>> branches() async =>
      (await _request('GET', '/branches/pickup') as List<dynamic>)
          .cast<Map<String, dynamic>>();

  Future<Map<String, dynamic>> createRequisition({
    required int branchId,
    required int productVariantId,
    required int quantity,
    required String title,
    required String reason,
  }) async =>
      (await _request('POST', '/procurement/requisitions', {
            'branchId': branchId,
            'title': title,
            'reason': reason,
            'items': [
              {
                'productVariantId': productVariantId,
                'requestedQuantity': quantity,
              },
            ],
          }))
          as Map<String, dynamic>;

  Future<void> submitRequisition(int id) async {
    await _request('POST', '/procurement/requisitions/$id/submit');
  }

  Future<void> decideRequisition(
    int id,
    String decision,
    String comment,
  ) async {
    await _request('POST', '/procurement/requisitions/$id/decision', {
      'decision': decision,
      'comment': comment,
    });
  }

  Future<List<Map<String, dynamic>>> inquiries() async =>
      (await _request('GET', '/staff/inquiries') as List<dynamic>)
          .cast<Map<String, dynamic>>();

  Future<List<Map<String, dynamic>>> customers() async =>
      (await _request('GET', '/staff/customers') as List<dynamic>)
          .cast<Map<String, dynamic>>();

  Future<Map<String, dynamic>> customerDetail(int id) async =>
      (await _request('GET', '/staff/customers/$id')) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> returns({int? branchId}) async =>
      (await _request(
                'GET',
                '/staff/returns${branchId == null ? '' : '?branchId=$branchId'}',
              )
              as List<dynamic>)
          .cast<Map<String, dynamic>>();

  Future<void> inspectReturn(int id, Map<String, dynamic> details) async {
    await _request('POST', '/returns/$id/inspection', details);
  }

  Future<Map<String, dynamic>> analytics({
    required int days,
    int? branchId,
    int? productId,
  }) async {
    final query = Uri(
      queryParameters: {
        'days': '$days',
        if (branchId != null) 'branchId': '$branchId',
        if (productId != null) 'productId': '$productId',
      },
    ).query;
    return (await _request('GET', '/staff/analytics?$query'))
        as Map<String, dynamic>;
  }

  Future<void> answerInquiry(int id, String answer) async {
    await _request('POST', '/inquiries/$id/answer', {'answer': answer});
  }
}
