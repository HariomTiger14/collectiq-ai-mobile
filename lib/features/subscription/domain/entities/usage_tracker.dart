import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';

/// Usage state for monthly scan limits. Mirrors the same monthly-window
/// pattern used for price refreshes, and the server-side monthly cap that
/// actually enforces the quota on /analyze.
class UsageTracker {
  /// Creates immutable usage state.
  const UsageTracker({
    required this.scansUsedThisMonth,
    required this.monthlyFreeScanLimit,
    required this.remainingScans,
    required this.resetAt,
    required this.isUnlimited,
  });

  /// Builds a tracker snapshot from a limit and used count.
  factory UsageTracker.fromLimit({
    required UsageLimit limit,
    required int scansUsedThisMonth,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final normalizedUsed = scansUsedThisMonth < 0 ? 0 : scansUsedThisMonth;
    final remaining = limit.isUnlimited
        ? limit.monthlyFreeScanLimit
        : (limit.monthlyFreeScanLimit - normalizedUsed).clamp(0, 1 << 30);

    return UsageTracker(
      scansUsedThisMonth: normalizedUsed,
      monthlyFreeScanLimit: limit.monthlyFreeScanLimit,
      remainingScans: remaining,
      resetAt: DateTime(currentTime.year, currentTime.month + 1),
      isUnlimited: limit.isUnlimited,
    );
  }

  /// Number of successful analyses so far this calendar month.
  final int scansUsedThisMonth;

  /// Monthly free scan limit.
  final int monthlyFreeScanLimit;

  /// Remaining scans before the limit is reached.
  final int remainingScans;

  /// Local date/time when the monthly limit resets.
  final DateTime resetAt;

  /// Whether the current environment allows unlimited scanning.
  final bool isUnlimited;

  /// Whether another analysis is allowed.
  bool get canAnalyze => isUnlimited || remainingScans > 0;
}
