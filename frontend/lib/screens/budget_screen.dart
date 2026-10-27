import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';
import '../i18n/locale_scope.dart';

/// Budget dashboard built from /api/analytics/summary.
/// Budget target is stored locally (shared_preferences) — no backend change.
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  static const _kBudgetKey = 'app_budget';
  ApiService? _api;
  Future<AnalyticsSummary>? _future;
  double _budget = 3000;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api == null) {
      _api = ApiService(auth: AuthScope.of(context));
      _future = _api!.getSummary();
      _loadBudget();
    }
    final rev = DataScope.watch(context);
    if (rev != _rev) {
      _rev = rev;
      if (_api != null) _future = _api!.getSummary();
    }
  }

  int _rev = 0;

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final b = prefs.getDouble(_kBudgetKey);
    if (b != null && mounted) setState(() => _budget = b);
  }

  void _reload() => setState(() => _future = _api!.getSummary());

  Future<void> _editBudget() async {
    final s = context.strings;
    final dataRefresh = DataScope.of(context);
    final ctrl = TextEditingController(text: _budget.toStringAsFixed(0));
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.setBudget),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: s.budgetField),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(s.save2)),
        ],
      ),
    );
    if (saved == true) {
      final v = double.tryParse(ctrl.text) ?? _budget;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kBudgetKey, v);
      if (mounted) setState(() => _budget = v);
      dataRefresh.bump(); // let other screens (home card) pick up the new budget
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final baht = NumberFormat.currency(
        locale: context.locale.lang, symbol: '฿', decimalDigits: 0);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<AnalyticsSummary>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SkeletonList();
            }
            if (snap.hasError) {
              return ErrorView(error: snap.error!, onRetry: _reload);
            }
            final data = snap.data!;
            final pct = _budget > 0
                ? (data.grandTotal / _budget * 100).clamp(0, 999)
                : 0.0;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                const _Header(),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _TotalCard(
                      total: data.grandTotal,
                      budget: _budget,
                      pct: pct.toDouble(),
                      baht: baht,
                      onSetBudget: _editBudget,
                    ),
                  ),
                ),
                if (data.grandTotal == 0)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: s.noBudgetData,
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                    child: SectionHeader(title: s.spendByMonth),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: AppCard(
                      child: _BarChart(
                        months: data.months,
                        locale: context.locale.lang,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                    child: SectionHeader(title: s.spendByCategory),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: AppCard(
                      child: Column(
                        children: [
                          for (final c in data.categories)
                            _CategoryRow(
                              category: c.category,
                              amount: c.amount,
                              total: data.grandTotal,
                              baht: baht,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 90),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxxl),
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
            Text(s.budgetTitle,
                style: AppType.headlineMedium.copyWith(color: Colors.white)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              s.expectedSpend,
              style: AppType.bodyLarge
                  .copyWith(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;
  final double budget;
  final double pct;
  final NumberFormat baht;
  final VoidCallback onSetBudget;
  const _TotalCard({
    required this.total,
    required this.budget,
    required this.pct,
    required this.baht,
    required this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final over = pct > 100;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title + "set budget" action on one row
          Row(
            children: [
              Expanded(
                child: Text(s.expectedSpend,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              Material(
                color: AppColors.brand500.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: InkWell(
                  onTap: onSetBudget,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded,
                            color: AppColors.brand600, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text(s.setBudget,
                            style: AppType.label
                                .copyWith(color: AppColors.brand600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(baht.format(total),
              style: AppType.displayLarge.copyWith(
                  color: over ? AppColors.danger : AppColors.brand600)),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.neutral200,
              valueColor: AlwaysStoppedAnimation(
                  over ? AppColors.danger : AppColors.brand500),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${s.ofBudgetUsed(pct.toStringAsFixed(0))} · ${baht.format(budget)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Simple container-based monthly bar chart (no chart library).
class _BarChart extends StatelessWidget {
  final List<MonthSpend> months;
  final String locale;
  const _BarChart({required this.months, required this.locale});

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return const SizedBox(height: 80);
    }
    final maxAmount =
        months.map((m) => m.amount).fold<double>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final m in months)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.compact(locale: locale).format(m.amount),
                    style: AppType.caption,
                  ),
                  const SizedBox(height: 4),
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      height: maxAmount > 0
                          ? (m.amount / maxAmount) * 100 + 4
                          : 4,
                      decoration: const BoxDecoration(
                        gradient: AppGradients.brand,
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppRadius.sm)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_label(m.month), style: AppType.caption),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _label(String yyyymm) {
    // yyyy-mm → short month
    final parts = yyyymm.split('-');
    if (parts.length < 2) return yyyymm;
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat('MMM', locale).format(dt);
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final double amount;
  final double total;
  final NumberFormat baht;
  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.total,
    required this.baht,
  });

  IconData get _icon {
    switch (category) {
      case 'laundry':
        return Icons.local_laundry_service_outlined;
      case 'kitchen':
        return Icons.kitchen_outlined;
      case 'bathroom':
        return Icons.bathtub_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'personal':
        return Icons.face_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final pct = total > 0 ? (amount / total * 100) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.brand100,
              borderRadius: AppRadius.rMd,
            ),
            child: Icon(_icon, color: AppColors.brand500, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.categoryName(category),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.neutral200,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.brand400),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(baht.format(amount),
                  style: AppType.titleMedium
                      .copyWith(color: AppColors.brand600)),
              Text('${pct.toStringAsFixed(0)}%', style: AppType.caption),
            ],
          ),
        ],
      ),
    );
  }
}
