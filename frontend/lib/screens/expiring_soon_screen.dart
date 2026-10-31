import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../i18n/locale_scope.dart';
import '../models/expiring_item.dart';
import '../services/api_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';

class ExpiringSoonScreen extends StatefulWidget {
  const ExpiringSoonScreen({super.key});

  @override
  State<ExpiringSoonScreen> createState() => _ExpiringSoonScreenState();
}

class _ExpiringSoonScreenState extends State<ExpiringSoonScreen> {
  ApiService? _api;
  int _days = 7;
  Future<List<ExpiringItem>>? _future;

  static const _options = [3, 7, 14, 30];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api ??= ApiService(auth: AuthScope.of(context));
    _future ??= _api!.getExpiringSoon(days: _days);
  }

  void _reload() {
    setState(() => _future = _api!.getExpiringSoon(days: _days));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final df = DateFormat('d MMM yyyy', context.locale.lang);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GradientHeader(
                gradient:
                    isDark ? AppGradients.accentDark : AppGradients.accent,
                subtitle: s.notifications,
                title: s.expiringTitle,
                leading: _HeaderIconButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  children: [
                    for (final o in _options) ...[
                      _FilterChip(
                        label: s.withinDays(o),
                        selected: _days == o,
                        onTap: () {
                          _days = o;
                          _reload();
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
            ),
            FutureBuilder<List<ExpiringItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                      hasScrollBody: false, child: LoadingView());
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(error: snapshot.error!, onRetry: _reload),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: s.noExpiring,
                      message: s.noExpiringHint(_days),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) =>
                        _ExpiringCard(item: items[i], df: df),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiringCard extends StatelessWidget {
  final ExpiringItem item;
  final DateFormat df;

  const _ExpiringCard({required this.item, required this.df});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final d = item.daysUntilExpiry;
    final status = AppStatus.fromDays(d);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppStatus.fg(status, dark: isDark);
    final overdue = status == StockStatus.out;
    final statusLabel = {
      StockStatus.normal: s.statusNormal,
      StockStatus.low: s.statusLow,
      StockStatus.shouldBuy: s.statusShouldBuy,
      StockStatus.out: s.statusOut,
    }[status]!;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppStatus.bg(status, dark: isDark),
              borderRadius: AppRadius.rMd,
            ),
            child: Icon(
              overdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.expiryDate != null
                      ? context.strings.expiryWithQty(
                          df.format(item.expiryDate!), item.quantity)
                      : context.strings.noExpiryWithQty(item.quantity),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusChip(status: status, label: statusLabel),
              const SizedBox(height: AppSpacing.xs),
              Text(
                d == null
                    ? '-'
                    : overdue
                        ? s.overdueDays(-d)
                        : s.daysLeft(d),
                style: AppType.caption.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brand500 : Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: selected ? null : AppShadows.sm,
          ),
          child: Text(
            label,
            style: AppType.label.copyWith(
              color: selected ? Colors.white : AppColors.neutral600,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: AppRadius.rMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
