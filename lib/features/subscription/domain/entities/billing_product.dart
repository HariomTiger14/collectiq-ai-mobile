import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';

/// Google Play Billing product metadata normalized for Settings.
class BillingProduct {
  /// Creates a billing product.
  const BillingProduct({
    required this.id,
    required this.plan,
    required this.title,
    required this.description,
    required this.price,
    this.currencyCode,
    this.isAvailable = true,
  });

  /// Google Play product id.
  final String id;

  /// Plan unlocked by this product.
  final SubscriptionPlan plan;

  /// Product title from Play Console.
  final String title;

  /// Product description from Play Console.
  final String description;

  /// Localized price from Play Billing.
  final String price;

  /// ISO currency code when available.
  final String? currencyCode;

  /// Whether this product can currently be purchased.
  final bool isAvailable;
}
