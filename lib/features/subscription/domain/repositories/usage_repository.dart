/// Stores local scan usage counters.
abstract interface class UsageRepository {
  /// Loads this month's scan usage.
  Future<int> scansUsedThisMonth();

  /// Increments successful analysis usage and returns the new count.
  Future<int> incrementScansUsedThisMonth();

  /// Loads this month's manual price refresh usage.
  Future<int> priceRefreshesUsedThisMonth();

  /// Increments manual price refresh usage and returns the new count.
  Future<int> incrementPriceRefreshesThisMonth();

  /// Resets local usage counters.
  Future<void> resetUsage();
}
