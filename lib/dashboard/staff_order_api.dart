import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shupick_staff/auth/staff_session.dart';

class StaffOrder {
  const StaffOrder({
    required this.id,
    required this.number,
    required this.status,
    required this.customerName,
    required this.branchName,
    required this.products,
    this.fulfillmentId,
    this.fulfillmentStatus,
    this.orderedAt,
  });

  final int id;
  final String number;
  final String status;
  final String customerName;
  final String branchName;
  final List<String> products;
  final int? fulfillmentId;
  final String? fulfillmentStatus;
  final DateTime? orderedAt;

  String get productSummary =>
      products.isEmpty ? '상품 정보 없음' : products.join(', ');

  factory StaffOrder.fromJson(Map<String, dynamic> json) => StaffOrder(
    id: json['orderId'] as int,
    number: json['orderNumber'] as String,
    status: json['orderStatus'] as String,
    customerName: json['customerName'] as String,
    branchName: json['branchName'] as String,
    products: (json['products'] as List<dynamic>).cast<String>(),
    fulfillmentId: json['fulfillmentId'] as int?,
    fulfillmentStatus: json['fulfillmentStatus'] as String?,
    orderedAt: json['orderedAt'] == null
        ? null
        : DateTime.tryParse(json['orderedAt'] as String),
  );
}

abstract class StaffOrderRepository {
  Future<List<StaffOrder>> listOrders({int? branchId});
  Future<StaffOrder> verifyPickup(String code);
  Future<void> completePickup(StaffOrder order, String code);
  Future<void> markArrived(int fulfillmentId);
  Future<void> shipFulfillment(int fulfillmentId);
}

class HttpStaffOrderRepository implements StaffOrderRepository {
  HttpStaffOrderRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, String>> _headers({bool json = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const StaffAuthException('직원 로그인이 필요합니다.');
    final token = await user.getIdToken();
    if (token == null) throw const StaffAuthException('로그인 토큰을 가져오지 못했습니다.');
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json; charset=utf-8',
    };
  }

  Future<http.Response> _get(String path) async {
    try {
      return await _client
          .get(
            Uri.parse('${FirebaseStaffAuthRepository.apiBaseUrl}$path'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 12));
    } on StaffAuthException {
      rethrow;
    } catch (_) {
      throw const StaffAuthException('서버에 연결하지 못했습니다.');
    }
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    try {
      return await _client
          .post(
            Uri.parse('${FirebaseStaffAuthRepository.apiBaseUrl}$path'),
            headers: await _headers(json: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
    } on StaffAuthException {
      rethrow;
    } catch (_) {
      throw const StaffAuthException('서버에 연결하지 못했습니다.');
    }
  }

  void _requireSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 401) {
      throw const StaffAuthException('로그인이 만료되었습니다. 다시 로그인해주세요.');
    }
    if (response.statusCode == 403) {
      throw const StaffAuthException('이 지점의 주문을 처리할 권한이 없습니다.');
    }
    if (response.statusCode == 404) {
      throw const StaffAuthException('해당 지점에서 주문을 찾지 못했습니다.');
    }
    if (response.statusCode == 409) {
      throw const StaffAuthException('현재 주문 상태에서는 처리할 수 없습니다. 목록을 새로고침해주세요.');
    }
    throw StaffAuthException('요청을 처리하지 못했습니다. (${response.statusCode})');
  }

  @override
  Future<List<StaffOrder>> listOrders({int? branchId}) async {
    final suffix = branchId == null ? '' : '?branchId=$branchId';
    final response = await _get('/staff/orders$suffix');
    _requireSuccess(response);
    return (jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>)
        .map((item) => StaffOrder.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<StaffOrder> verifyPickup(String code) async {
    final response = await _post('/staff/pickups/verify', {
      'paymentCode': code,
    });
    _requireSuccess(response);
    return StaffOrder.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> completePickup(StaffOrder order, String code) async {
    final response = await _post('/orders/${order.id}/pickup/complete', {
      'paymentCode': code,
    });
    _requireSuccess(response);
  }

  @override
  Future<void> markArrived(int fulfillmentId) async {
    final response = await _post('/fulfillments/$fulfillmentId/arrive', {});
    _requireSuccess(response);
  }

  @override
  Future<void> shipFulfillment(int fulfillmentId) async {
    final response = await _post('/fulfillments/$fulfillmentId/ship', {});
    _requireSuccess(response);
  }
}
