/// Stores local scan usage counters.
abstract interface class UsageRepository {
  /// Loads today's usage.
  Future<int> scansUsedToday();

  /// Increments successful analysis usage and returns the new tracker.
  Future<int> incrementScansUsedToday();

  /// Loads this month's manual price refresh usage.
  Future<int> priceRefreshesUsedThisMonth();

  /// Increments manual price refresh usage and returns the new count.
  Future<int> incrementPriceRefreshesThisMonth();

  /// Resets local usage counters.
  Future<void> resetUsage();
}
