/// Central app configuration.
class AppConfig {
  /// Base URL of the API Gateway.
  /// - Android emulator: use http://10.0.2.2:3000
  /// - iOS simulator / web / desktop: use http://localhost:3000
  static const String gatewayBaseUrl = String.fromEnvironment(
    'GATEWAY_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String catalogPrefix = '/api/catalog';
  static const String analyticsPrefix = '/api/analytics';
  static const String customerPrefix = '/api/customer';
  static const String authPrefix = '/api/auth';
}
