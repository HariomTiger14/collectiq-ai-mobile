import 'package:shared_preferences/shared_preferences.dart';

/// Persists notification inbox state that is independent of the underlying
/// alerts: when the inbox was last opened (for the unread badge) and which
/// notification *events* the user has dismissed (so they stay hidden).
class NotificationSeenStore {
  const NotificationSeenStore();

  static const _lastSeenKey = 'notifications_last_seen_at';
  static const _dismissedKeysKey = 'notifications_dismissed_keys';

  // Cap the dismissed set so it can never grow unbounded; keep the newest.
  static const _maxDismissedKeys = 500;

  Future<DateTime?> lastSeenAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSeenKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> markSeen(DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenKey, at.toIso8601String());
  }

  Future<Set<String>> dismissedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_dismissedKeysKey) ?? const <String>[]).toSet();
  }

  Future<void> dismiss(Iterable<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_dismissedKeysKey) ?? const <String>[];
    // Preserve order (oldest first), append new keys, drop duplicates.
    final merged = <String>[...existing];
    for (final key in keys) {
      if (!merged.contains(key)) {
        merged.add(key);
      }
    }
    final trimmed = merged.length > _maxDismissedKeys
        ? merged.sublist(merged.length - _maxDismissedKeys)
        : merged;
    await prefs.setStringList(_dismissedKeysKey, trimmed);
  }

  /// Resets inbox state (last-seen + dismissed). Used when demo data is cleared
  /// so a re-seed surfaces its notifications as fresh/unread.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSeenKey);
    await prefs.remove(_dismissedKeysKey);
  }
}
