import 'package:collectiq_ai/features/search/domain/entities/catalog_search_result.dart';

/// Repository boundary for PackLox catalog search.
abstract class CatalogSearchRepository {
  /// Searches the backend pricing/catalog index.
  Future<List<CatalogSearchResult>> searchCatalog({
    required String query,
    int limit = 20,
  });

  /// Loads a catalog item with richer detail/history when available.
  ///
  /// [historyLimit] defaults to the backend's own max (90, see
  /// GET /api/pricing/catalog/{id}) -- fetched once, in full, since 90
  /// small JSON rows is trivial payload. The detail screen only renders
  /// the 5 most recent inline (see _CatalogHistoryPanel); the rest powers
  /// the trend chart and the "View full price history" screen without a
  /// second network call.
  ///
  /// [currency] requests the backend convert pricing (and match eBay
  /// marketplace listings) to a specific display currency -- pass the
  /// user's CollectorProfile.preferredCurrency. Omitting it leaves prices
  /// in their raw source currency (USD), unconverted.
  Future<CatalogSearchResult> getCatalogDetail({
    required CatalogSearchResult result,
    int historyLimit = 90,
    String? currency,
  });
}
