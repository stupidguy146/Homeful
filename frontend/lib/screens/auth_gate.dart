import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import 'login_screen.dart';
import 'main_shell.dart';

/// Decides which screen to show based on auth state. Rebuilds automatically
/// when [AuthService] notifies (login/logout/refresh).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    if (auth.initializing) {
      return const Scaffold(body: LoadingView());
    }
    return auth.isAuthenticated ? const MainShell() : const LoginScreen();
  }
}
