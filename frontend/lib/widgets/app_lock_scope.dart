import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';

/// Shares a single [AppLockService] down the widget tree.
class AppLockScope extends InheritedWidget {
  final AppLockService lock;
  const AppLockScope({super.key, required this.lock, required super.child});

  static AppLockService of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLockScope>();
    assert(scope != null, 'AppLockScope not found in widget tree');
    return scope!.lock;
  }

  static AppLockService read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppLockScope>();
    assert(scope != null, 'AppLockScope not found in widget tree');
    return scope!.lock;
  }

  @override
  bool updateShouldNotify(AppLockScope oldWidget) => lock != oldWidget.lock;
}
