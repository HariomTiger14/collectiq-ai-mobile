import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';

/// Usage state for daily scan limits.
class UsageTracker {
  /// Creates immutable usage state.
  const UsageTracker({
    required this.scansUsedToday,
    required this.dailyFreeScanLimit,
    required this.remainingScans,
    required this.resetAt,
    required this.isUnlimited,
  });

  /// Builds a tracker snapshot from a limit and used count.
  factory UsageTracker.fromLimit({
    required UsageLimit limit,
    required int scansUsedToday,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final normalizedUsed = scansUsedToday < 0 ? 0 : scansUsedToday;
    final remaining = limit.isUnlimited
        ? limit.dailyFreeScanLimit
        : (limit.dailyFreeScanLimit - normalizedUsed).clamp(0, 1 << 30);

    return UsageTracker(
      scansUsedToday: normalizedUsed,
      dailyFreeScanLimit: limit.dailyFreeScanLimit,
      remainingScans: remaining,
      resetAt: DateTime(
        currentTime.year,
        currentTime.month,
        currentTime.day + 1,
      ),
      isUnlimited: limit.isUnlimited,
    );
  }

  /// Number of successful analyses today.
  final int scansUsedToday;

  /// Daily free scan limit.
  final int dailyFreeScanLimit;

  /// Remaining scans before the limit is reached.
  final int remainingScans;

  /// Local date/time when the daily limit resets.
  final DateTime resetAt;

  /// Whether the current environment allows unlimited scanning.
  final bool isUnlimited;

  /// Whether another analysis is allowed.
  bool get canAnalyze => isUnlimited || remainingScans > 0;
}
