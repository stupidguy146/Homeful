import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';
import '../i18n/locale_scope.dart';
import 'product_detail_screen.dart';

/// "To buy" checklist — products marked `out` or `low`, grouped by urgency.
/// Selected products are recorded directly with their quantity and price.
class ToBuyScreen extends StatefulWidget {
  const ToBuyScreen({super.key});

  @override
  State<ToBuyScreen> createState() => _ToBuyScreenState();
}

class _ToBuyScreenState extends State<ToBuyScreen> {
  ApiService? _api;
  Future<List<Product>>? _future;
  final Set<String> _selectedIds = {};
  final Map<String, int> _quantities = {};
  final Map<String, TextEditingController> _priceControllers = {};
  bool _buyingSelected = false;
  int _rev = 0;

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api == null) {
      _api = ApiService(auth: AuthScope.of(context));
      _future = _loadProductsToBuy();
    }
    final rev = DataScope.watch(context);
    if (rev != _rev) {
      _rev = rev;
      if (_api != null) {
        _future = _loadProductsToBuy();
      }
    }
  }

  void _reload() => setState(() {
        _future = _loadProductsToBuy();
      });

  Future<List<Product>> _loadProductsToBuy() async {
    final products = await _api!.getProductsToBuy();
    final productIds = products.map((product) => product.productId).toSet();
    _selectedIds.removeWhere((productId) => !productIds.contains(productId));
    return products;
  }

  Future<void> _refresh() async {
    _reload();
    await _future!;
  }

  TextEditingController _priceControllerFor(Product product) =>
      _priceControllers.putIfAbsent(
        product.productId,
        TextEditingController.new,
      );

  void _setSelected(Product product, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(product.productId);
      } else {
        _selectedIds.remove(product.productId);
      }
    });
  }

  void _setQuantity(Product product, int quantity) {
    setState(() => _quantities[product.productId] = quantity);
  }

  Future<void> _buySelected(List<Product> products) async {
    if (_buyingSelected || products.isEmpty) return;

    final s = context.strings;
    final messenger = ScaffoldMessenger.of(context);
    final purchases = <({Product product, int quantity, double price})>[];
    for (final product in products) {
      final priceText = _priceControllerFor(product).text.trim();
      final price = double.tryParse(priceText);
      if (price == null ||
          !price.isFinite ||
          price < 0 ||
          (priceText.contains('.') && priceText.split('.').last.length > 2)) {
        AppSnackBar.show(messenger, s.priceRequired, SnackKind.error);
        return;
      }
      purchases.add((
        product: product,
        quantity: _quantities[product.productId] ?? 1,
        price: price,
      ));
    }

    final dataRefresh = DataScope.of(context);
    setState(() => _buyingSelected = true);
    var purchased = 0;
    try {
      for (final purchase in purchases) {
        await _api!.createPurchase(purchase.product.productId, {
          'quantity': purchase.quantity,
          'price': purchase.price,
          'purchasedAt': DateTime.now().toIso8601String().substring(0, 10),
        });
        purchased++;
      }
      if (mounted) {
        AppSnackBar.show(
          messenger,
          s.purchaseBatchSaved(purchased),
          SnackKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(messenger, s.errorWith(e), SnackKind.error);
      }
    } finally {
      if (mounted) {
        if (purchased > 0) dataRefresh.bump();
        setState(() {
          _buyingSelected = false;
        });
      }
    }
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
        top: false,
        child: Column(
          children: [
            GradientHeader(
              title: s.toBuyTitle,
              subtitle: s.appTitle,
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
                  final selectedProducts = products
                      .where((p) => _selectedIds.contains(p.productId))
                      .toList();
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                            children: [
                              if (out.isNotEmpty) ...[
                                _SectionLabel(
                                  label: '🔴 ${s.toBuyOutSection}',
                                  count: out.length,
                                ),
                                for (final p in out)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md),
                                    child: _ToBuyCard(
                                      product: p,
                                      checked:
                                          _selectedIds.contains(p.productId),
                                      quantity: _quantities[p.productId] ?? 1,
                                      priceController: _priceControllerFor(p),
                                      onChanged: (value) =>
                                          _setSelected(p, value),
                                      onQuantityChanged: (value) =>
                                          _setQuantity(p, value),
                                      enabled: !_buyingSelected,
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
                                    padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md),
                                    child: _ToBuyCard(
                                      product: p,
                                      checked:
                                          _selectedIds.contains(p.productId),
                                      quantity: _quantities[p.productId] ?? 1,
                                      priceController: _priceControllerFor(p),
                                      onChanged: (value) =>
                                          _setSelected(p, value),
                                      onQuantityChanged: (value) =>
                                          _setQuantity(p, value),
                                      enabled: !_buyingSelected,
                                      onTap: () => _openDetail(p),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                        _SelectionBar(
                          count: _selectedIds.length,
                          loading: _buyingSelected,
                          onBuy: () => _buySelected(selectedProducts),
                        ),
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

class _SelectionBar extends StatelessWidget {
  final int count;
  final bool loading;
  final VoidCallback onBuy;
  const _SelectionBar({
    required this.count,
    required this.loading,
    required this.onBuy,
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
            Expanded(
              child: Text(
                s.selectedItems(count),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: loading || count == 0 ? null : onBuy,
              icon: loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
              label: Text(s.buySelected(count)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToBuyCard extends StatelessWidget {
  final Product product;
  final bool checked;
  final int quantity;
  final TextEditingController priceController;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onTap;
  const _ToBuyCard({
    required this.product,
    required this.checked,
    required this.quantity,
    required this.priceController,
    required this.enabled,
    required this.onChanged,
    required this.onQuantityChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final img = _decode(product.imageBase64);
    final subtitle = [
      if (product.sizeLabel.isNotEmpty) product.sizeLabel,
      if ((product.unitLabel ?? '').isNotEmpty) product.unitLabel!,
    ].join(' · ');
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: checked,
                onChanged: enabled ? (value) => onChanged(value == true) : null,
                activeColor: AppColors.brand500,
              ),
              Container(
                width: 48,
                height: 48,
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
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.neutral400),
            ],
          ),
          if (checked) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(context.strings.quantity),
                IconButton(
                  tooltip: context.strings.quantity,
                  visualDensity: VisualDensity.compact,
                  onPressed: enabled && quantity > 1
                      ? () => onQuantityChanged(quantity - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Text('$quantity'),
                IconButton(
                  tooltip: context.strings.quantity,
                  visualDensity: VisualDensity.compact,
                  onPressed: enabled && quantity < 100000
                      ? () => onQuantityChanged(quantity + 1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    enabled: enabled,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.strings.unitPrice,
                      prefixText: '฿ ',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
