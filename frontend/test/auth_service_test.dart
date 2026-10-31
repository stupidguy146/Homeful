import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkon/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('logout clears persisted access and refresh tokens', () async {
    final auth = AuthService();
    await auth.tokens.save(accessToken: 'access', refreshToken: 'refresh');

    await auth.logout();

    final preferences = await SharedPreferences.getInstance();
    expect(auth.isAuthenticated, isFalse);
    expect(preferences.getString('auth_access_token'), isNull);
    expect(preferences.getString('auth_refresh_token'), isNull);
  });

  test('bootstrap does not wait for remote session validation', () async {
    SharedPreferences.setMockInitialValues({
      'auth_access_token': 'access',
      'auth_refresh_token': 'refresh',
    });
    final response = Completer<http.Response>();
    final requestStarted = Completer<void>();
    final auth = AuthService(
      client: MockClient((_) {
        requestStarted.complete();
        return response.future;
      }),
    );
    final userLoaded = Completer<void>();
    void onAuthChanged() {
      if (auth.user != null && !userLoaded.isCompleted) userLoaded.complete();
    }

    auth.addListener(onAuthChanged);
    await auth.bootstrap().timeout(const Duration(seconds: 1));

    expect(auth.initializing, isFalse);
    expect(auth.isAuthenticated, isTrue);
    await requestStarted.future.timeout(const Duration(seconds: 1));

    response.complete(http.Response(
      jsonEncode({
        'ssoId': 'user-id',
        'email': 'user@example.com',
        'emailVerified': true,
      }),
      200,
    ));
    await userLoaded.future.timeout(const Duration(seconds: 1));
    auth.removeListener(onAuthChanged);

    expect(auth.user?.emailVerified, isTrue);
  });
}
