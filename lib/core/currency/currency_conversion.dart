import 'package:collectiq_ai/core/currency/fx_rate.dart';

/// Pure conversion arithmetic -- the client-side mirror of
/// app/services/pricing/currency_conversion.py's `_exchange_rate`. Never
/// invents a rate: every number here comes from `FxRateSnapshot`, which is
/// fetched from the backend (currency_conversion.py's own source of
/// truth), never computed independently.
///
/// `usdRate` convention throughout: units of `currency` per 1 USD (matches
/// the backend's fx_rates_daily table and _usd_rate()).

/// Converts `value` from `from` to `to` using each currency's most CURRENT
/// rate -- for live totals (Home hero, Portfolio total, Detail value),
/// never for historical chart points (use [convertHistorical] instead).
double convertCurrent(
  double value, {
  required String from,
  required String to,
  required Map<String, double> currentRates,
}) {
  final fromCode = from.trim().toUpperCase();
  final toCode = to.trim().toUpperCase();
  if (fromCode == toCode) {
    return value;
  }
  final usdToTarget = currentRates[toCode] ?? 1.0;
  final usdToSource = currentRates[fromCode] ?? 1.0;
  if (usdToSource == 0) {
    return value;
  }
  return value * (usdToTarget / usdToSource);
}

/// Converts `value` from `from` to `to` using the rate that was actually in
/// effect ON `date` -- for historical chart points, so switching currency
/// doesn't distort the chart's shape by applying today's rate backward.
/// Falls back to `currentRates` for a currency/date this snapshot has no
/// historical row for (e.g. before the daily backfill started), same
/// graceful-degradation posture as the backend's own static-rate fallback.
double convertHistorical(
  double value, {
  required String from,
  required String to,
  required DateTime date,
  required FxRateSnapshot rates,
}) {
  final fromCode = from.trim().toUpperCase();
  final toCode = to.trim().toUpperCase();
  if (fromCode == toCode) {
    return value;
  }
  final usdToSource = _rateOnOrBefore(rates, fromCode, date) ?? rates.currentRates[fromCode] ?? 1.0;
  final usdToTarget = _rateOnOrBefore(rates, toCode, date) ?? rates.currentRates[toCode] ?? 1.0;
  if (usdToSource == 0) {
    return value;
  }
  return value * (usdToTarget / usdToSource);
}

/// The most recent stored rate for `currency` on or before `date` -- the
/// standard "most recent earlier date" convention for weekends/holidays a
/// market didn't publish a rate for (matches
/// fx_rate_service.py's `get_rate`). `history` is sorted ascending by date
/// (guaranteed by `FxRateSnapshot.fromJson`), so this scans from the end.
double? _rateOnOrBefore(FxRateSnapshot rates, String currency, DateTime date) {
  if (currency == 'USD') {
    return 1.0;
  }
  for (var i = rates.history.length - 1; i >= 0; i--) {
    final rate = rates.history[i];
    if (rate.currency == currency && !rate.date.isAfter(date)) {
      return rate.usdRate;
    }
  }
  return null;
}
