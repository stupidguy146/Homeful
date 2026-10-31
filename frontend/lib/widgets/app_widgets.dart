import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../theme/app_tokens.dart';

/// ============================================================
/// REUSABLE COMPONENTS — ใช้ซ้ำได้ทุกหน้า
/// ============================================================

/// Shared surface card with a soft brand-tinted border and atmospheric shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius? radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? BorderRadius.circular(AppRadius.card);
    final bg = color ?? Theme.of(context).cardTheme.color;
    final borderColor = Theme.of(context).dividerColor;
    return Material(
      color: bg,
      borderRadius: r,
      child: InkWell(
        onTap: onTap,
        borderRadius: r,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: r,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? borderColor
                  : AppBorders.subtle,
              width: AppBorders.defaultWidth,
            ),
            boxShadow: AppShadows.card,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// หัวข้อ gradient ขนาดใหญ่ (hero header) ใช้ด้านบนของหน้า
class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> stats;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;

  /// Optional brand logo shown above the title (e.g. on the login/register
  /// entry screens). null hides it.
  final String? logoAsset;
  final Widget? logoWidget;
  final double logoHeight;
  final bool logoBackground;

  /// Force-center the logo + subtitle + title. When null, falls back to the
  /// legacy behaviour (centered only when a [leading] back button exists).
  final bool? centerTitle;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.stats = const [],
    this.gradient,
    this.logoAsset,
    this.logoWidget,
    this.logoHeight = 44,
    this.logoBackground = true,
    this.centerTitle,
    this.padding = const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final centered = centerTitle ?? (leading != null);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerForeground =
        gradient != null || isDark ? Colors.white : AppColors.brand900;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: padding,
      decoration: BoxDecoration(
        gradient:
            gradient ?? (isDark ? AppGradients.brandDark : AppGradients.brand),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: AppShadows.brandGlow(AppColors.oceanBlue),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (logoAsset != null || logoWidget != null) ...[
              Align(
                alignment: centered ? Alignment.center : Alignment.centerLeft,
                child: Container(
                  padding: logoBackground
                      ? const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        )
                      : EdgeInsets.zero,
                  decoration: logoBackground
                      ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadius.rLg,
                          boxShadow: AppShadows.sm,
                        )
                      : null,
                  child: logoWidget ??
                      Image.asset(
                        logoAsset!,
                        height: logoHeight,
                        fit: BoxFit.contain,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            SizedBox(
              width: double.infinity,
              height: subtitle == null ? 48 : 68,
              child: Stack(
                // centre the title on screens that have a back button;
                // left-align it on entry screens (no back button)
                alignment: centered ? Alignment.center : Alignment.centerLeft,
                children: [
                  if (leading != null)
                    Align(alignment: Alignment.centerLeft, child: leading!),
                  if (trailing != null)
                    Align(alignment: Alignment.centerRight, child: trailing!),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: leading != null || trailing != null
                          ? AppSpacing.xxxl + AppSpacing.md
                          : 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: centered
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        if (subtitle != null) ...[
                          Text(
                            subtitle!,
                            style: AppType.label.copyWith(
                              color: headerForeground.withValues(alpha: 0.82),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign:
                                centered ? TextAlign.center : TextAlign.start,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        Text(
                          title,
                          style: AppType.headlineMedium.copyWith(
                            color: headerForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign:
                              centered ? TextAlign.center : TextAlign.start,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (stats.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  for (int i = 0; i < stats.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(child: stats[i]),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ปุ่มไอคอนบน [GradientHeader] (เช่น ปุ่มย้อนกลับ) — พื้นขาวโปร่งแสง
/// ใช้ร่วมกันทุกหน้าเพื่อให้ header หน้าตาเหมือนกันทั้งแอป
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
      child: ClipRRect(
        borderRadius: AppRadius.rMd,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlass.blurSigma,
            sigmaY: AppGlass.blurSigma,
          ),
          child: Material(
            color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.58),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.rMd,
              side: BorderSide(
                color: Colors.white.withValues(
                  alpha: isDark ? 0.62 : AppGlass.borderOpacity,
                ),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.rMd,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Icon(
                  icon,
                  color: isDark ? Colors.white : AppColors.brand800,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// กล่องสถิติเล็ก ๆ (โปร่งแสงบน header หรือทึบบนพื้นขาว)
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool onGradient;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.onGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = onGradient
        ? (isDark ? Colors.white : AppColors.brand900)
        : AppColors.neutral900;
    final mutedFg =
        onGradient ? fg.withValues(alpha: 0.8) : AppColors.neutral500;
    final bg = onGradient
        ? Colors.white.withValues(alpha: isDark ? 0.18 : 0.4)
        : Theme.of(context).cardTheme.color;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.rMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(value,
              style: AppType.titleMedium.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: AppType.caption.copyWith(color: mutedFg)),
        ],
      ),
    );
  }
}

/// ป้าย pill เล็ก (สถานะ / แท็ก)
class AppPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const AppPill(
      {super.key, required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            text,
            style: AppType.caption
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// หัวข้อ section
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// สถานะว่าง (empty state) พร้อมไอคอนวงกลม
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppGradients.card,
                borderRadius: AppRadius.rXl,
                border: Border.all(color: AppBorders.subtle),
                boxShadow: AppShadows.glass,
              ),
              child: Icon(icon, size: 40, color: AppColors.brand600),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(message!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// มุมมอง error ที่ใช้ได้ทุกหน้า
class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'เชื่อมต่อไม่ได้',
      message: '$error',
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('ลองใหม่'),
      ),
    );
  }
}

class StartupLoadingView extends StatelessWidget {
  const StartupLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.asset(
        'assets/images/loading page/image.png',
        key: ValueKey('startup-artwork'),
        fit: BoxFit.cover,
      ),
    );
  }
}

/// loading แบบ center
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2.5),
    );
  }
}

/// Checkon status chip using tinted pills for the four stock states.
class StatusChip extends StatelessWidget {
  final StockStatus status;
  final String label;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.status,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = AppStatus.fg(status, dark: isDark);
    final bg = AppStatus.bg(status, dark: isDark);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppType.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer effect — animated gradient sweep used for skeleton placeholders.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * (_c.value * 2 - 1);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.neutral200,
                AppColors.neutral100,
                AppColors.neutral200,
              ],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(dx),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double dx;
  const _SlideGradient(this.dx);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

/// A single grey rounded placeholder block.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? radius;
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.neutral200,
        borderRadius: radius ?? AppRadius.rSm,
      ),
    );
  }
}

