import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../i18n/locale_scope.dart';
import '../i18n/app_strings.dart';
import '../models/expiring_item.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/notification_read_store.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import 'item_detail_screen.dart';

/// In-app notifications screen: lists household items expiring within
/// [NotificationService.thresholdDays] days — the same set the OS reminders
/// are scheduled for. Reachable from the bell icon in the header.
///
/// Each entry has a local read/unread state (persisted via
/// [NotificationReadStore]): unread entries stand out (tinted card, accent
/// dot, bold title); read entries look normal and carry a "read" stamp.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  ApiService? _api;
  final _store = NotificationStore();
  Future<_NotifData>? _future;
  _NotifFilter _filter = _NotifFilter.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api ??= ApiService(auth: AuthScope.of(context));
    _future ??= _load();
  }

  Future<_NotifData> _load() async {
    final items =
        await _api!.getExpiringSoon(days: NotificationService.thresholdDays);
    if (mounted) {
      await NotificationService.instance.syncExpiring(items, context.strings);
    }

    // reconcile local notification events (adds new, drops gone/>7 days old)
    final events = await _store.sync(items.map((e) => e.itemId).toSet());
    final byId = {for (final it in items) it.itemId: it};
    final eventById = {for (final e in events) e.itemId: e};

    // build rows for items we still have, newest (seenAt) first
    final rows = <_NotifRow>[];
    for (final e in events) {
      final it = byId[e.itemId];
      if (it != null) rows.add(_NotifRow(item: it, event: e));
    }
    rows.sort((a, b) => b.event.seenAt.compareTo(a.event.seenAt));
    return _NotifData(rows: rows, readIds: {
      for (final e in eventById.values)
        if (e.read) e.itemId
    });
  }

  void _reload() => setState(() {
        _future = _load();
      });

  Future<void> _markRead(String itemId) async {
    await _store.markRead(itemId);
    _reload();
  }

  Future<void> _markAllRead(Iterable<String> itemIds) async {
    await _store.markAllRead(itemIds);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final df = DateFormat('d MMM yyyy', context.locale.lang);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GradientHeader(
                subtitle: s.notificationsSubtitle,
                title: s.notificationsTitle,
                leading: _HeaderIconButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
            FutureBuilder<_NotifData>(
              future: _future,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data == null || data.rows.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                final unread =
                    data.rows.where((r) => !r.event.read).length;
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: s.notifFilterAll,
                          selected: _filter == _NotifFilter.all,
                          onTap: () =>
                              setState(() => _filter = _NotifFilter.all),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _FilterChip(
                          label: unread > 0
                              ? '${s.notifFilterUnread} ($unread)'
                              : s.notifFilterUnread,
                          selected: _filter == _NotifFilter.unread,
                          onTap: () =>
                              setState(() => _filter = _NotifFilter.unread),
                        ),
                        const Spacer(),
                        if (unread > 0)
                          _MarkAllButton(
                            label: s.notifMarkAllRead,
                            onTap: () => _markAllRead(
                                data.rows.map((r) => r.item.itemId)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            FutureBuilder<_NotifData>(
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
                final data = snapshot.data!;
                if (data.rows.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.notifications_off_outlined,
                      title: s.noNotifications,
                      message: s.noNotificationsHint,
                    ),
                  );
                }
                // apply All / Unread filter
                final rows = _filter == _NotifFilter.unread
                    ? data.rows.where((r) => !r.event.read).toList()
                    : data.rows;
                if (rows.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.mark_email_read_outlined,
                      title: s.noUnreadNotifications,
                      message: s.noNotificationsHint,
                    ),
                  );
                }

                // flatten into [day-header, card, card, day-header, ...]
                final entries = _groupByDay(rows, s);

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                  sliver: SliverList.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, i) {
                      final next =
                          i + 1 < entries.length ? entries[i + 1] : null;
                      // bigger gap before a new day header
                      return SizedBox(
                          height: next is _DayHeaderEntry
                              ? AppSpacing.lg
                              : AppSpacing.md);
                    },
                    itemBuilder: (context, i) {
                      final entry = entries[i];
                      if (entry is _DayHeaderEntry) {
                        return Padding(
                          padding: EdgeInsets.only(
                              top: i == 0 ? 0 : AppSpacing.xs,
                              bottom: AppSpacing.xs),
                          child: Text(
                            entry.label,
                            style: AppType.label
                                .copyWith(color: AppColors.neutral500),
                          ),
                        );
                      }
                      final row = (entry as _CardEntry).row;
                      final it = row.item;
                      final isRead = row.event.read;
                      return _NotificationCard(
                        item: it,
                        event: row.event,
                        df: df,
                        read: isRead,
                        onTap: () async {
                          if (!isRead) await _store.markRead(it.itemId);
                          if (!context.mounted) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ItemDetailScreen(itemId: it.itemId)),
                          );
                          _reload();
                        },
                        onMarkRead:
                            isRead ? null : () => _markRead(it.itemId),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Group rows (already sorted newest-first) by calendar day, producing a
  /// flat list of day-header + card entries.
  List<_Entry> _groupByDay(List<_NotifRow> rows, AppStrings s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final df = DateFormat('d MMM yyyy', s.lang);

    String labelFor(DateTime d) {
      final day = DateTime(d.year, d.month, d.day);
      final diff = today.difference(day).inDays;
      if (diff == 0) return s.notifToday;
      if (diff == 1) return s.notifYesterday;
      return df.format(day);
    }

    final out = <_Entry>[];
    String? currentLabel;
    for (final r in rows) {
      final label = labelFor(r.event.seenAt);
      if (label != currentLabel) {
        currentLabel = label;
        out.add(_DayHeaderEntry(label));
      }
      out.add(_CardEntry(r));
    }
    return out;
  }
}

