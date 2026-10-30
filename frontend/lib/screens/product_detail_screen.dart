import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/household_item.dart' show categoryToString;
import '../models/product.dart';
import '../models/purchase.dart';
import '../services/api_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';
import '../i18n/locale_scope.dart';
import 'record_purchase_screen.dart';

/// Bundle fetched for the detail view.
class _DetailData {
  final Product product;
  final List<Purchase> history;
  _DetailData(this.product, this.history);
}

/// Product master detail: info + stock-status actions + purchase history +
/// delete. Pops `true` when anything changed so the caller can refresh.
class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ApiService? _api;
  Future<_DetailData>? _future;
  bool _changed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api == null) {
      _api = ApiService(auth: AuthScope.of(context));
      _future = _load();
    }
  }

  Future<_DetailData> _load() async {
    final results = await Future.wait([
      _api!.getProduct(widget.productId),
      _api!.getProductHistory(widget.productId),
    ]);
    return _DetailData(results[0] as Product, results[1] as List<Purchase>);
  }

  void _reload() => setState(() {
        _future = _load();
      });

  Future<void> _setStatus(ProductStatus status) async {
    final s = context.strings;
    final messenger = ScaffoldMessenger.of(context);
    final dataRefresh = DataScope.of(context);
    try {
      await _api!.updateProductStatus(
          widget.productId, productStatusToString(status));
      _changed = true;
      dataRefresh.bump();
      if (mounted) {
        AppSnackBar.show(messenger, s.statusUpdated, SnackKind.success);
        _reload();
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(messenger, s.errorWith(e), SnackKind.error);
    }
  }

  Future<void> _recordPurchase() async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RecordPurchaseScreen()),
    );
    if (done == true) {
      _changed = true;
      _reload();
    }
  }

  Future<void> _delete(Product p) async {
    final s = context.strings;
    final messenger = ScaffoldMessenger.of(context);
    final dataRefresh = DataScope.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: s.deleteProductConfirmTitle,
      message: s.deleteProductConfirmMessage(p.name),
      confirmLabel: s.delete,
      cancelLabel: s.cancel,
      icon: Icons.delete_outline_rounded,
      danger: true,
    );
    if (!confirmed) return;
    try {
      await _api!.deleteProduct(p.productId);
      dataRefresh.bump();
      if (mounted) {
        AppSnackBar.show(messenger, s.productDeleted, SnackKind.success);
        navigator.pop(true);
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(messenger, s.errorWith(e), SnackKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        body: Column(
          children: [
            GradientHeader(
              title: s.productDetailTitle,
              subtitle: s.appTitle,
              leading: HeaderIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => Navigator.of(context).pop(_changed),
              ),
            ),
            Expanded(
              child: FutureBuilder<_DetailData>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SkeletonList();
                  }
                  if (snap.hasError) {
                    return ErrorView(error: snap.error!, onRetry: _reload);
                  }
                  return _Body(
                    data: snap.data!,
                    onSetStatus: _setStatus,
                    onRecordPurchase: _recordPurchase,
                    onDelete: _delete,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

StockStatus _stockStatusOf(ProductStatus s) {
  switch (s) {
    case ProductStatus.inStock:
      return StockStatus.normal;
    case ProductStatus.low:
      return StockStatus.low;
    case ProductStatus.out:
      return StockStatus.out;
  }
}

class _Body extends StatelessWidget {
  final _DetailData data;
  final ValueChanged<ProductStatus> onSetStatus;
  final VoidCallback onRecordPurchase;
  final ValueChanged<Product> onDelete;
  const _Body({
    required this.data,
    required this.onSetStatus,
    required this.onRecordPurchase,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final baht = NumberFormat.currency(
        locale: context.locale.lang, symbol: '฿', decimalDigits: 0);
    final df = DateFormat('d MMM yyyy', context.locale.lang);
    final p = data.product;
    final img = _decode(p.imageBase64);
    final meta = [
      s.categoryName(categoryToString(p.category)),
      if (p.sizeLabel.isNotEmpty) p.sizeLabel,
      if ((p.unitLabel ?? '').isNotEmpty) p.unitLabel!,
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 32),
      children: [
        // header card: image + name + meta + badges
        AppCard(
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: AppRadius.rMd,
                  image: img != null
                      ? DecorationImage(
                          image: MemoryImage(img), fit: BoxFit.cover)
                      : null,
                ),
                child: img == null
                    ? const Icon(Icons.inventory_2_outlined,
                        color: AppColors.brand500, size: 30)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(meta,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        StatusChip(
                          status: _stockStatusOf(p.status),
                          label: {
                            ProductStatus.inStock: s.productStatusInStock,
                            ProductStatus.low: s.productStatusLow,
                            ProductStatus.out: s.productStatusOut,
                          }[p.status]!,
                        ),
                        if (p.isRecurring) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brand100,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.autorenew_rounded,
                                    size: 12, color: AppColors.brand600),
                                const SizedBox(width: 2),
                                Text(s.recurringBadge,
                                    style: AppType.caption.copyWith(
                                        color: AppColors.brand600,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        SectionHeader(title: s.statusSection),
        const SizedBox(height: AppSpacing.sm),
        // status action buttons
        Row(
          children: [
            Expanded(
              child: _StatusButton(
                label: s.markLowButton,
                color: AppColors.warning,
                selected: p.status == ProductStatus.low,
                onTap: () => onSetStatus(ProductStatus.low),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatusButton(
                label: s.markOutButton,
                color: AppColors.danger,
                selected: p.status == ProductStatus.out,
                onTap: () => onSetStatus(ProductStatus.out),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatusButton(
                label: s.markInStockButton,
                color: AppColors.success,
                selected: p.status == ProductStatus.inStock,
                onTap: () => onSetStatus(ProductStatus.inStock),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: s.purchaseHistory,
          action: TextButton.icon(
            onPressed: onRecordPurchase,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(s.recordPurchaseAction),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (data.history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: s.noPurchaseHistory,
            ),
          )
        else
          ...data.history.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              df.format(DateTime.parse(h.purchasedAt)),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                '${h.quantity} ${s.pieces}',
                                if ((h.store ?? '').isNotEmpty) h.store!,
                                if ((h.buyer ?? '').isNotEmpty) h.buyer!,
                              ].join(' · '),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Text(baht.format(h.subtotal),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              )),

        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: () => onDelete(p),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: Text(s.deleteItem),
        ),
      ],
    );
  }

  static Uint8List? _decode(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64.contains(',') ? b64.split(',').last : b64);
    } catch (_) {
      return null;
    }
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _StatusButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : color.withValues(alpha: 0.12),
      borderRadius: AppRadius.rMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rMd,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppType.label.copyWith(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
