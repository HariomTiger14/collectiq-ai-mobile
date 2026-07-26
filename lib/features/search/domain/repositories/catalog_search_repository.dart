import 'package:collectiq_ai/features/search/domain/entities/catalog_search_result.dart';

/// Repository boundary for PackLox catalog search.
abstract class CatalogSearchRepository {
  /// Searches the backend pricing/catalog index.
  Future<List<CatalogSearchResult>> searchCatalog({
    required String query,
    int limit = 20,
  });

  /// Loads a catalog item with richer detail/history when available.
  Future<CatalogSearchResult> getCatalogDetail({
    required CatalogSearchResult result,
    int historyLimit = 30,
  });
}
