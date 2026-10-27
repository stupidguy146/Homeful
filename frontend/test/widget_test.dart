// Basic widget smoke test for RoomShoppingApp.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:room_shopping_app/main.dart';
import 'package:room_shopping_app/services/auth_service.dart';
import 'package:room_shopping_app/services/app_lock_service.dart';
import 'package:room_shopping_app/i18n/locale_controller.dart';
import 'package:room_shopping_app/i18n/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Unauthenticated app shows the login screen',
      (WidgetTester tester) async {
    final auth = AuthService();
    await auth.bootstrap();
    final lock = AppLockService();
    final locale = LocaleController();
    await locale.load();
    final theme = ThemeController();
    await theme.load();

    await tester.pumpWidget(
      RoomShoppingApp(auth: auth, lock: lock, locale: locale, theme: theme),
    );
    await tester.pumpAndSettle();

    final thai = find.text('ยินดีต้อนรับกลับ');
    final english = find.text('Welcome back');
    expect(thai.evaluate().isNotEmpty || english.evaluate().isNotEmpty, isTrue);
  });
}
