import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Severity of an action result, driving the snackbar color + icon.
enum SnackKind { success, error, info }

/// Centralized, color-coded snackbars so every action across the app gives
/// consistent feedback: green = success, red = failure, blue = info.
///
/// Usage:
///   AppSnackBar.success(context, s.itemSaved);
///   AppSnackBar.error(context, message);
class AppSnackBar {
  AppSnackBar._();

  static void success(BuildContext context, String message) =>
      _show(context, message, SnackKind.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, SnackKind.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, SnackKind.info);

  /// Show using a pre-captured messenger (safe to call after an await when the
  /// original context may be gone). Pass [ScaffoldMessenger.of(context)].
  static void show(
    ScaffoldMessengerState messenger,
    String message,
    SnackKind kind,
  ) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(_build(message, kind));
  }

  static void _show(BuildContext context, String message, SnackKind kind) {
    show(ScaffoldMessenger.of(context), message, kind);
  }

  static SnackBar _build(String message, SnackKind kind) {
    final (bg, icon) = switch (kind) {
      SnackKind.success => (AppColors.success, Icons.check_circle_rounded),
      SnackKind.error => (AppColors.danger, Icons.error_rounded),
      SnackKind.info => (AppColors.brand600, Icons.info_rounded),
    };
    return SnackBar(
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppType.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