/// One notification row = the item + its stored event (seenAt / read).
class _NotifRow {
  final ExpiringItem item;
  final NotifEvent event;
  _NotifRow({required this.item, required this.event});
}

class _NotifData {
  final List<_NotifRow> rows;
  final Set<String> readIds;
  _NotifData({required this.rows, required this.readIds});
}

/// Flattened list entry (day header or card) for the grouped list.
sealed class _Entry {}

class _DayHeaderEntry extends _Entry {
  final String label;
  _DayHeaderEntry(this.label);
}

class _CardEntry extends _Entry {
  final _NotifRow row;
  _CardEntry(this.row);
}

/// Leading thumbnail: the product image when available, otherwise a coloured
/// fallback icon tinted by urgency.
class _ItemThumb extends StatelessWidget {
  final String? imageBase64;
  final bool overdue;
  final Color fg;
  final Color bg;

  const _ItemThumb({
    required this.imageBase64,
    required this.overdue,
    required this.fg,
    required this.bg,
  });

  static Uint8List? _decode(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      final s = b64.contains(',') ? b64.split(',').last : b64;
      return base64Decode(s);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _decode(imageBase64);
    if (bytes != null) {
      return ClipRRect(
        borderRadius: AppRadius.rMd,
        child: Image.memory(
          bytes,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.rMd,
      ),
      child: Icon(
        overdue ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
        color: fg,
      ),
    );
  }
}

/// Urgency colour by days-until-expiry, shared by the card icon and the
/// expiry chip: red = expired/today, orange = 1 day, amber/yellow = 2-3 days.
(Color fg, Color bg) _urgencyColors(int? days) {
  if (days == null) return (AppColors.neutral500, AppColors.neutral100);
  if (days <= 0) return (AppColors.danger, AppColors.coralTint); // red
  if (days == 1) return (AppColors.shouldBuy, AppColors.amberTint); // orange
  return (AppColors.warning, AppColors.amberTint); // amber / yellow
}

class _NotificationCard extends StatelessWidget {
  final ExpiringItem item;
  final NotifEvent event;
  final DateFormat df;
  final bool read;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;

