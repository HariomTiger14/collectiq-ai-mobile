import 'package:collectiq_ai/features/search/domain/entities/catalog_search_result.dart';

/// Repository boundary for PackLox catalog search.
abstract class CatalogSearchRepository {
  /// Searches the backend pricing/catalog index.
  Future<List<CatalogSearchResult>> searchCatalog({
    required String query,
    int limit = 20,
  });
}
