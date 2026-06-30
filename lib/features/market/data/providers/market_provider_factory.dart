import 'package:collectiq_ai/features/market/data/providers/mock_market_provider.dart';
import 'package:collectiq_ai/features/market/domain/repositories/market_provider.dart';

enum MarketProviderType { mock, ebay, tcgplayer, priceCharting, psa, comc }

class MarketProviderFactory {
  const MarketProviderFactory();

  MarketProvider create({
    MarketProviderType provider = MarketProviderType.mock,
  }) {
    return switch (provider) {
      MarketProviderType.mock => const MockMarketProvider(),
      MarketProviderType.ebay => throw UnsupportedError(
        'eBay market provider is prepared but not implemented.',
      ),
      MarketProviderType.tcgplayer => throw UnsupportedError(
        'TCGplayer market provider is prepared but not implemented.',
      ),
      MarketProviderType.priceCharting => throw UnsupportedError(
        'PriceCharting market provider is prepared but not implemented.',
      ),
      MarketProviderType.psa => throw UnsupportedError(
        'PSA market provider is prepared but not implemented.',
      ),
      MarketProviderType.comc => throw UnsupportedError(
        'COMC market provider is prepared but not implemented.',
      ),
    };
  }
}
