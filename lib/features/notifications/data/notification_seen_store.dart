import 'package:shared_preferences/shared_preferences.dart';

/// Persists when the notification inbox was last opened so the bell badge can
/// count only notifications newer than the last visit.
class NotificationSeenStore {
  const NotificationSeenStore();

  static const _lastSeenKey = 'notifications_last_seen_at';

  Future<DateTime?> lastSeenAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSeenKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> markSeen(DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenKey, at.toIso8601String());
  }
}