/// Skeleton list of card rows (used while a list is loading).
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardTheme.color;
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: AppRadius.rLg,
            boxShadow: AppShadows.sm,
          ),
          child: const Row(
            children: [
              SkeletonBox(
                  width: 52,
                  height: 52,
                  radius: BorderRadius.all(Radius.circular(12))),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 14),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonBox(width: 90, height: 12),
                  ],
                ),
              ),
              SkeletonBox(
                  width: 48,
                  height: 22,
                  radius: BorderRadius.all(Radius.circular(999))),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// MONTH NAVIGATOR — shared across Items + Budget screens
/// prev / next arrows + a tappable label that opens a month-year picker.
/// `onGradient` switches to white colors for use on a gradient header.
/// ============================================================
class MonthNavigator extends StatelessWidget {
  final DateTime month; // any day in the month
  final ValueChanged<DateTime> onChanged;
  final String locale;
  final String prevTooltip;
  final String nextTooltip;
  final String pickerTitle;

  /// Lowest / highest selectable month. [lastMonth] also disables the "next"
  /// arrow once reached (e.g. the current month).
  final DateTime firstMonth;
  final DateTime lastMonth;

  /// White styling for placement on a gradient header.
  final bool onGradient;

  const MonthNavigator({
    super.key,
    required this.month,
    required this.onChanged,
    required this.locale,
    required this.firstMonth,
    required this.lastMonth,
    required this.prevTooltip,
    required this.nextTooltip,
    required this.pickerTitle,
    this.onGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabledFg = onGradient
        ? Colors.white.withValues(alpha: 0.35)
        : AppColors.neutral300;

    // prev enabled if the previous month is >= firstMonth
    final prev = DateTime(month.year, month.month - 1);
    final canPrev = !prev.isBefore(DateTime(firstMonth.year, firstMonth.month));
    // next enabled if the current selection is before lastMonth
    final canNext = month.year < lastMonth.year ||
        (month.year == lastMonth.year && month.month < lastMonth.month);

    Widget arrow(IconData icon, bool enabled, VoidCallback onTap, String tip) {
      if (onGradient) {
        return IconButton(
          tooltip: tip,
          onPressed: enabled ? onTap : null,
          color: Colors.white,
          disabledColor: disabledFg,
          icon: Icon(icon),
        );
      }
      return IconButton.filledTonal(
        tooltip: tip,
        onPressed: enabled ? onTap : null,
        icon: Icon(icon),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        arrow(
            Icons.chevron_left_rounded,
            canPrev,
            () => onChanged(DateTime(month.year, month.month - 1)),
            prevTooltip),
        Expanded(
          child: _MonthLabelButton(
            label: DateFormat('MMMM yyyy', locale).format(month),
            onGradient: onGradient,
            onTap: () async {
              final picked = await showMonthYearPicker(
                context,
                initial: month,
                firstMonth: firstMonth,
                lastMonth: lastMonth,
                title: pickerTitle,
                locale: locale,
              );
              if (picked != null) onChanged(picked);
            },
          ),
        ),
        arrow(
            Icons.chevron_right_rounded,
            canNext,
            () => onChanged(DateTime(month.year, month.month + 1)),
            nextTooltip),
      ],
    );
  }
}

class _MonthLabelButton extends StatelessWidget {
  final String label;
  final bool onGradient;
  final VoidCallback onTap;
  const _MonthLabelButton(
      {required this.label, required this.onGradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = onGradient ? Colors.white : AppColors.neutral900;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: AppType.titleLarge.copyWith(color: fg),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.arrow_drop_down_rounded, color: fg),
          ],
        ),
      ),
    );
  }
}

