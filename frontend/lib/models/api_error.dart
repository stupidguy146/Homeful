import 'dart:convert';

/// Error returned by the API gateway, following the contract
/// { domain, code, message }. `message` is a developer-facing fallback;
/// the UI localizes using `code` via AppStrings.errorForCode().
class ApiError implements Exception {
  final String? domain;
  final String? code;
  final String message; // backend fallback (English)
  final int statusCode;

  ApiError({
    required this.statusCode,
    this.domain,
    this.code,
    this.message = '',
  });

  /// Parse an HTTP error response body into an ApiError.
  factory ApiError.fromResponse(int statusCode, String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        return ApiError(
          statusCode: statusCode,
          domain: json['domain'] as String?,
          code: json['code'] as String?,
          message: (json['message'] ?? '').toString(),
        );
      }
    } catch (_) {
      // non-JSON body → keep raw text as message
    }
    return ApiError(statusCode: statusCode, message: body);
  }

  @override
  String toString() => 'ApiError($statusCode, $domain/$code): $message';
}
