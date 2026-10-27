/// Authenticated identity (mirrors gateway /api/auth responses).
/// Profile fields (username, first/last name) live in CustomerProfile.
class AuthUser {
  final String ssoId;
  final String email;
  final bool emailVerified;

  AuthUser({
    required this.ssoId,
    required this.email,
    this.emailVerified = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      ssoId: (json['ssoId'] ?? json['id'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      emailVerified: (json['emailVerified'] ?? false) as bool,
    );
  }
}

/// Token pair returned by login/register/refresh.
class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}
