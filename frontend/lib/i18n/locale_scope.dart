import 'package:flutter/material.dart';
import 'app_strings.dart';
import 'locale_controller.dart';

/// Shares the [LocaleController] down the tree and rebuilds on language change.
class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found');
    return scope!.notifier!;
  }

  static LocaleController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found');
    return scope!.notifier!;
  }
}

/// Convenience accessors: `context.strings.save`, `context.locale.toggle()`.
extension LocaleX on BuildContext {
  AppStrings get strings => AppStrings(LocaleScope.of(this).lang);
  LocaleController get locale => LocaleScope.of(this);
}
