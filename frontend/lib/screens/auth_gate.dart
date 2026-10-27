import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import '../widgets/app_lock_scope.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'pin_lock_screen.dart';

/// Decides which screen to show based on auth + app-lock state. Rebuilds
/// automatically when [AuthService] notifies (login/logout/refresh).
///
/// Order:
///   not authenticated        → LoginScreen
///   authenticated + has PIN  → PinLockScreen (until unlocked this session)
///   authenticated, unlocked  → MainShell
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthService? _auth;
  bool? _wasAuthenticated;
  bool _checkedLock = false;
  bool _pinRequired = false;
  bool _unlocked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);
    if (!identical(auth, _auth)) {
      _auth?.removeListener(_onAuthChanged);
      _auth = auth;
      _auth!.addListener(_onAuthChanged);
    }
    if (!_checkedLock) {
      _checkedLock = true;
      _wasAuthenticated = auth.isAuthenticated;
      _evaluateLock();
    }
  }

  void _onAuthChanged() {
    final isAuth = _auth?.isAuthenticated ?? false;
    // On any login/logout transition, re-evaluate the local lock so a PIN set
    // (or cleared) by the previous session is reflected for the next one.
    if (isAuth != _wasAuthenticated) {
      _wasAuthenticated = isAuth;
      if (isAuth) {
        _evaluateLock();
      } else {
        // logged out: reset lock gate for the next login
        setState(() {
          _pinRequired = false;
          _unlocked = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> _evaluateLock() async {
    final hasPin = await AppLockScope.read(context).hasPin();
    if (!mounted) return;
    setState(() {
      _pinRequired = hasPin;
      _unlocked = !hasPin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    if (auth.initializing || !_checkedLock) {
      return const Scaffold(body: LoadingView());
    }
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }
    if (_pinRequired && !_unlocked) {
      return PinLockScreen(onUnlocked: () => setState(() => _unlocked = true));
    }
    return const MainShell();
  }
}
