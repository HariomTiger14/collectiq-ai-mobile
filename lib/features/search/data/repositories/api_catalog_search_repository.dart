import 'package:collectiq_ai/core/network/api_client.dart';
import 'package:collectiq_ai/core/network/api_constants.dart';
import 'package:collectiq_ai/features/search/domain/entities/catalog_search_result.dart';
import 'package:collectiq_ai/features/search/domain/repositories/catalog_search_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides catalog search backed by the PackLox API.
final catalogSearchRepositoryProvider = Provider<CatalogSearchRepository>((
  ref,
) {
  return ApiCatalogSearchRepository(ref.watch(apiClientProvider));
});

/// API-backed catalog search repository.
class ApiCatalogSearchRepository implements CatalogSearchRepository {
  /// Creates an API-backed catalog repository.
  const ApiCatalogSearchRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<CatalogSearchResult>> searchCatalog({
    required String query,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.pricingCatalogSearchPath,
      queryParameters: {'q': query, 'limit': limit},
    );
    final data = response.data;
    final rows = switch (data) {
      {'results': final List<dynamic> results} => results,
      {'items': final List<dynamic> items} => items,
      final List<dynamic> list => list,
      _ => const <dynamic>[],
    };
    return rows
        .whereType<Map<String, dynamic>>()
        .map(CatalogSearchResult.fromJson)
        .toList(growable: false);
  }
}
