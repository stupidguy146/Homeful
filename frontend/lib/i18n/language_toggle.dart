import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import 'locale_scope.dart';

/// A small TH/EN pill switcher. On a gradient header use the default
/// ([onGradient] = true, white translucent). On a light surface pass
/// [onGradient] = false for a brand-tinted pill that stays readable.
class LanguageToggle extends StatelessWidget {
  final bool onGradient;
  const LanguageToggle({super.key, this.onGradient = true});

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final fg = onGradient ? Colors.white : AppColors.brand600;
    final bg = onGradient
        ? Colors.white.withValues(alpha: 0.18)
        : AppColors.brand500.withValues(alpha: 0.10);
    return Material(
      color: bg,
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
              Icon(Icons.language_rounded, color: fg, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                locale.isThai ? 'TH' : 'EN',
                style: AppType.label.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
