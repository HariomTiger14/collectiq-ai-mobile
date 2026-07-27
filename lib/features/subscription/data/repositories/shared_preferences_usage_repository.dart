import 'package:collectiq_ai/features/subscription/domain/repositories/usage_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local SharedPreferences implementation for scan usage.
class SharedPreferencesUsageRepository implements UsageRepository {
  /// Creates a local usage repository.
  const SharedPreferencesUsageRepository();

  static const _usageDateKey = 'subscription_usage_date';
  static const _scansUsedKey = 'subscription_scans_used_today';
  static const _priceRefreshMonthKey = 'subscription_price_refresh_month';
  static const _priceRefreshesUsedKey =
      'subscription_price_refreshes_used_month';

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
  Future<int> priceRefreshesUsedThisMonth() async {
    final preferences = await SharedPreferences.getInstance();
    await _resetIfNewMonth(preferences);
    return preferences.getInt(_priceRefreshesUsedKey) ?? 0;
  }

  @override
  Future<int> incrementPriceRefreshesThisMonth() async {
    final preferences = await SharedPreferences.getInstance();
    await _resetIfNewMonth(preferences);
    final nextValue = (preferences.getInt(_priceRefreshesUsedKey) ?? 0) + 1;
    await preferences.setInt(_priceRefreshesUsedKey, nextValue);
    return nextValue;
  }

  @override
  Future<void> resetUsage() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_usageDateKey, _todayKey());
    await preferences.setInt(_scansUsedKey, 0);
    await preferences.setString(_priceRefreshMonthKey, _monthKey());
    await preferences.setInt(_priceRefreshesUsedKey, 0);
  }

  Future<void> _resetIfNewDay(SharedPreferences preferences) async {
    final today = _todayKey();
    if (preferences.getString(_usageDateKey) == today) {
      return;
    }

    await preferences.setString(_usageDateKey, today);
    await preferences.setInt(_scansUsedKey, 0);
  }

  Future<void> _resetIfNewMonth(SharedPreferences preferences) async {
    final month = _monthKey();
    if (preferences.getString(_priceRefreshMonthKey) == month) {
      return;
    }

    await preferences.setString(_priceRefreshMonthKey, month);
    await preferences.setInt(_priceRefreshesUsedKey, 0);
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  String _monthKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    return '${now.year}-$month';
  }
}