  const _NotificationCard({
    required this.item,
    required this.event,
    required this.df,
    required this.read,
    required this.onTap,
    this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final d = item.daysUntilExpiry;
    final overdue = d != null && d < 0;
    final (urgentFg, urgentBg) = _urgencyColors(d);

    // unread → tinted/brand-bordered card that stands out; read → plain card.
    final cardColor = read
        ? Theme.of(context).cardTheme.color
        : AppColors.brand500.withValues(alpha: 0.06);

    return AppCard(
      color: cardColor,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // unread accent dot
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: read ? Colors.transparent : AppColors.brand500,
              ),
            ),
          ),
          _ItemThumb(
            imageBase64: item.imageBase64,
            overdue: overdue,
            fg: read ? AppColors.neutral500 : urgentFg,
            bg: read ? AppColors.neutral100 : urgentBg,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight:
                                  read ? FontWeight.w500 : FontWeight.w700,
                              color: read ? AppColors.neutral600 : null,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (read)
                      _ReadStamp(label: s.notifRead)
                    else
                      _UnreadBadge(label: s.notifUnread),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _ExpiryHighlight(
                  item: item,
                  df: df,
                  dimmed: read,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  s.notifReceivedAt(
                      DateFormat('HH:mm', s.lang).format(event.seenAt)),
                  style: AppType.caption.copyWith(color: AppColors.neutral400),
                ),
                if (onMarkRead != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  GestureDetector(
                    onTap: onMarkRead,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.done_rounded,
                            size: 15, color: AppColors.brand500),
                        const SizedBox(width: 4),
                        Text(
                          s.notifMarkRead,
                          style: AppType.caption
                              .copyWith(color: AppColors.brand500),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Emphasised "when does it expire" chip: an icon + a bold urgency phrase
/// (today / tomorrow / in N days / overdue) plus the exact date. Coloured by
/// status so the deadline stands out. Dimmed when the entry is read.
class _ExpiryHighlight extends StatelessWidget {
  final ExpiringItem item;
  final DateFormat df;
  final bool dimmed;

  const _ExpiryHighlight({
    required this.item,
    required this.df,
    required this.dimmed,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final d = item.daysUntilExpiry;

    // urgency phrase
    final String phrase;
    if (d == null) {
      phrase = '';
    } else if (d < 0) {
      phrase = s.expiredAgoShort(-d);
    } else if (d == 0) {
      phrase = s.expiresTodayShort;
    } else if (d == 1) {
      phrase = s.expiresTomorrowShort;
    } else {
      phrase = s.expiresInDaysShort(d);
    }

    // urgency colour by days-left (shared with the card's leading icon).
    final (urgentFg, urgentBg) = _urgencyColors(d);
    final fg = dimmed ? AppColors.neutral500 : urgentFg;
    final bg = dimmed ? AppColors.neutral100 : urgentBg;
    final overdue = d != null && d < 0;

    final dateText =
        item.expiryDate != null ? df.format(item.expiryDate!) : null;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.rMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            overdue ? Icons.event_busy_rounded : Icons.schedule_rounded,
            size: 16,
            color: fg,
          ),
          const SizedBox(width: 6),
          // bold urgency phrase
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: phrase,
                    style: AppType.label.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (dateText != null)
                    TextSpan(
                      text: '  ·  ${s.expiryOn(dateText)}',
                      style: AppType.caption.copyWith(
                        color: fg.withValues(alpha: 0.85),
                      ),
                    ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small grey "read" stamp.
class _ReadStamp extends StatelessWidget {
  final String label;
  const _ReadStamp({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.neutral200,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 12, color: AppColors.neutral500),
          const SizedBox(width: 3),
          Text(label,
              style: AppType.caption.copyWith(color: AppColors.neutral500)),
        ],
      ),
    );
  }
}

/// Bright "new" badge for unread entries.
class _UnreadBadge extends StatelessWidget {
  final String label;
  const _UnreadBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brand500,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label,
          style: AppType.caption
              .copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
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

enum _NotifFilter { all, unread }

/// Pill filter chip (All / Unread).
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

/// "Mark all read" action placed at the bottom-right of the list header row.
class _MarkAllButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MarkAllButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.done_all_rounded,
                size: 16, color: AppColors.brand500),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppType.label.copyWith(color: AppColors.brand500),
            ),
          ],
        ),
      ),
    );
  }
}
