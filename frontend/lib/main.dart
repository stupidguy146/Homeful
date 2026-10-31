import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/auth_gate.dart';
import 'services/app_lock_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'i18n/app_strings.dart';
import 'i18n/locale_controller.dart';
import 'i18n/locale_scope.dart';
import 'i18n/theme_controller.dart';
import 'state/data_refresh.dart';
import 'theme/app_theme.dart';
import 'widgets/app_lock_scope.dart';
import 'widgets/auth_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _preloadStartupArtwork();

  final auth = AuthService();
  final lock = AppLockService();
  final locale = LocaleController();
  final theme = ThemeController();

  runApp(CheckonApp(
    auth: auth,
    lock: lock,
    locale: locale,
    theme: theme,
  ));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeStartup(auth, locale, theme));
    unawaited(_initializeNotifications());
  });
}

Future<void> _preloadStartupArtwork() {
  const provider = AssetImage('assets/images/loading page/image.png');
  final stream = provider.resolve(const ImageConfiguration());
  final completer = Completer<void>();
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (imageInfo, synchronousCall) {
      stream.removeListener(listener);
      completer.complete();
    },
    onError: (Object error, StackTrace? stackTrace) {
      stream.removeListener(listener);
      completer.completeError(error, stackTrace);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

Future<void> _initializeStartup(
  AuthService auth,
  LocaleController locale,
  ThemeController theme,
) async {
  await Future.wait([
    initializeDateFormatting('th'),
    initializeDateFormatting('en'),
    locale.load(),
    theme.load(),
  ]);
  await auth.bootstrap();
}

Future<void> _initializeNotifications() async {
  try {
    await NotificationService.instance.init();
    await NotificationService.instance.requestPermission();
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'notifications',
        context: ErrorDescription('while initializing local notifications'),
      ),
    );
  }
}

class CheckonApp extends StatelessWidget {
  final AuthService auth;
  final AppLockService lock;
  final LocaleController locale;
  final ThemeController theme;
  const CheckonApp({
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
                  title: AppStrings(locale.lang).appTitle,
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
