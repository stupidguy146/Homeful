import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expiring_item.dart';
import '../models/customer_profile.dart';
import '../services/api_service.dart';
import '../services/customer_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';
import '../i18n/locale_scope.dart';
import 'add_edit_item_screen.dart';
import 'item_detail_screen.dart';

/// homeful home dashboard built from household items + analytics.
class HomeScreen extends StatefulWidget {
  final VoidCallback? onSeeAllItems;
  const HomeScreen({super.key, this.onSeeAllItems});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ApiService? _api;
  CustomerService? _customer;
  Future<_HomeData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api == null) {
      final auth = AuthScope.of(context);
      _api = ApiService(auth: auth);
      _customer = CustomerService(auth: auth);
      _future = _load();
    }
    // re-fetch when global data changes (create/update/delete/profile)
    final rev = DataScope.watch(context);
    if (rev != _rev) {
      _rev = rev;
      if (_api != null) _future = _load();
    }
  }

  int _rev = 0;

  Future<_HomeData> _load() async {
    final summary = await _api!.getSummary();
    final expiring = await _api!.getExpiringSoon(days: 30);
    CustomerProfile? profile;
    try {
      profile = await _customer!.getMyProfile();
    } catch (_) {
      profile = null;
    }
    return _HomeData(
        total: summary.grandTotal,
        totalItems: summary.totalItems,
        expiring: expiring,
        profile: profile);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final baht = NumberFormat.currency(
        locale: context.locale.lang, symbol: '฿', decimalDigits: 0);
    final df = DateFormat('d MMM yyyy', context.locale.lang);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<_HomeData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SkeletonList();
            }
            if (snap.hasError) {
              return ErrorView(error: snap.error!, onRetry: _reload);
            }
            final data = snap.data!;
            final attention = [...data.expiring]..sort((a, b) =>
                (a.daysUntilExpiry ?? 9999).compareTo(b.daysUntilExpiry ?? 9999));
            final name = data.profile?.firstName ?? '';

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _GreetingHeader(
                  greeting: s.greeting(name),
                  question: s.homeQuestion,
                ),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.inventory_2_rounded,
                            value: '${data.totalItems}',
                            label: s.statAllItems,
                            unit: s.statItemsUnit,
                            color: AppColors.brand500,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.error_outline_rounded,
                            value: '${attention.length}',
                            label: s.statLowItems,
                            unit: s.statItemsUnit,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                  child: SectionHeader(
                    title: s.toManage,
                    action: widget.onSeeAllItems == null
                        ? null
                        : TextButton(
                            onPressed: widget.onSeeAllItems,
                            child: Text(s.seeAll),
                          ),
                  ),
                ),
                if (attention.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              color: AppColors.success),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Text(s.nothingToManage)),
                        ],
                      ),
                    ),
                  )
                else
                  ...attention.take(5).map((it) => Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0,
                            AppSpacing.lg, AppSpacing.md),
                        child: _AttentionCard(item: it, df: df),
                      )),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _BudgetCard(spent: data.total, baht: baht),
                ),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
          );
          if (created == true) _reload();
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addProduct),
      ),
    );
  }
}

class _HomeData {
  final double total;
  final int totalItems;
  final List<ExpiringItem> expiring;
  final CustomerProfile? profile;
  _HomeData(
      {required this.total,
      required this.totalItems,
      required this.expiring,
      this.profile});
}

class _GreetingHeader extends StatelessWidget {
  final String greeting;
  final String question;
  const _GreetingHeader({
    required this.greeting,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
      decoration: const BoxDecoration(
        gradient: AppGradients.brand,
          borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(AppRadius.xxl)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/logos/1a97f22c-dd06-498b-83b7-f4da51fc5f24.png',
              width: 64,
              height: 64,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(greeting,
                style: AppType.titleMedium
                    .copyWith(color: Colors.white.withValues(alpha: 0.9))),
            const SizedBox(height: AppSpacing.xs),
            Text(question,
                style: AppType.headlineMedium.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String unit;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: AppRadius.rMd,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppType.displayLarge.copyWith(color: color)),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final ExpiringItem item;
  final DateFormat df;
  const _AttentionCard({required this.item, required this.df});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final d = item.daysUntilExpiry;
    final status = AppStatus.fromDays(d);
    final color = AppStatus.fg(status);
    final statusLabel = {
      StockStatus.normal: s.statusNormal,
      StockStatus.low: s.statusLow,
      StockStatus.shouldBuy: s.statusShouldBuy,
      StockStatus.out: s.statusOut,
    }[status]!;

    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ItemDetailScreen(itemId: item.itemId)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppStatus.bg(status),
              borderRadius: AppRadius.rMd,
            ),
            child: Icon(Icons.inventory_2_outlined, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  item.expiryDate != null
                      ? (d != null && d < 0
                          ? s.overdueDays(-d)
                          : s.expireShort(df.format(item.expiryDate!)))
                      : '${item.quantity} ${s.pieces}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          StatusChip(status: status, label: statusLabel),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final double spent;
  final NumberFormat baht;
  const _BudgetCard({required this.spent, required this.baht});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.brand500),
              const SizedBox(width: AppSpacing.sm),
              Text(s.monthlyBudget,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(baht.format(spent),
              style: AppType.headlineMedium.copyWith(color: AppColors.brand600)),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: const LinearProgressIndicator(
              value: 0.65,
              minHeight: 8,
              backgroundColor: AppColors.neutral200,
              valueColor: AlwaysStoppedAnimation(AppColors.brand500),
            ),
          ),
        ],
      ),
    );
  }
}
