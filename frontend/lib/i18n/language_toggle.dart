import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import 'locale_scope.dart';

/// A small TH/EN pill switcher, usable on any gradient header.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: () => locale.toggle(),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded, color: Colors.white, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                locale.isThai ? 'TH' : 'EN',
                style: AppType.label.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
