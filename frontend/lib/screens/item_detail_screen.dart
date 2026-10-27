import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/household_item.dart';
import '../services/api_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';
import '../i18n/locale_scope.dart';
import 'add_edit_item_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  ApiService? _api;
  Future<HouseholdItem>? _future;
  bool _changed = false;
  bool _deleting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api == null) {
      _api = ApiService(auth: AuthScope.of(context));
      _future = _api!.getItem(widget.itemId);
    }
  }

  void _reload() => setState(() => _future = _api!.getItem(widget.itemId));

  Future<void> _delete() async {
    final s = context.strings;
    final messenger = ScaffoldMessenger.of(context);
    final dataRefresh = DataScope.of(context);
    setState(() => _deleting = true);
    try {
      await _api!.deleteItem(widget.itemId);
      dataRefresh.bump();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.errorWith(e))));
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final baht = NumberFormat.currency(
        locale: context.locale.lang, symbol: '฿', decimalDigits: 0);
    final df = DateFormat('d MMM yyyy', context.locale.lang);

    return Scaffold(
      body: FutureBuilder<HouseholdItem>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return ErrorView(error: snap.error!, onRetry: _reload);
          }
          final item = snap.data!;
          final status = AppStatus.fromDays(item.daysUntilExpiry);
          final img = _decode(item.imageBase64);
          final statusLabel = {
            StockStatus.normal: s.statusNormal,
            StockStatus.low: s.statusLow,
            StockStatus.shouldBuy: s.statusShouldBuy,
            StockStatus.out: s.statusOut,
          }[status]!;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              GradientHeader(
                subtitle: s.categoryName(categoryToString(item.category)),
                title: item.name,
                leading: _Back(onTap: () => Navigator.pop(context, _changed)),
              ),
              Transform.translate(
                offset: const Offset(0, -28),
                child: Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.brand100,
                      borderRadius: AppRadius.rLg,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: AppShadows.md,
                      image: img != null
                          ? DecorationImage(
                              image: MemoryImage(img), fit: BoxFit.cover)
                          : null,
                    ),
                    child: img == null
                        ? const Icon(Icons.inventory_2_outlined,
                            size: 40, color: AppColors.brand500)
                        : null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: StatusChip(status: status, label: statusLabel)),
                    const SizedBox(height: AppSpacing.lg),
                    AppCard(
                      child: Column(
                        children: [
                          _row(context, s.sizeLabel, item.sizeLabel),
                          _row(context, s.quantity,
                              '${item.quantity} ${item.unitLabel ?? s.pieces}'),
                          _row(context, s.unitPrice, baht.format(item.price)),
                          _row(context, s.total, baht.format(item.subtotal)),
                          if ((item.store ?? '').isNotEmpty)
                            _row(context, s.storeLabel, item.store!),
                          if (item.purchaseDate != null)
                            _row(context, s.purchaseDateLabel,
                                df.format(DateTime.parse(item.purchaseDate!))),
                          if ((item.buyer ?? '').isNotEmpty)
                            _row(context, s.buyerLabel, item.buyer!),
                          if (item.expiryDate != null)
                            _row(context, s.expiryLabel,
                                df.format(DateTime.parse(item.expiryDate!))),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () async {
                        final changed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditItemScreen(existing: item),
                          ),
                        );
                        if (changed == true) {
                          _changed = true;
                          _reload();
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(s.editItemTitle),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: _deleting ? null : _delete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      icon: _deleting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.danger),
                            )
                          : const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(s.deleteItem),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  static dynamic _decode(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      final s = b64.contains(',') ? b64.split(',').last : b64;
      return base64Decode(s);
    } catch (_) {
      return null;
    }
  }
}

class _Back extends StatelessWidget {
  final VoidCallback onTap;
  const _Back({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: AppRadius.rMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rMd,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

