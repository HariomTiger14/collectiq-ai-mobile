import 'package:collectiq_ai/core/network/api_client.dart';
import 'package:collectiq_ai/core/network/api_constants.dart';
import 'package:collectiq_ai/core/network/api_result.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the portfolio API data source.
final portfolioApiProvider = Provider<PortfolioApi>((ref) {
  return PortfolioApi(ref.watch(apiClientProvider));
});

/// API data source for portfolio-related Azure backend operations.
class PortfolioApi {
  /// Creates a portfolio API with an injected API client.
  const PortfolioApi(this._apiClient);

  final ApiClient _apiClient;

  /// Returns a mocked remote portfolio item list.
  Future<ApiResult<List<CollectibleItem>>> getPortfolio() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final endpoint = '${_apiClient.baseUrl}${ApiConstants.portfolioPath}';

    if (endpoint.isEmpty) {
      return const ApiFailure(
        message: 'Portfolio request could not be prepared.',
        code: 'portfolio.invalid_endpoint',
      );
    }

    return const ApiSuccess(<CollectibleItem>[]);
  }

  /// Saves a portfolio item and returns the mocked saved item.
  Future<ApiResult<CollectibleItem>> savePortfolio(CollectibleItem item) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final endpoint = '${_apiClient.baseUrl}${ApiConstants.portfolioPath}';

    if (endpoint.isEmpty) {
      return const ApiFailure(
        message: 'Portfolio save request could not be prepared.',
        code: 'portfolio.save.invalid_endpoint',
      );
    }

    return ApiSuccess(item);
  }

  /// Deletes a portfolio item and returns a mocked success flag.
  Future<ApiResult<bool>> deleteItem(String itemId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final endpoint =
        '${_apiClient.baseUrl}${ApiConstants.portfolioItemPath}/$itemId';

    if (itemId.isEmpty || endpoint.isEmpty) {
      return const ApiFailure(
        message: 'Portfolio delete request could not be prepared.',
        code: 'portfolio.delete.invalid_item',
      );
    }

    return const ApiSuccess(true);
  }
}
