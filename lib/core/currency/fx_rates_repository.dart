import 'package:collectiq_ai/core/currency/fx_rate.dart';
import 'package:collectiq_ai/core/network/api_client.dart';
import 'package:collectiq_ai/core/network/api_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches FX rate history from the backend -- the single source of truth
/// for rates, per currency_conversion.py's own stated principle. The app
/// never invents its own rates; it only does the conversion arithmetic
/// locally using rates fetched from here.
abstract class FxRatesRepository {
  Future<FxRateSnapshot> fetchRates({DateTime? fromDate, DateTime? toDate});
}

final fxRatesRepositoryProvider = Provider<FxRatesRepository>((ref) {
  return ApiFxRatesRepository(ref.watch(apiClientProvider));
});

class ApiFxRatesRepository implements FxRatesRepository {
  const ApiFxRatesRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<FxRateSnapshot> fetchRates({DateTime? fromDate, DateTime? toDate}) async {
    final response = await _apiClient.get(
      ApiConstants.pricingFxRatesPath,
      queryParameters: {
        if (fromDate != null) 'fromDate': _dateOnly(fromDate),
        if (toDate != null) 'toDate': _dateOnly(toDate),
      },
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return FxRateSnapshot.empty;
    }
    return FxRateSnapshot.fromJson(data);
  }

  String _dateOnly(DateTime date) {
    final normalized = date.toUtc();
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
