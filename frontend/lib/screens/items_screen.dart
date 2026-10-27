import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/household_item.dart';
import '../services/api_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';
import '../i18n/locale_scope.dart';
import 'add_edit_item_screen.dart';
import 'item_detail_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  ApiService? _api;
  Future<List<HouseholdItem>>? _future;
  final _searchCtrl = TextEditingController();
  String _search = '';
  ItemCategory? _category; // null = all

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api == null) {
      _api = ApiService(auth: AuthScope.of(context));
      _future = _api!.getItems();
    }
    final rev = DataScope.watch(context);
    if (rev != _rev) {
      _rev = rev;
      if (_api != null) _future = _api!.getItems();
    }
  }

  int _rev = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // full re-fetch (pull-to-refresh / after add). Category+search filter is
  // done client-side in build() so switching chips is instant (no flicker).
  void _reload() {
    setState(() => _future = _api!.getItems());
  }

  Future<void> _openAdd() async {
    final created = await showAddItemFlow(context);
    if (created) _reload();
  }

  /// Confirm + delete an item (used by swipe-to-delete). Returns true if the
  /// row should be dismissed (i.e. the item was actually deleted).
  Future<bool> _confirmDelete(HouseholdItem item) async {
    final s = context.strings;
    final messenger = ScaffoldMessenger.of(context);
    final dataRefresh = DataScope.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: s.deleteItemConfirmTitle,
      message: s.deleteItemConfirmMessage(item.name),
      confirmLabel: s.delete,
      cancelLabel: s.cancel,
      icon: Icons.delete_outline_rounded,
      danger: true,
    );
    if (!confirmed) return false;
    try {
      await _api!.deleteItem(item.itemId);
      dataRefresh.bump();
      if (mounted) {
        AppSnackBar.show(messenger, s.itemDeleted, SnackKind.success);
        _reload();
      }
      return true;
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(messenger, s.errorWith(e), SnackKind.error);
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final baht = NumberFormat.currency(
        locale: context.locale.lang, symbol: '฿', decimalDigits: 0);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  Text(s.itemsTitle,
                      style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
            ),
            // search
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: s.searchItems,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // category filter chips
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  _CatChip(
                    label: s.categoryAll,
                    selected: _category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                  for (final c in ItemCategory.values)
                    _CatChip(
                      label: s.categoryName(categoryToString(c)),
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _reload(),
                child: FutureBuilder<List<HouseholdItem>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SkeletonList();
                    }
                    if (snap.hasError) {
                      return ErrorView(error: snap.error!, onRetry: _reload);
                    }
                    var items = snap.data ?? [];
                    final hasItems = items.isNotEmpty;
                    if (_category != null) {
                      items = items
                          .where((i) => i.category == _category)
                          .toList();
                    }
                    if (_search.isNotEmpty) {
                      final q = _search.toLowerCase();
                      items = items
                          .where((i) => i.name.toLowerCase().contains(q))
                          .toList();
                    }
                    if (items.isEmpty) {
                      if (hasItems) {
                        return EmptyState(
                          icon: Icons.search_off_rounded,
                          title: s.noMatchingItems,
                          message: s.noMatchingItemsHint,
                          action: FilledButton(
                            onPressed: () => setState(() {
                              _search = '';
                              _searchCtrl.clear();
                              _category = null;
                            }),
                            child: Text(s.clearFilters),
                          ),
                        );
                      }
                      return EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: s.noItemsYet,
                        message: s.noItemsYetHint,
                        action: FilledButton.icon(
                          onPressed: _openAdd,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(s.addProduct),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, 90),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return Dismissible(
                          key: ValueKey(item.itemId),
                          direction: DismissDirection.endToStart,
                          // confirm (and perform) the delete here; the list is
                          // reloaded on success so we return false to avoid a
                          // double removal of the row.
                          confirmDismiss: (_) async {
                            await _confirmDelete(item);
                            return false;
                          },
                          background: _SwipeDeleteBackground(label: s.delete),
                          child: _ItemCard(
                            item: item,
                            baht: baht,
                            onTap: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ItemDetailScreen(itemId: item.itemId),
                                ),
                              );
                              if (changed == true) _reload();
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FutureBuilder<List<HouseholdItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.data?.isEmpty ?? true) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: _openAdd,
            child: const Icon(Icons.add_rounded),
          );
        },
      ),
    );
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  final String label;
  const _SwipeDeleteBackground({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: AppRadius.rLg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppType.label.copyWith(color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: selected ? AppColors.brand500 : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final HouseholdItem item;
  final NumberFormat baht;
  final VoidCallback onTap;
  const _ItemCard(
      {required this.item, required this.baht, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final status = AppStatus.fromDays(item.daysUntilExpiry);
    final img = _decode(item.imageBase64);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
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
                Text(item.name,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  [
                    if (item.sizeLabel.isNotEmpty) item.sizeLabel,
                    '${item.quantity} ${item.unitLabel ?? s.pieces}',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusChip(
            status: status,
            label: {
              StockStatus.normal: s.statusNormal,
              StockStatus.low: s.statusLow,
              StockStatus.shouldBuy: s.statusShouldBuy,
              StockStatus.out: s.statusOut,
            }[status]!,
          ),
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
