/// Monthly scan usage policy for a plan. Matches the server-side monthly cap
/// enforced on /analyze (see SUBSCRIPTION_FREE_MONTHLY_SCAN_LIMIT).
class UsageLimit {
  /// Creates an immutable usage limit.
  const UsageLimit({
    required this.monthlyFreeScanLimit,
    this.isUnlimited = false,
  });

  /// Development-safe unlimited limit.
  static const unlimited = UsageLimit(
    monthlyFreeScanLimit: 9999,
    isUnlimited: true,
  );

  /// Number of free scans allowed per local calendar month.
  final int monthlyFreeScanLimit;

  /// Whether usage checks should never block scans.
  final bool isUnlimited;

  /// Creates a copy with updated values.
  UsageLimit copyWith({int? monthlyFreeScanLimit, bool? isUnlimited}) {
    return UsageLimit(
      monthlyFreeScanLimit: monthlyFreeScanLimit ?? this.monthlyFreeScanLimit,
      isUnlimited: isUnlimited ?? this.isUnlimited,
    );
  }
}
