import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/customer_profile.dart';
import '../models/api_error.dart';
import 'auth_service.dart';

/// Talks to the gateway customer-profile endpoints (/api/customer/me).
/// Attaches the Bearer access token and retries once after refreshing.
class CustomerService {
  final http.Client _client;
  final AuthService _auth;

  CustomerService({required AuthService auth, http.Client? client})
      : _auth = auth,
        _client = client ?? http.Client();

  Uri _url(String path) =>
      Uri.parse('${AppConfig.gatewayBaseUrl}${AppConfig.customerPrefix}$path');

  Map<String, String> _headers({bool json = false}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    final token = _auth.tokens.accessToken;
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<http.Response> _withAuthRetry(
    Future<http.Response> Function() send,
  ) async {
    var res = await send();
    if (res.statusCode == 401) {
      final refreshed = await _auth.tryRefresh();
      if (refreshed) res = await send();
    }
    return res;
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode >= 400) {
      throw ApiError.fromResponse(res.statusCode, res.body);
    }
  }

  Future<CustomerProfile> getMyProfile() async {
    final res =
        await _withAuthRetry(() => _client.get(_url('/me'), headers: _headers()));
    _ensureOk(res);
    return CustomerProfile.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<CustomerProfile> updateMyProfile({
    String? title,
    String? username,
    String? firstName,
    String? lastName,
    Object? avatarBase64 = leaveAvatar,
    Object? status = leaveStatus,
    String? birthDate,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (username != null) 'username': username,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (!identical(avatarBase64, leaveAvatar)) 'avatarBase64': avatarBase64,
      if (!identical(status, leaveStatus)) 'status': status,
      if (birthDate != null) 'birthDate': birthDate,
    };
    final res = await _withAuthRetry(() => _client.patch(
          _url('/me'),
          headers: _headers(json: true),
          body: jsonEncode(body),
        ));
    _ensureOk(res);
    return CustomerProfile.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // sentinels to distinguish "not provided" from explicit null (clear field)
  static const Object leaveAvatar = Object();
  static const Object leaveStatus = Object();
}
