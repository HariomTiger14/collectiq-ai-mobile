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
    test('every currency carries its ISO code', () {
      // One shape everywhere. The app used to render US$30.65, C$30.65, a
      // bare $30.65 for AUD, "$200 AUD" on Discover and "USD $200" on the
      // detail page -- five formats for one kind of value. Worse, "$" and
      // "US$" differ by two characters for currencies that differ by ~40%.
      expect(formatCollectionValue(30.65, currencyCode: 'USD'), 'USD \$30.65');
      expect(formatCollectionValue(30.65, currencyCode: 'AUD'), 'AUD \$30.65');
      expect(formatCollectionValue(30.65, currencyCode: 'CAD'), 'CAD \$30.65');
      expect(formatCollectionValue(30.65, currencyCode: 'GBP'), 'GBP £30.65');
    });

    test('thousands separators and zero', () {
      expect(
        formatCollectionValue(2275, currencyCode: 'AUD'),
        'AUD \$2,275.00',
      );
      expect(formatCollectionValue(0), 'AUD \$0.00');
      expect(
        formatCollectionValue(196538),
        'AUD \$196,538.00',
      );
    });

    test('empty currency renders a bare \$ rather than inventing a code', () {
      // Nothing said what this amount is in, so nothing here claims to know.
      expect(formatCollectionValue(350, currencyCode: ''), '\$350.00');
    });

    test('a currency with no symbol of its own still gets its code', () {
      expect(
        formatCollectionValue(1000, currencyCode: 'CHF'),
        'CHF \$1,000.00',
      );
      expect(formatCollectionValue(2275, currencyCode: 'EUR'), 'EUR €2,275.00');
      expect(formatCollectionValue(2275, currencyCode: 'JPY'), 'JPY ¥2,275.00');
    });

    test('never fabricates conversion — amount is passed through verbatim', () {
      // Same numeric amount, only the label changes with the currency.
      expect(formatCollectionValue(500, currencyCode: 'USD'), 'USD \$500.00');
      expect(formatCollectionValue(500, currencyCode: 'AUD'), 'AUD \$500.00');
    });

    test('decimals show exact cents, not rounded to whole dollars', () {
      // Regression: whole-dollar rounding on each displayed amount made
      // per-item prices not add up to the displayed total (e.g. $1.60 and
      // $39.60 individually rounded to $2 and $40, which looks like it
      // should sum to $42 even though the real total is $41.20).
      expect(
        formatCollectionValue(1234.5, currencyCode: 'AUD'),
        'AUD \$1,234.50',
      );
      expect(
        formatCollectionValue(1.6, currencyCode: 'AUD'),
        'AUD \$1.60',
      );
      expect(
        formatCollectionValue(39.6, currencyCode: 'AUD'),
        'AUD \$39.60',
      );
    });

    test('showDecimals: false still rounds to whole dollars when requested', () {
      expect(
        formatCollectionValue(1234.5, currencyCode: 'AUD', showDecimals: false),
        'AUD \$1,235',
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