/// A month+year picker dialog: a year stepper on top + a 12-month grid.
/// Returns the chosen month (first day) or null if cancelled.
Future<DateTime?> showMonthYearPicker(
  BuildContext context, {
  required DateTime initial,
  required DateTime firstMonth,
  required DateTime lastMonth,
  required String title,
  required String locale,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _MonthYearPickerDialog(
      initial: DateTime(initial.year, initial.month),
      firstMonth: DateTime(firstMonth.year, firstMonth.month),
      lastMonth: DateTime(lastMonth.year, lastMonth.month),
      title: title,
      locale: locale,
    ),
  );
}

class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initial;
  final DateTime firstMonth;
  final DateTime lastMonth;
  final String title;
  final String locale;
  const _MonthYearPickerDialog({
    required this.initial,
    required this.firstMonth,
    required this.lastMonth,
    required this.title,
    required this.locale,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
  }

  bool _enabled(int year, int month) {
    final d = DateTime(year, month);
    final lo = DateTime(widget.firstMonth.year, widget.firstMonth.month);
    final hi = DateTime(widget.lastMonth.year, widget.lastMonth.month);
    return !d.isBefore(lo) && !d.isAfter(hi);
  }

  @override
  Widget build(BuildContext context) {
    final canPrevYear = _year > widget.firstMonth.year;
    final canNextYear = _year < widget.lastMonth.year;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rXl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: AppType.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            // year stepper
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: canPrevYear ? () => setState(() => _year--) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text('$_year', style: AppType.titleLarge),
                IconButton(
                  onPressed: canNextYear ? () => setState(() => _year++) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // 12-month grid (3 cols x 4 rows)
            SizedBox(
              width: 300,
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 2.1,
                children: [
                  for (int m = 1; m <= 12; m++)
                    _MonthCell(
                      label: DateFormat('MMM', widget.locale)
                          .format(DateTime(_year, m)),
                      selected: _year == widget.initial.year &&
                          m == widget.initial.month,
                      enabled: _enabled(_year, m),
                      onTap: () =>
                          Navigator.of(context).pop(DateTime(_year, m)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  const _MonthCell({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = selected
        ? AppColors.brand500
        : (Theme.of(context).cardTheme.color ?? AppColors.neutral100);
    final Color fg = !enabled
        ? AppColors.neutral300
        : (selected ? Colors.white : AppColors.neutral700);
    return Material(
      color: enabled ? bg : AppColors.neutral100,
      borderRadius: AppRadius.rMd,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.rMd,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rMd,
            border: Border.all(
              color: selected ? AppColors.brand500 : AppColors.neutral200,
            ),
          ),
          child: Text(label, style: AppType.titleMedium.copyWith(color: fg)),
        ),
      ),
    );
  }
}
