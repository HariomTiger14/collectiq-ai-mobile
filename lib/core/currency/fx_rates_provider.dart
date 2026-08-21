import 'package:collectiq_ai/core/currency/fx_rate.dart';
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

/// Fetched once per app session and cached (`keepAlive`) -- currency
/// doesn't move fast enough for collectibles to need refetching on every
/// screen build. Covers the last 2 years by default (the backend's own
/// default range), enough for every chart period the app currently offers.
/// Falls back to `FxRateSnapshot.empty` (USD-only, 1:1) on any failure so a
/// network hiccup degrades to "no conversion applied" rather than crashing
/// a value display.
final fxRatesProvider = FutureProvider<FxRateSnapshot>((ref) async {
  final repository = ref.watch(fxRatesRepositoryProvider);
  try {
    return await repository.fetchRates();
  } catch (_) {
    return FxRateSnapshot.empty;
  }
});
