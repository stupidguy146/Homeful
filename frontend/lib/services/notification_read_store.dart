import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A locally-stored notification event for an expiring item.
class NotifEvent {
  final String itemId;
  final DateTime seenAt; // when this item first entered the "expiring" window
  final bool read;

  NotifEvent({required this.itemId, required this.seenAt, this.read = false});

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'seenAt': seenAt.toIso8601String(),
        'read': read,
      };

  factory NotifEvent.fromJson(Map<String, dynamic> j) => NotifEvent(
        itemId: j['itemId'] as String,
        seenAt: DateTime.parse(j['seenAt'] as String),
        read: (j['read'] as bool?) ?? false,
      );

  NotifEvent copyWith({bool? read}) =>
      NotifEvent(itemId: itemId, seenAt: seenAt, read: read ?? this.read);
}

/// Local-only store of notification events (expiring-item reminders).
/// Keyed by item id. Nothing is sent to the server — this is UI history that
/// lives on this device.
///
/// Retention: events older than [retentionDays] days are cleared. Each item's
/// `seenAt` is recorded the first time it enters the expiring window, so the
/// list can be sorted newest-first and grouped by day.
class NotificationStore {
  static const _kEvents = 'notif_events_v2';
  static const int retentionDays = 7;

  Future<Map<String, NotifEvent>> _readMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kEvents);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => NotifEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      return {for (final e in list) e.itemId: e};
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeMap(Map<String, NotifEvent> map) async {
    final prefs = await SharedPreferences.getInstance();
    final list = map.values.map((e) => e.toJson()).toList();
    await prefs.setString(_kEvents, jsonEncode(list));
  }

  /// Reconcile stored events with the current set of expiring [currentIds]:
  /// - add new events (seenAt = now) for ids not seen before
  /// - drop events whose item is no longer expiring (left the window)
  /// - drop events older than [retentionDays]
  /// Returns the resulting events (unsorted).
  Future<List<NotifEvent>> sync(Set<String> currentIds) async {
    final map = await _readMap();
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: retentionDays));

    // add newly-seen ids
    for (final id in currentIds) {
      map.putIfAbsent(id, () => NotifEvent(itemId: id, seenAt: now));
    }
    // keep only ids still expiring AND within retention window
    map.removeWhere(
        (id, e) => !currentIds.contains(id) || e.seenAt.isBefore(cutoff));

    await _writeMap(map);
    return map.values.toList();
  }

  Future<void> markRead(String itemId) async {
    final map = await _readMap();
    final e = map[itemId];
    if (e != null && !e.read) {
      map[itemId] = e.copyWith(read: true);
      await _writeMap(map);
    }
  }

  Future<void> markAllRead(Iterable<String> itemIds) async {
    final map = await _readMap();
    var changed = false;
    for (final id in itemIds) {
      final e = map[id];
      if (e != null && !e.read) {
        map[id] = e.copyWith(read: true);
        changed = true;
      }
    }
    if (changed) await _writeMap(map);
  }
}
