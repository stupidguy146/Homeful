import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/app_lock_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_scope.dart';
import 'widgets/app_lock_scope.dart';
import 'i18n/locale_controller.dart';
import 'i18n/locale_scope.dart';
import 'i18n/theme_controller.dart';
import 'state/data_refresh.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th');
  await initializeDateFormatting('en');

  final auth = AuthService();
  await auth.bootstrap(); // load persisted tokens + profile

  // Local notifications (expiring-item reminders). no-op on web.
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();

  final lock = AppLockService();

  final locale = LocaleController();
  await locale.load(); // saved choice or device default

  final theme = ThemeController();
  await theme.load(); // saved theme mode

  runApp(RoomShoppingApp(
    auth: auth,
    lock: lock,
    locale: locale,
    theme: theme,
  ));
}

class RoomShoppingApp extends StatelessWidget {
  final AuthService auth;
  final AppLockService lock;
  final LocaleController locale;
  final ThemeController theme;
  const RoomShoppingApp({
    super.key,
    required this.auth,
    required this.lock,
    required this.locale,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return DataScope(
      notifier: DataRefreshNotifier(),
      child: ThemeScope(
        controller: theme,
        child: LocaleScope(
          controller: locale,
          child: AppLockScope(
            lock: lock,
            child: AuthScope(
              auth: auth,
              // rebuild MaterialApp when language OR theme changes
              child: AnimatedBuilder(
                animation: Listenable.merge([locale, theme]),
                builder: (context, _) => MaterialApp(
                  title: 'Checkon',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode: theme.mode,
                  locale: Locale(locale.lang),
                  supportedLocales: const [Locale('th'), Locale('en')],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: const AuthGate(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
