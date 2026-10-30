import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expiring_item.dart';
import '../models/customer_profile.dart';
import '../services/api_service.dart';
import '../services/customer_service.dart';
import '../services/notification_service.dart';
import '../services/notification_read_store.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import '../widgets/notification_bell.dart';
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
  final _store = NotificationStore();
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
    // keep OS reminders in sync on every home load (app start / after login /
    // after add-edit-delete via DataScope). no-op on web.
    if (mounted) {
      await NotificationService.instance
          .syncExpiring(expiring, context.strings);
    }
    CustomerProfile? profile;
    try {
      profile = await _customer!.getMyProfile();
    } catch (_) {
      profile = null;
    }
    // bell badge = expiring within threshold AND not yet read (local).
    // reuse the same event store the notifications screen uses, so retention
    // (7 days) and read-state stay consistent.
    final expiringIds = expiring
        .where((it) =>
            (it.daysUntilExpiry ?? 9999) <=
            NotificationService.thresholdDays)
        .map((it) => it.itemId)
        .toSet();
    final events = await _store.sync(expiringIds);
    final unread = events.where((e) => !e.read).length;
    return _HomeData(
        total: summary.grandTotal,
        totalItems: summary.totalItems,
        expiring: expiring,
        unreadCount: unread,
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
                  expiringCount: data.unreadCount,
                  onBellReturn: _reload,
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
        heroTag: 'fab_home',
        onPressed: () async {
          final created = await showAddItemFlow(context);
          if (created) _reload();
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
  final int unreadCount;
  final CustomerProfile? profile;
  _HomeData(
      {required this.total,
      required this.totalItems,
      required this.expiring,
      this.unreadCount = 0,
      this.profile});
}

class _GreetingHeader extends StatelessWidget {
  final String greeting;
  final String question;
  final int expiringCount;
  final VoidCallback? onBellReturn;
  const _GreetingHeader({
    required this.greeting,
    required this.question,
    this.expiringCount = 0,
    this.onBellReturn,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.rLg,
                    boxShadow: AppShadows.sm,
                  ),
                  child: Image.asset(
                    'assets/images/logos/checkon_logo.png',
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                NotificationBell(
                  count: expiringCount,
                  onReturn: onBellReturn,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
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

class _BudgetCard extends StatefulWidget {
  final double spent;
  final NumberFormat baht;
  const _BudgetCard({required this.spent, required this.baht});

  @override
  State<_BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<_BudgetCard> {
  static const _kBudgetKey = 'app_budget';
  double _budget = 3000;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // re-read whenever the shared data revision bumps (e.g. budget changed)
    DataScope.watch(context);
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final b = prefs.getDouble(_kBudgetKey);
    if (b != null && mounted && b != _budget) {
      setState(() => _budget = b);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final spent = widget.spent;
    final baht = widget.baht;
    // progress = spent / budget, clamped to 0..1; guard divide-by-zero
    final ratio = _budget > 0 ? (spent / _budget) : 0.0;
    final progress = ratio.clamp(0.0, 1.0);
    final pct = (ratio * 100).round();
    final overBudget = spent > _budget;
    final barColor = overBudget ? AppColors.danger : AppColors.brand500;

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
          // "spent / budget"
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(baht.format(spent),
                  style: AppType.headlineMedium
                      .copyWith(color: barColor)),
              const SizedBox(width: AppSpacing.xs),
              Text('/ ${baht.format(_budget)}',
                  style: AppType.bodyMedium
                      .copyWith(color: AppColors.neutral500)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.neutral200,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            s.ofBudgetUsed('$pct'),
            style: AppType.caption.copyWith(
              color: overBudget ? AppColors.danger : AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}
