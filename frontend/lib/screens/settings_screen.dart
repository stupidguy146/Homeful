import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../i18n/locale_scope.dart';
import '../i18n/theme_controller.dart';

/// Settings: language (TH/EN) + theme (light / dark / system).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final locale = context.locale;
    final theme = context.theme;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(
            title: s.settings,
            leading: Material(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: AppRadius.rMd,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: AppRadius.rMd,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.rMd,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.65)),
                  ),
                  child: Tooltip(
                    message:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    child: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(title: s.language),
                Column(
                  children: [
                    _OptionRow(
                      flag: '🇹🇭',
                      label: s.thai,
                      selected: locale.isThai,
                      onTap: () => locale.setLang('th'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _OptionRow(
                      flag: '🇬🇧',
                      label: s.english,
                      selected: !locale.isThai,
                      onTap: () => locale.setLang('en'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(title: s.appearance),
                Column(
                  children: [
                    _OptionRow(
                      icon: Icons.light_mode_outlined,
                      label: s.themeLight,
                      selected: theme.mode == ThemeMode.light,
                      onTap: () => theme.setMode(ThemeMode.light),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _OptionRow(
                      icon: Icons.dark_mode_outlined,
                      label: s.themeDark,
                      selected: theme.mode == ThemeMode.dark,
                      onTap: () => theme.setMode(ThemeMode.dark),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _OptionRow(
                      icon: Icons.brightness_auto_outlined,
                      label: s.themeSystem,
                      selected: theme.mode == ThemeMode.system,
                      onTap: () => theme.setMode(ThemeMode.system),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData? icon;
  final String? flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OptionRow({
    this.icon,
    this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = selected
        ? AppColors.brand500
        : isDark
            ? AppColors.neutral600
            : AppColors.neutral300;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brand500.withValues(alpha: isDark ? 0.24 : 0.10)
              : theme.cardTheme.color,
          borderRadius: AppRadius.rMd,
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            if (flag != null)
              Text(flag!, style: const TextStyle(fontSize: 24))
            else
              Icon(icon,
                  color: selected ? AppColors.brand500 : AppColors.neutral500,
                  size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label, style: theme.textTheme.titleMedium),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.brand500, size: 22),
          ],
        ),
      ),
    );
  }
}

