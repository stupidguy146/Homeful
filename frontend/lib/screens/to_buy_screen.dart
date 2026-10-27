import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/household_item.dart';
import '../services/api_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';
import '../i18n/locale_scope.dart';

/// "To buy" checklist — auto-populated from items that need restocking
/// (status low / buy-soon / out), grouped by category. Ticking shows an
/// estimated total; the buy action is a mock for this phase.
class ToBuyScreen extends StatefulWidget {
  const ToBuyScreen({super.key});

  @override
  State<ToBuyScreen> createState() => _ToBuyScreenState();
}

class _ToBuyScreenState extends State<ToBuyScreen> {
  ApiService? _api;
  Future<List<HouseholdItem>>? _future;
  final Set<String> _checked = {}; // itemIds
  bool _checkingOut = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api == null) {
      _api = ApiService(auth: AuthScope.of(context));
      _future = _loadNeedToBuy();
    }
    final rev = DataScope.watch(context);
    if (rev != _rev) {
      _rev = rev;
      if (_api != null) {
        _checked.clear();
        _future = _loadNeedToBuy();
      }
    }
  }

  int _rev = 0;

  Future<List<HouseholdItem>> _loadNeedToBuy() async {
    final items = await _api!.getItems();
    // needs restock = status != normal (low / shouldBuy / out)
    return items
        .where((i) => AppStatus.fromDays(i.daysUntilExpiry) != StockStatus.normal)
        .toList();
  }

  void _reload() {
    _checked.clear();
    setState(() => _future = _loadNeedToBuy());
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final baht = NumberFormat.currency(
        locale: context.locale.lang, symbol: '฿', decimalDigits: 0);

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<HouseholdItem>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SkeletonList();
            }
            if (snap.hasError) {
              return ErrorView(error: snap.error!, onRetry: _reload);
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return Column(
                children: [
                  _title(context, s.toBuyTitle),
                  Expanded(
                    child: EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: s.toBuyEmpty,
                      message: s.toBuyEmptyHint,
                    ),
                  ),
                ],
              );
            }

            // group by category
            final groups = <String, List<HouseholdItem>>{};
            for (final i in items) {
              groups.putIfAbsent(categoryToString(i.category), () => []).add(i);
            }
            final estimated = items
                .where((i) => _checked.contains(i.itemId))
                .fold<double>(0, (a, i) => a + i.subtotal);

            return Column(
              children: [
                _title(context, s.toBuyTitle),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                      children: [
                        for (final entry in groups.entries) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm),
                            child: Text(
                              '${s.categoryName(entry.key)} (${entry.value.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (final it in entry.value)
                                  _CheckRow(
                                    item: it,
                                    baht: baht,
                                    checked: _checked.contains(it.itemId),
                                    onChanged: (v) => setState(() {
                                      if (v == true) {
                                        _checked.add(it.itemId);
                                      } else {
                                        _checked.remove(it.itemId);
                                      }
                                    }),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ),
                  ),
                ),
                _CheckoutBar(
                  total: estimated,
                  count: _checked.length,
                  baht: baht,
                  loading: _checkingOut,
                  onCheckout: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (_checked.isEmpty) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(s.selectItemsFirst)),
                      );
                      return;
                    }
                    final n = _checked.length;
                    setState(() => _checkingOut = true);
                    await Future.delayed(const Duration(milliseconds: 500));
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text(s.checkoutDone(n))),
                    );
                    setState(() => _checkingOut = false);
                    _reload();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _title(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      );
}

class _CheckRow extends StatelessWidget {
  final HouseholdItem item;
  final NumberFormat baht;
  final bool checked;
  final ValueChanged<bool?> onChanged;
  const _CheckRow({
    required this.item,
    required this.baht,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final status = AppStatus.fromDays(item.daysUntilExpiry);
    final statusLabel = {
      StockStatus.normal: s.statusNormal,
      StockStatus.low: s.statusLow,
      StockStatus.shouldBuy: s.statusShouldBuy,
      StockStatus.out: s.statusOut,
    }[status]!;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: onChanged,
            activeColor: AppColors.brand500,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Row(
                  children: [
                    StatusChip(status: status, label: statusLabel),
                    const SizedBox(width: AppSpacing.sm),
                    Text('${item.quantity} ${item.unitLabel ?? s.pieces}',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
          Text(baht.format(item.subtotal),
              style: AppType.titleMedium.copyWith(color: AppColors.brand600)),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final double total;
  final int count;
  final NumberFormat baht;
  final bool loading;
  final Future<void> Function() onCheckout;
  const _CheckoutBar({
    required this.total,
    required this.count,
    required this.baht,
    required this.loading,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: AppShadows.lg,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.estimatedTotal,
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(baht.format(total),
                    style: AppType.titleLarge
                        .copyWith(color: AppColors.brand600)),
              ],
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: loading ? null : () => onCheckout(),
              icon: loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
              label: Text(s.checkout),
            ),
          ],
        ),
      ),
    );
  }
}
