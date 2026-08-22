import 'package:collectiq_ai/core/currency/currency_conversion.dart';
import 'package:collectiq_ai/core/currency/fx_rate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('convertCurrent', () {
    test('returns the same value when from and to match', () {
      final result = convertCurrent(
        100,
        from: 'AUD',
        to: 'AUD',
        currentRates: {'AUD': 1.52},
      );

      expect(result, 100);
    });

    test('converts AUD to USD using the current rate', () {
      // 1 USD = 1.52 AUD, so 152 AUD == 100 USD.
      final result = convertCurrent(
        152,
        from: 'AUD',
        to: 'USD',
        currentRates: {'USD': 1.0, 'AUD': 1.52},
      );

      expect(result, closeTo(100, 0.0001));
    });

    test('converts between two non-USD currencies via the USD cross rate', () {
      final result = convertCurrent(
        152,
        from: 'AUD',
        to: 'GBP',
        currentRates: {'USD': 1.0, 'AUD': 1.52, 'GBP': 0.78},
      );

      // 152 AUD -> 100 USD -> 78 GBP.
      expect(result, closeTo(78, 0.0001));
    });

    test('is lowercase/whitespace tolerant', () {
      final result = convertCurrent(
        100,
        from: ' aud ',
        to: 'usd',
        currentRates: {'USD': 1.0, 'AUD': 2.0},
      );

      expect(result, closeTo(50, 0.0001));
    });

    test('falls back to a 1.0 usdRate for a currency missing from the map', () {
      final result = convertCurrent(
        100,
        from: 'AUD',
        to: 'ZZZ',
        currentRates: {'AUD': 2.0},
      );

      // ZZZ has no entry -> treated as 1.0, i.e. as if it were USD.
      expect(result, closeTo(50, 0.0001));
    });
  });

  group('convertHistorical', () {
    final snapshot = FxRateSnapshot(
      currentRates: {'USD': 1.0, 'AUD': 1.60},
      history: [
        FxRate(date: DateTime(2026, 1, 1), currency: 'AUD', usdRate: 1.40),
        FxRate(date: DateTime(2026, 3, 1), currency: 'AUD', usdRate: 1.50),
      ],
    );

    test('returns the same value when from and to match', () {
      final result = convertHistorical(
        100,
        from: 'AUD',
        to: 'AUD',
        date: DateTime(2026, 2, 1),
        rates: snapshot,
      );

      expect(result, 100);
    });

    test('uses the rate in effect on the given date, not the current rate', () {
      // On 2026-02-15 the most recent stored AUD rate is the 2026-01-01
      // one (1.40), not the later 1.50 or the current 1.60.
      final result = convertHistorical(
        140,
        from: 'AUD',
        to: 'USD',
        date: DateTime(2026, 2, 15),
        rates: snapshot,
      );

      expect(result, closeTo(100, 0.0001));
    });

    test('picks the most recent rate on or before the date, not after', () {
      final result = convertHistorical(
        150,
        from: 'AUD',
        to: 'USD',
        date: DateTime(2026, 3, 15),
        rates: snapshot,
      );

      expect(result, closeTo(100, 0.0001));
    });

    test('falls back to the current rate when no historical row exists yet', () {
      final noHistory = FxRateSnapshot(
        currentRates: {'USD': 1.0, 'AUD': 1.60},
        history: const [],
      );

      final result = convertHistorical(
        160,
        from: 'AUD',
        to: 'USD',
        date: DateTime(2020, 1, 1),
        rates: noHistory,
      );

      expect(result, closeTo(100, 0.0001));
    });

    test('treats USD as always 1.0 even with no stored USD rows', () {
      final result = convertHistorical(
        100,
        from: 'USD',
        to: 'AUD',
        date: DateTime(2026, 2, 1),
        rates: snapshot,
      );

      expect(result, closeTo(140, 0.0001));
    });
  });
}
