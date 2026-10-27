import 'package:flutter/material.dart';
import '../i18n/app_strings.dart';
import '../i18n/locale_scope.dart';
import '../theme/app_tokens.dart';
import '../validators/password_policy.dart';

/// A segmented strength bar + colored label reflecting [PasswordPolicy.strength].
class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  const PasswordStrengthMeter({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final strength = PasswordPolicy.strength(password);
    final level = PasswordStrength.values.indexOf(strength); // 0..3

    final color = switch (strength) {
      PasswordStrength.weak => AppColors.danger,
      PasswordStrength.fair => AppColors.warning,
      PasswordStrength.good => AppColors.accent600,
      PasswordStrength.strong => AppColors.success,
    };
    final label = switch (strength) {
      PasswordStrength.weak => s.strengthWeak,
      PasswordStrength.fair => s.strengthFair,
      PasswordStrength.good => s.strengthGood,
      PasswordStrength.strong => s.strengthStrong,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  height: 6,
                  decoration: BoxDecoration(
                    color: password.isEmpty
                        ? AppColors.neutral200
                        : (i <= level ? color : AppColors.neutral200),
                    borderRadius: AppRadius.rSm,
                  ),
                ),
              ),
              if (i < 3) const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
        if (password.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.passwordStrength,
                  style: AppType.caption
                      .copyWith(color: AppColors.neutral500)),
              Text(label,
                  style: AppType.caption
                      .copyWith(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ],
    );
  }
}

/// A checklist of password requirements, each ticking green as satisfied.
class PasswordRulesChecklist extends StatelessWidget {
  final String password;
  const PasswordRulesChecklist({super.key, required this.password});

  String _labelFor(AppStrings s, String id) {
    switch (id) {
      case 'minLength':
        return s.ruleMinLength;
      case 'uppercase':
        return s.ruleUppercase;
      case 'lowercase':
        return s.ruleLowercase;
      case 'digit':
        return s.ruleDigit;
      case 'special':
        return s.ruleSpecial;
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final satisfied = PasswordPolicy.satisfiedRules(password);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.passwordRequirements,
            style: AppType.label.copyWith(color: AppColors.neutral600)),
        const SizedBox(height: AppSpacing.xs),
        for (final rule in PasswordPolicy.rules)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  satisfied.contains(rule.id)
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 18,
                  color: satisfied.contains(rule.id)
                      ? AppColors.success
                      : AppColors.neutral400,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _labelFor(s, rule.id),
                    style: AppType.bodyMedium.copyWith(
                      color: satisfied.contains(rule.id)
                          ? AppColors.neutral700
                          : AppColors.neutral500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
