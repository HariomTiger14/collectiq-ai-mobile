/// Supported monetisation plan placeholders.
enum SubscriptionPlan {
  /// Free/local-first plan.
  free,

  /// Future paid plan.
  pro,

  /// Future paid plan with higher limits/features.
  premium;

  /// Human-readable label for Settings.
  String get displayName {
    return switch (this) {
      SubscriptionPlan.free => 'Free',
      SubscriptionPlan.pro => 'Pro',
      SubscriptionPlan.premium => 'Premium',
    };
  }

  /// Whether this plan can be purchased in the current build.
  bool get isAvailable => this == SubscriptionPlan.free;

  /// Settings label for purchase state.
  String get statusLabel => isAvailable ? 'Active' : 'Coming soon';

  /// Parses a stored plan name.
  static SubscriptionPlan fromName(String? value) {
    return SubscriptionPlan.values.firstWhere(
      (plan) => plan.name == value,
      orElse: () => SubscriptionPlan.free,
    );
  }
}
