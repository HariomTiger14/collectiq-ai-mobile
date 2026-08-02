import 'package:collectiq_ai/core/ui/currency_format.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CollectibleItem valued(String id, {required String currency, double value = 100}) {
    return CollectibleItem(
      id: id,
      title: id,
      category: 'Pokemon',
      estimatedValue: value,
      confidence: 90,
      condition: 'Near Mint',
      recommendation: '',
      imagePath: '',
      createdAt: DateTime(2026, 1, 1),
      valuationStatus: ValuationStatus.marketEstimated,
      pricing: PricingInfo(
        estimatedMarketValue: value,
        lowEstimate: value,
        highEstimate: value,
        currency: currency,
        pricingSource: 'test',
        pricingConfidence: 90,
        lastUpdated: DateTime(2026, 1, 1),
        valuationStatus: ValuationStatus.marketEstimated,
      ),
    );
  }

  group('formatCollectionValue', () {
    test('AUD renders as a bare \$ with thousands separators', () {
      expect(formatCollectionValue(2275, currencyCode: 'AUD'), '\$2,275');
      expect(formatCollectionValue(0), '\$0');
      expect(formatCollectionValue(196538), '\$196,538');
    });

    test('empty currency defaults to bare \$ (AUD)', () {
      expect(formatCollectionValue(350, currencyCode: ''), '\$350');
    });

    test('non-AUD currencies get a disambiguating prefix', () {
      expect(formatCollectionValue(2275, currencyCode: 'USD'), 'US\$2,275');
      expect(formatCollectionValue(2275, currencyCode: 'CAD'), 'C\$2,275');
      expect(formatCollectionValue(2275, currencyCode: 'GBP'), '£2,275');
      expect(formatCollectionValue(2275, currencyCode: 'EUR'), '€2,275');
      expect(formatCollectionValue(1000, currencyCode: 'CHF'), 'CHF 1,000');
    });

    test('never fabricates conversion — amount is passed through verbatim', () {
      // Same numeric amount, only the label changes with the currency.
      expect(formatCollectionValue(500, currencyCode: 'USD'), 'US\$500');
      expect(formatCollectionValue(500, currencyCode: 'AUD'), '\$500');
    });

    test('optional decimals', () {
      expect(
        formatCollectionValue(1234.5, currencyCode: 'AUD', showDecimals: true),
        '\$1,234.50',
      );
    });
  });

  group('dominantDisplayCurrency', () {
    test('returns the most common valued-item currency', () {
      final items = [
        valued('a', currency: 'USD'),
        valued('b', currency: 'USD'),
        valued('c', currency: 'AUD'),
      ];
      expect(dominantDisplayCurrency(items), 'USD');
    });

    test('ignores unvalued items and falls back when nothing is valued', () {
      final unvalued = CollectibleItem(
        id: 'x',
        title: 'x',
        category: 'Pokemon',
        estimatedValue: 0,
        confidence: 0,
        condition: 'Unknown',
        recommendation: '',
        imagePath: '',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(dominantDisplayCurrency([unvalued]), 'AUD');
      expect(dominantDisplayCurrency(const []), 'AUD');
      expect(dominantDisplayCurrency(const [], fallback: 'gbp'), 'GBP');
    });
  });

  group('currencyForItem', () {
    test('uses the item pricing currency, AUD fallback', () {
      expect(currencyForItem(valued('a', currency: 'USD')), 'USD');
    });
  });
}
