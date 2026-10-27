import 'package:flutter_test/flutter_test.dart';
import 'package:room_shopping_app/services/auth_service.dart';
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
}