import 'package:flutter/material.dart';
import '../screens/notification_screen.dart';
import '../theme/app_tokens.dart';

/// Bell icon for the gradient header's top-right corner. Shows a small red
/// badge with [count] when there are items expiring soon, and opens the
/// in-app [NotificationScreen] on tap.
class NotificationBell extends StatelessWidget {
  /// Number of items expiring soon (drives the badge). 0 hides the badge.
  final int count;

  /// Called after returning from the notifications screen so the caller can
  /// refresh its data/badge.
  final VoidCallback? onReturn;

  const NotificationBell({super.key, this.count = 0, this.onReturn});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : AppColors.brand800;
    return Material(
      color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.62),
      borderRadius: AppRadius.rMd,
      child: InkWell(
        borderRadius: AppRadius.rMd,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          );
          onReturn?.call();
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_rounded, color: foreground, size: 22),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
