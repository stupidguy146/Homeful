import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// ============================================================
/// REUSABLE COMPONENTS — ใช้ซ้ำได้ทุกหน้า
/// ============================================================

/// การ์ดพื้นฐาน: พื้นหลัง surface + เงานุ่ม + มุมโค้ง
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
    final r = radius ?? AppRadius.rLg;
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
            border: Border.all(color: borderColor, width: 1),
            boxShadow: AppShadows.sm,
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
  final Gradient gradient;
  final EdgeInsetsGeometry padding;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.stats = const [],
    this.gradient = AppGradients.brand,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: AppShadows.brandGlow(AppColors.brand600),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: subtitle == null ? 48 : 68,
              child: Stack(
                alignment: Alignment.center,
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (subtitle != null) ...[
                          Text(
                            subtitle!,
                            style: AppType.label.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        Text(
                          title,
                          style: AppType.headlineMedium
                              .copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
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
    final fg = onGradient ? Colors.white : AppColors.neutral900;
    final mutedFg = onGradient
        ? Colors.white.withValues(alpha: 0.8)
        : AppColors.neutral500;
    final bg = onGradient
        ? Colors.white.withValues(alpha: 0.18)
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

  const AppPill({super.key, required this.text, required this.color, this.icon});

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
            style: AppType.caption.copyWith(
                color: color, fontWeight: FontWeight.w700),
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
                color: AppColors.brand500.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.brand500),
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

/// Status chip ตาม homeful — pill สี tint ตาม 4 สถานะ (ปกติ/ใกล้หมด/ควรซื้อ/หมดแล้ว)
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
    final fg = AppStatus.fg(status);
    final bg = AppStatus.bg(status);
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

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
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
