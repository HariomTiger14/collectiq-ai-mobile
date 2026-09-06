import 'package:collectiq_ai/core/ui/currency_format.dart';
import 'package:collectiq_ai/features/price_alerts/data/repositories/supabase_price_alert_repository.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_providers.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A card PriceCharting prices at USD 100, with AUD worth half a USD.
  final item = CollectibleItem(
    id: 'item-1',
    title: 'Charizard',
    category: 'Pokemon Cards',
    estimatedValue: 100,
    confidence: 0.9,
    condition: 'Near mint',
    recommendation: '',
    imagePath: '',
    createdAt: DateTime(2026, 9, 6),
    pricing: const PricingInfo(
      estimatedMarketValue: 100,
      lowEstimate: 90,
      highEstimate: 110,
      currency: 'USD',
      pricingSource: 'PriceCharting',
      pricingConfidence: 0.9,
      lastUpdated: null,
    ),
  );
  const rates = {'USD': 1.0, 'AUD': 2.0};

  test('an alert records the collector intent and the USD comparison', () {
    final alert = buildPriceAlert(
      item: item,
      type: PriceAlertRuleType.priceRisesAboveAmount,
      displayCurrency: 'AUD',
      currentRates: rates,
    );

    // The collector is looking at AUD 200, so "rises above" means AUD 220.
    expect(alert.rule.amount, closeTo(220, 0.001));
    expect(alert.rule.displayCurrency, 'AUD');
    // The server compares against a USD price, so it needs USD 110.
    expect(alert.rule.normalizedAmountUsd, closeTo(110, 0.001));
    expect(alert.rule.exchangeRateUsed, closeTo(0.5, 0.001));
    expect(alert.rule.exchangeRateDate, isNotNull);
  });

  test('the row sends the USD figure for comparison, not the intent', () {
    final alert = buildPriceAlert(
      item: item,
      type: PriceAlertRuleType.priceRisesAboveAmount,
      displayCurrency: 'AUD',
      currentRates: rates,
    );

    final row = supabaseRowForPriceAlert(alert, 'user-1');

    // Comparing AUD 220 against a USD 100 price would never fire correctly.
    expect(row['target_amount'], closeTo(110, 0.001));
    final rule = (row['raw_json'] as Map)['rule'] as Map;
    expect(rule['amount'], closeTo(220, 0.001));
    expect(rule['displayCurrency'], 'AUD');
  });

  test('the intent survives a round trip through Supabase', () {
    final alert = buildPriceAlert(
      item: item,
      type: PriceAlertRuleType.priceDropsBelowAmount,
      displayCurrency: 'AUD',
      currentRates: rates,
    );

    final restored = priceAlertFromSupabaseRow(
      supabaseRowForPriceAlert(alert, 'user-1'),
    );

    expect(restored, isNotNull);
    expect(restored!.rule.amount, closeTo(180, 0.001));
    expect(restored.rule.displayCurrency, 'AUD');
    expect(restored.rule.normalizedAmountUsd, closeTo(90, 0.001));
  });

  test('an alert created before currencies were tracked reads as AUD', () {
    const legacy = PriceAlertRule(
      type: PriceAlertRuleType.priceRisesAboveAmount,
      amount: 50,
    );

    expect(legacy.effectiveDisplayCurrency, 'AUD');
    // With nothing normalized, the entered amount is the comparison value --
    // which is right, because both it and the item were AUD then.
    expect(legacy.comparisonAmountUsd, 50);
  });

  test('no rate available leaves the threshold in the item currency', () {
    final alert = buildPriceAlert(
      item: item,
      type: PriceAlertRuleType.priceRisesAboveAmount,
      displayCurrency: 'AUD',
      currentRates: const {},
    );

    // Nothing could be converted, so the threshold is the item's own USD 110
    // and must say USD. Calling it AUD would be the original bug in
    // miniature: a number labelled with a currency it is not in.
    expect(alert.rule.amount, closeTo(110, 0.001));
    expect(alert.rule.displayCurrency, 'USD');
    expect(alert.rule.effectiveDisplayCurrency, 'USD');
    // Recorded as a 1.0 identity rather than null: the threshold really is
    // the unconverted figure, and saying so is the point.
    expect(alert.rule.exchangeRateUsed, 1.0);
    expect(alert.rule.normalizedAmountUsd, closeTo(110, 0.001));
    expect(
      formatCollectionValue(alert.rule.amount!, currencyCode: 'USD'),
      'US\$110.00',
    );
  });
}
