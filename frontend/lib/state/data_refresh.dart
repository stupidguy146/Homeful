import 'package:flutter/material.dart';

/// Global "data changed" signal. Any mutation (create/update/delete item,
/// update profile) calls [bump]; screens that show data listen to [revision]
/// and re-fetch when it changes — so every page stays live without manual
/// pull-to-refresh.
class DataRefreshNotifier extends ChangeNotifier {
  int _revision = 0;
  int get revision => _revision;

  void bump() {
    _revision++;
    notifyListeners();
  }
}

/// Shares the [DataRefreshNotifier] down the tree and rebuilds listeners.
class DataScope extends InheritedNotifier<DataRefreshNotifier> {
  const DataScope({
    super.key,
    required DataRefreshNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Subscribe: returns the current revision and rebuilds the caller on bump.
  static int watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DataScope>();
    return scope?.notifier?.revision ?? 0;
  }

  /// Read without subscribing (for calling bump from callbacks).
  static DataRefreshNotifier of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<DataScope>();
    assert(scope != null, 'DataScope not found in widget tree');
    return scope!.notifier!;
  }
}
