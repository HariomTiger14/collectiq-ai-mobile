import 'dart:async';

import 'package:collectiq_ai/core/currency/fx_rate.dart';
import 'package:collectiq_ai/core/currency/fx_rates_cache.dart';
import 'package:collectiq_ai/core/currency/fx_rates_repository.dart';
import 'package:collectiq_ai/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The user's chosen display currency (Settings -> Country & Currency).
/// Defaults to AUD, matching CollectorProfile's own default -- see
/// collector_profile.dart.
final displayCurrencyProvider = Provider<String>((ref) {
  final profile = ref.watch(profileControllerProvider).value;
  return profile?.preferredCurrency ?? 'AUD';
});

/// Rates for converting stored values into the display currency.
///
/// Served from the device cache first when one exists, so a cold launch has
/// rates on the very first frame instead of a window where every amount has
/// to fall back to its own currency; the network refresh then runs in the
/// background and replaces them. Only the first ever launch, or a first
/// launch whose fetch fails, has no rates at all.
///
/// Falls back to `FxRateSnapshot.empty` (USD-only, 1:1) when there is
/// nothing cached and the fetch fails, so a network hiccup degrades to "no
/// conversion applied" rather than crashing a value display. Callers must
/// not label an unconverted amount with the display currency -- see
/// canConvertCurrent in currency_conversion.dart.
final fxRatesProvider =
    AsyncNotifierProvider<FxRatesController, FxRateSnapshot>(
      FxRatesController.new,
    );

class FxRatesController extends AsyncNotifier<FxRateSnapshot> {
  /// When the rates currently in [state] were fetched from the backend, or
  /// null if they did not come from the cache and no fetch has succeeded.
  DateTime? savedAt;

  @override
  Future<FxRateSnapshot> build() async {
    final cache = ref.watch(fxRatesCacheProvider);
    final cached = await cache.read();
    if (cached == null) {
      return _fetchAndStore(cache);
    }
    savedAt = cached.savedAt;
    // Serve what we have immediately and let the refresh land later. The
    // cached rates are already good enough to label amounts honestly, which
    // is the whole point of not waiting for the network here.
    unawaited(_refreshInBackground(cache));
    return cached.snapshot;
  }

  Future<FxRateSnapshot> _fetchAndStore(FxRatesCache cache) async {
    try {
      final fresh = await ref.read(fxRatesRepositoryProvider).fetchRates();
      await cache.write(fresh);
      savedAt = DateTime.now();
      return fresh;
    } catch (_) {
      return FxRateSnapshot.empty;
    }
  }

  Future<void> _refreshInBackground(FxRatesCache cache) async {
    try {
      final fresh = await ref.read(fxRatesRepositoryProvider).fetchRates();
      if (fresh.currentRates.length <= 1) {
        // An empty snapshot means the call failed upstream; keep the cached
        // rates rather than downgrading working conversions to none.
        return;
      }
      await cache.write(fresh);
      savedAt = DateTime.now();
      state = AsyncValue.data(fresh);
    } catch (_) {
      // Keep serving the cache: stale rates beat no rates.
    }
  }
}
