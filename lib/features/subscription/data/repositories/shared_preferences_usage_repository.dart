import 'package:collectiq_ai/features/subscription/domain/repositories/usage_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local SharedPreferences implementation for scan usage.
class SharedPreferencesUsageRepository implements UsageRepository {
  /// Creates a local usage repository.
  const SharedPreferencesUsageRepository();

  static const _usageDateKey = 'subscription_usage_date';
  static const _scansUsedKey = 'subscription_scans_used_today';

  @override
  Future<int> scansUsedToday() async {
    final preferences = await SharedPreferences.getInstance();
    await _resetIfNewDay(preferences);
    return preferences.getInt(_scansUsedKey) ?? 0;
  }

  @override
  Future<int> incrementScansUsedToday() async {
    final preferences = await SharedPreferences.getInstance();
    await _resetIfNewDay(preferences);
    final nextValue = (preferences.getInt(_scansUsedKey) ?? 0) + 1;
    await preferences.setInt(_scansUsedKey, nextValue);
    return nextValue;
  }

  @override
  Future<void> resetUsage() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_usageDateKey, _todayKey());
    await preferences.setInt(_scansUsedKey, 0);
  }

  Future<void> _resetIfNewDay(SharedPreferences preferences) async {
    final today = _todayKey();
    if (preferences.getString(_usageDateKey) == today) {
      return;
    }

    await preferences.setString(_usageDateKey, today);
    await preferences.setInt(_scansUsedKey, 0);
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
