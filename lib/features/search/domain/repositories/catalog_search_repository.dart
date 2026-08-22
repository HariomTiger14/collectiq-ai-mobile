import 'package:collectiq_ai/features/search/domain/entities/catalog_search_result.dart';

/// Repository boundary for PackLox catalog search.
abstract class CatalogSearchRepository {
  /// Searches the backend pricing/catalog index.
  ///
  /// [categoryGroup] narrows to one of the backend's curated top-level
  /// category groups (sports-cards/trading-card-games/comics/funko-pops/
  /// lego-sets/coins/video-games) -- same taxonomy as the admin Catalog
  /// screen. [subcategory] drills further within categories that have one:
  /// a sport (baseball/basketball/football/hockey/soccer) under
  /// sports-cards, a game (magic/pokemon/yugioh/lorcana) under
  /// trading-card-games, or a platform (playstation/xbox/nintendo/sega/
  /// atari/pc/retro-other) under video-games -- video-games with no
  /// subcategory means any platform. [minPrice]/[maxPrice] filter by price
  /// range. [source] restricts to a single provider ('pricecharting' or
  /// 'kicksdb'); omitting it searches both, merged and re-ranked together
  /// as today.
  Future<List<CatalogSearchResult>> searchCatalog({
    required String query,
    int limit = 20,
    String? categoryGroup,
    String? subcategory,
    double? minPrice,
    double? maxPrice,
    String? source,
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
