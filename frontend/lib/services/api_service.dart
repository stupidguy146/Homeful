import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/household_item.dart';
import '../models/expiring_item.dart';
import '../models/api_error.dart';
import 'auth_service.dart';

/// Talks to the API Gateway for household items + analytics.
/// Attaches the Bearer access token and retries once after refreshing on 401.
class ApiService {
  final http.Client _client;
  final AuthService? _auth;
  ApiService({http.Client? client, AuthService? auth})
      : _client = client ?? http.Client(),
        _auth = auth;

  Uri _catalog(String path) =>
      Uri.parse('${AppConfig.gatewayBaseUrl}${AppConfig.catalogPrefix}$path');
  Uri _analytics(String path) =>
      Uri.parse('${AppConfig.gatewayBaseUrl}${AppConfig.analyticsPrefix}$path');

  Map<String, String> _headers({bool json = false}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    final token = _auth?.tokens.accessToken;
    if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Future<http.Response> _withAuthRetry(
    Future<http.Response> Function() send,
  ) async {
    var res = await send();
    if (res.statusCode == 401 && _auth != null) {
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

  // ---------- Household items ----------
  Future<List<HouseholdItem>> getItems({String? category}) async {
    final q = category != null ? '?category=$category' : '';
    final res = await _withAuthRetry(
        () => _client.get(_catalog('/items$q'), headers: _headers()));
    _ensureOk(res);
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => HouseholdItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HouseholdItem> getItem(String itemId) async {
    final res = await _withAuthRetry(
        () => _client.get(_catalog('/items/$itemId'), headers: _headers()));
    _ensureOk(res);
    return HouseholdItem.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<HouseholdItem> createItem(Map<String, dynamic> body) async {
    final res = await _withAuthRetry(() => _client.post(
          _catalog('/items'),
          headers: _headers(json: true),
          body: jsonEncode(body),
        ));
    _ensureOk(res);
    return HouseholdItem.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<HouseholdItem> updateItem(
      String itemId, Map<String, dynamic> body) async {
    final res = await _withAuthRetry(() => _client.patch(
          _catalog('/items/$itemId'),
          headers: _headers(json: true),
          body: jsonEncode(body),
        ));
    _ensureOk(res);
    return HouseholdItem.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteItem(String itemId) async {
    final res = await _withAuthRetry(
        () => _client.delete(_catalog('/items/$itemId'), headers: _headers()));
    _ensureOk(res);
  }

  // ---------- Analytics ----------
  Future<AnalyticsSummary> getSummary() async {
    final res = await _withAuthRetry(
        () => _client.get(_analytics('/summary'), headers: _headers()));
    _ensureOk(res);
    return AnalyticsSummary.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<ExpiringItem>> getExpiringSoon({int days = 7}) async {
    final res = await _withAuthRetry(() =>
        _client.get(_analytics('/expiring-soon?days=$days'), headers: _headers()));
    _ensureOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (body['items'] as List?) ?? [];
    return items
        .map((e) => ExpiringItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Analytics summary payload.
class AnalyticsSummary {
  final double grandTotal;
  final int totalItems;
  final List<MonthSpend> months;
  final List<CategorySpend> categories;

  AnalyticsSummary({
    required this.grandTotal,
    required this.totalItems,
    required this.months,
    required this.categories,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      months: ((json['months'] as List?) ?? [])
          .map((e) => MonthSpend(
                month: e['month'] as String,
                amount: (e['amount'] as num).toDouble(),
              ))
          .toList(),
      categories: ((json['categories'] as List?) ?? [])
          .map((e) => CategorySpend(
                category: e['category'] as String,
                amount: (e['amount'] as num).toDouble(),
              ))
          .toList(),
    );
  }
}

class MonthSpend {
  final String month; // yyyy-mm
  final double amount;
  MonthSpend({required this.month, required this.amount});
}

class CategorySpend {
  final String category;
  final double amount;
  CategorySpend({required this.category, required this.amount});
}
