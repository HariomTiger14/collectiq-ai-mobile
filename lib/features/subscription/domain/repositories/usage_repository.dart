/// Stores local scan usage counters.
abstract interface class UsageRepository {
  /// Loads today's usage.
  Future<int> scansUsedToday();

  /// Increments successful analysis usage and returns the new tracker.
  Future<int> incrementScansUsedToday();

  /// Resets local usage counters.
  Future<void> resetUsage();
}
