import 'package:collectiq_ai/features/market/domain/entities/market_pricing_request.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_pricing_result.dart';

/// Provider boundary for future market pricing and valuation data.
abstract interface class MarketPricingProvider {
  /// Returns market pricing for a recognized collectible.
  Future<MarketPricingResult> price(MarketPricingRequest request);
}

/// User-safe pricing-provider exception.
class MarketPricingException implements Exception {
  /// Creates a pricing exception.
  const MarketPricingException(this.message);

  /// Message safe to show or log without secrets.
  final String message;

  @override
  String toString() => 'MarketPricingException: $message';
}
