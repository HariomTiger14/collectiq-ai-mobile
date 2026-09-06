import 'dart:async';
import 'package:collectiq_ai/core/currency/fx_rate.dart';
import 'package:collectiq_ai/core/currency/fx_rates_cache.dart';
import 'package:collectiq_ai/core/currency/fx_rates_provider.dart';
import 'package:collectiq_ai/core/currency/fx_rates_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final rates = FxRateSnapshot(
    currentRates: const {'USD': 1.0, 'AUD': 1.52},
    history: [
      FxRate(date: DateTime.utc(2026, 9, 1), currency: 'AUD', usdRate: 1.5),
    ],
  );

  group('FxRatesCache', () {
    test('round-trips a snapshot through the wire parser', () async {
      const cache = FxRatesCache();
      await cache.write(rates, savedAt: DateTime.utc(2026, 9, 5));

      final restored = await cache.read();

      expect(restored, isNotNull);
      expect(restored!.snapshot.currentRates['AUD'], 1.52);
      expect(restored.snapshot.history.single.usdRate, 1.5);
      expect(restored.savedAt, DateTime.utc(2026, 9, 5));
    });

    test('reads nothing when there is no cache', () async {
      expect(await const FxRatesCache().read(), isNull);
    });

    test('refuses to store the empty fallback over real rates', () async {
      const cache = FxRatesCache();
      await cache.write(rates);

      await cache.write(FxRateSnapshot.empty);

      final restored = await cache.read();
      expect(restored!.snapshot.currentRates['AUD'], 1.52);
    });

    test('treats a corrupt entry as no cache at all', () async {
      SharedPreferences.setMockInitialValues({
        'packlox.fx_rates.snapshot.v1': 'not json',
      });

      expect(await const FxRatesCache().read(), isNull);
    });
  });

  group('fxRatesProvider', () {
    test('serves cached rates without waiting for the network', () async {
      await const FxRatesCache().write(rates);
      final repository = _SlowFxRatesRepository();
      final container = ProviderContainer(
        overrides: [fxRatesRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final served = await container.read(fxRatesProvider.future);

      // The fetch is still in flight; the cache answered first.
      expect(repository.completer.isCompleted, isFalse);
      expect(served.currentRates['AUD'], 1.52);

      repository.completer.complete(
        const FxRateSnapshot(
          currentRates: {'USD': 1.0, 'AUD': 1.60},
          history: [],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(fxRatesProvider).value!.currentRates['AUD'], 1.60);
    });

    test('keeps cached rates when the refresh fails', () async {
      await const FxRatesCache().write(rates);
      final container = ProviderContainer(
        overrides: [
          fxRatesRepositoryProvider.overrideWithValue(
            _FailingFxRatesRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(fxRatesProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(fxRatesProvider).value!.currentRates['AUD'], 1.52);
    });

    test('falls back to empty on a first launch that cannot fetch', () async {
      final container = ProviderContainer(
        overrides: [
          fxRatesRepositoryProvider.overrideWithValue(
            _FailingFxRatesRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final served = await container.read(fxRatesProvider.future);

      expect(served.currentRates.containsKey('AUD'), isFalse);
    });
  });
}

class _SlowFxRatesRepository implements FxRatesRepository {
  final completer = Completer<FxRateSnapshot>();

  @override
  Future<FxRateSnapshot> fetchRates({DateTime? fromDate, DateTime? toDate}) {
    return completer.future;
  }
}

class _FailingFxRatesRepository implements FxRatesRepository {
  @override
  Future<FxRateSnapshot> fetchRates({DateTime? fromDate, DateTime? toDate}) {
    throw StateError('offline');
  }
}
