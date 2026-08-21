/// A single day's FX rate: `usdRate` units of `currency` equal 1 USD.
/// Matches the backend's fx_rates_daily convention
/// (app/services/pricing/currency_conversion.py's `_usd_rate`).
class FxRate {
  const FxRate({required this.date, required this.currency, required this.usdRate});

  final DateTime date;
  final String currency;
  final double usdRate;

  static FxRate? fromJson(Map<String, dynamic> json) {
    final dateString = json['date'] as String?;
    final currency = json['currency'] as String?;
    final rate = json['usdRate'];
    if (dateString == null || currency == null || rate == null) {
      return null;
    }
    final date = DateTime.tryParse(dateString);
    final usdRate = (rate as num?)?.toDouble();
    if (date == null || usdRate == null) {
      return null;
    }
    return FxRate(date: date, currency: currency.toUpperCase(), usdRate: usdRate);
  }
}

/// Everything fetched from `GET /api/pricing/fx-rates` in one call: each
/// tracked currency's most current rate, plus the stored daily history used
/// to convert a historical chart point using the rate that was actually in
/// effect on that point's own date.
class FxRateSnapshot {
  const FxRateSnapshot({required this.currentRates, required this.history});

  final Map<String, double> currentRates;
  final List<FxRate> history;

  static const empty = FxRateSnapshot(currentRates: {'USD': 1.0}, history: []);

  static FxRateSnapshot fromJson(Map<String, dynamic> json) {
    final currentJson = json['current'];
    final current = <String, double>{'USD': 1.0};
    if (currentJson is Map) {
      for (final entry in currentJson.entries) {
        final rate = (entry.value as num?)?.toDouble();
        if (rate != null) {
          current[entry.key.toString().toUpperCase()] = rate;
        }
      }
    }
    final ratesJson = json['rates'];
    final history = <FxRate>[];
    if (ratesJson is List) {
      for (final row in ratesJson) {
        if (row is Map<String, dynamic>) {
          final rate = FxRate.fromJson(row);
          if (rate != null) {
            history.add(rate);
          }
        }
      }
    }
    history.sort((a, b) => a.date.compareTo(b.date));
    return FxRateSnapshot(currentRates: current, history: history);
  }
}
