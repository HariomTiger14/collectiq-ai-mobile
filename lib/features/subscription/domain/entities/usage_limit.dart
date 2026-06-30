/// Daily scan usage policy for a plan.
class UsageLimit {
  /// Creates an immutable usage limit.
  const UsageLimit({
    required this.dailyFreeScanLimit,
    this.isUnlimited = false,
  });

  /// Development-safe unlimited limit.
  static const unlimited = UsageLimit(
    dailyFreeScanLimit: 9999,
    isUnlimited: true,
  );

  /// Number of free scans allowed per local day.
  final int dailyFreeScanLimit;

  /// Whether usage checks should never block scans.
  final bool isUnlimited;

  /// Creates a copy with updated values.
  UsageLimit copyWith({int? dailyFreeScanLimit, bool? isUnlimited}) {
    return UsageLimit(
      dailyFreeScanLimit: dailyFreeScanLimit ?? this.dailyFreeScanLimit,
      isUnlimited: isUnlimited ?? this.isUnlimited,
    );
  }
}
