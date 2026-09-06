import 'dart:convert';

import 'package:collectiq_ai/core/currency/fx_rate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The last FX snapshot the backend returned, kept on the device.
///
/// Rates are fetched once per session over the network. Without a cache,
/// every cold launch has a window where no rate exists, and a failed fetch
/// leaves the whole session with none -- which is why value displays have
/// to fall back to their source currency. A stored snapshot closes that
/// window to first run only, and survives a fetch that fails outright.
///
/// Stale rates are still served: a rate from yesterday converts far better
/// than no rate at all, and a background refresh replaces it as soon as the
/// network answers. [savedAt] is recorded so a caller can tell how old the
/// figures behind a conversion are.
class FxRatesCache {
  const FxRatesCache();

  static const _snapshotKey = 'packlox.fx_rates.snapshot.v1';
  static const _savedAtKey = 'packlox.fx_rates.saved_at.v1';

  Future<({FxRateSnapshot snapshot, DateTime savedAt})?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_snapshotKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final snapshot = FxRateSnapshot.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      // A snapshot with nothing but the implicit USD row is no better than
      // having no cache: serving it would let a caller believe rates exist.
      if (snapshot.currentRates.length <= 1) {
        return null;
      }
      final savedAt =
          DateTime.tryParse(preferences.getString(_savedAtKey) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return (snapshot: snapshot, savedAt: savedAt);
    } catch (_) {
      // A cache we cannot parse is a cache we do not have.
      return null;
    }
  }

  Future<void> write(FxRateSnapshot snapshot, {DateTime? savedAt}) async {
    if (snapshot.currentRates.length <= 1) {
      // Never overwrite real rates with the empty fallback a failed fetch
      // returns -- that would turn one bad response into a lasting one.
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_snapshotKey, jsonEncode(snapshot.toJson()));
    await preferences.setString(
      _savedAtKey,
      (savedAt ?? DateTime.now()).toIso8601String(),
    );
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_snapshotKey);
    await preferences.remove(_savedAtKey);
  }
}

final fxRatesCacheProvider = Provider<FxRatesCache>((ref) {
  return const FxRatesCache();
});
