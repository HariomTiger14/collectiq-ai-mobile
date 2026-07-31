import 'dart:convert';

import 'package:collectiq_ai/features/notifications/domain/entities/notification_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Append-once persistent log of notification events (one row per trigger).
/// This is the inbox's source of truth, independent of an alert's current
/// status — history survives an alert re-arming, and read/dismiss is per-event.
class NotificationEventStore {
  const NotificationEventStore();

  static const _key = 'notification_events';

  // Hard cap on stored rows so the log can never grow unbounded.
  static const _maxStored = 200;

  Future<List<NotificationEvent>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(NotificationEvent.fromJson)
        .toList();
  }

  Future<void> _save(List<NotificationEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    // Keep newest first, capped.
    final sorted = [...events]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final capped = sorted.length > _maxStored
        ? sorted.sublist(0, _maxStored)
        : sorted;
    await prefs.setString(
      _key,
      jsonEncode(capped.map((e) => e.toJson()).toList()),
    );
  }

  /// Appends an event, ignoring duplicates (same id = same trigger).
  Future<void> append(NotificationEvent event) async {
    final events = await all();
    if (events.any((e) => e.id == event.id)) {
      return;
    }
    await _save([...events, event]);
  }

  Future<void> markRead(Iterable<String> ids, DateTime at) async {
    final target = ids.toSet();
    if (target.isEmpty) {
      return;
    }
    final events = await all();
    final updated = events
        .map(
          (e) => (target.contains(e.id) && e.readAt == null)
              ? e.copyWith(readAt: at)
              : e,
        )
        .toList();
    await _save(updated);
  }

  Future<void> delete(Iterable<String> ids) async {
    final target = ids.toSet();
    if (target.isEmpty) {
      return;
    }
    final events = await all();
    await _save(events.where((e) => !target.contains(e.id)).toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
