import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';
import '../i18n/locale_scope.dart';
import 'record_purchase_screen.dart';
import 'product_detail_screen.dart';

/// "To buy" list — product-based, driven by the user-set stock status.
/// Shows products marked `out` (urgent) and `low`, grouped. Buying a product
/// records a purchase which resets its status to in_stock, so it leaves here.
class ToBuyScreen extends StatefulWidget {
  const ToBuyScreen({super.key});

  @override
  State<ToBuyScreen> createState() => _ToBuyScreenState();
}

class _ToBuyScreenState extends State<ToBuyScreen> {
  ApiService? _api;
  Future<List<Product>>? _future;
  int _rev = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api == null) {
      _api = ApiService(auth: AuthScope.of(context));
      _future = _api!.getProductsToBuy();
    }
    final rev = DataScope.watch(context);
    if (rev != _rev) {
      _rev = rev;
      if (_api != null) _future = _api!.getProductsToBuy();
    }
  }

  void _reload() => setState(() {
        _future = _api!.getProductsToBuy();
      });

  Future<void> _buy(Product p) async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RecordPurchaseScreen(preselected: p),
      ),
    );
    if (done == true) _reload();
  }

  Future<void> _openDetail(Product p) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: p.productId),
      ),
    );
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Text(s.toBuyTitle,
                      style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SkeletonList();
                  }
                  if (snap.hasError) {
                    return ErrorView(error: snap.error!, onRetry: _reload);
                  }
                  final products = snap.data ?? [];
                  if (products.isEmpty) {
                    return EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: s.toBuyEmpty,
                      message: s.toBuyEmptyHint,
                    );
                  }
                  final out = products
                      .where((p) => p.status == ProductStatus.out)
                      .toList();
                  final low = products
                      .where((p) => p.status == ProductStatus.low)
                      .toList();
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                      children: [
                        if (out.isNotEmpty) ...[
                          _SectionLabel(
                            label: '🔴 ${s.toBuyOutSection}',
                            count: out.length,
                          ),
                          for (final p in out)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _ToBuyCard(
                                product: p,
                                onBuy: () => _buy(p),
                                onTap: () => _openDetail(p),
                              ),
                            ),
                        ],
                        if (low.isNotEmpty) ...[
                          _SectionLabel(
                            label: '🟡 ${s.toBuyLowSection}',
                            count: low.length,
                          ),
                          for (final p in low)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _ToBuyCard(
                                product: p,
                                onBuy: () => _buy(p),
                                onTap: () => _openDetail(p),
                              ),
                            ),
                        ],
                      ],
                    ),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text('$label ($count)',
          style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ToBuyCard extends StatelessWidget {
  final Product product;
  final VoidCallback onBuy;
  final VoidCallback onTap;
  const _ToBuyCard({
    required this.product,
    required this.onBuy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final img = _decode(product.imageBase64);
    final subtitle = [
      if (product.sizeLabel.isNotEmpty) product.sizeLabel,
      if ((product.unitLabel ?? '').isNotEmpty) product.unitLabel!,
    ].join(' · ');
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brand100,
              borderRadius: AppRadius.rMd,
              image: img != null
                  ? DecorationImage(image: MemoryImage(img), fit: BoxFit.cover)
                  : null,
            ),
            child: img == null
                ? const Icon(Icons.inventory_2_outlined,
                    color: AppColors.brand500)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.icon(
            onPressed: onBuy,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            ),
            icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
            label: Text(s.buyButton),
          ),
        ],
      ),
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
