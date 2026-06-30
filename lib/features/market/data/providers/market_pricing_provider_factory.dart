import 'package:collectiq_ai/features/market/data/providers/mock_market_pricing_provider.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_pricing_request.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_pricing_result.dart';
import 'package:collectiq_ai/features/market/domain/repositories/market_pricing_provider.dart';

/// Future pricing provider choices.
enum MarketPricingProviderType {
  mock,
  ebayCompletedSales,
  tcgplayer,
  priceCharting,
  customBackend,
}

/// Creates market-pricing providers.
class MarketPricingProviderFactory {
  /// Creates a market-pricing provider factory.
  const MarketPricingProviderFactory();

  /// Builds a provider for the requested pricing source.
  MarketPricingProvider create({
    MarketPricingProviderType provider = MarketPricingProviderType.mock,
  }) {
    return switch (provider) {
      MarketPricingProviderType.mock => const MockMarketPricingProvider(),
      MarketPricingProviderType.ebayCompletedSales =>
        const _PlaceholderMarketPricingProvider(
          providerName: 'eBay completed sales',
        ),
      MarketPricingProviderType.tcgplayer =>
        const _PlaceholderMarketPricingProvider(providerName: 'TCGplayer'),
      MarketPricingProviderType.priceCharting =>
        const _PlaceholderMarketPricingProvider(providerName: 'PriceCharting'),
      MarketPricingProviderType.customBackend =>
        const _PlaceholderMarketPricingProvider(
          providerName: 'custom backend pricing',
        ),
    };
  }
}

class _PlaceholderMarketPricingProvider implements MarketPricingProvider {
  const _PlaceholderMarketPricingProvider({required this.providerName});

  final String providerName;

  @override
  Future<MarketPricingResult> price(MarketPricingRequest request) async {
    throw MarketPricingException(
      '$providerName pricing is not enabled yet. Live pricing APIs must run through the CollectIQ AI backend.',
    );
  }
}
