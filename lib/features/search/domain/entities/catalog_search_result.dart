/// A searchable market/catalog result returned by the PackLox backend.
class CatalogSearchResult {
  /// Creates a catalog search result.
  const CatalogSearchResult({
    required this.id,
    required this.title,
    required this.category,
    required this.source,
    this.setName,
    this.identifier,
    this.currency = 'AUD',
    this.marketValue,
    this.lowEstimate,
    this.highEstimate,
    this.confidence,
    this.lastUpdated,
    this.attribution,
    this.reasonCode,
    this.displayMessage,
    this.imageUrl,
    this.productUrl,
    this.externalImageUrl,
    this.history = const <CatalogPriceHistoryPoint>[],
    this.marketplaceListings = const <MarketplaceListing>[],
    this.images = const <CatalogImage>[],
  });

  /// Stable catalog identifier.
  final String id;

  /// Human-readable item name.
  final String title;

  /// Catalog category, such as Pokemon Cards or Video Games.
  final String category;

  /// Source label, such as PriceCharting.
  final String source;

  /// Optional set, release, or product family.
  final String? setName;

  /// Optional SKU/card/product number.
  final String? identifier;

  /// Display currency.
  final String currency;

  /// Primary market value.
  final double? marketValue;

  /// Low market estimate.
  final double? lowEstimate;

  /// High market estimate.
  final double? highEstimate;

  /// Match confidence from 0 to 1.
  final double? confidence;

  /// Last time the backend refreshed this catalog row.
  final DateTime? lastUpdated;

  /// Required/desired attribution text.
  final String? attribution;

  /// Backend reason code when trusted pricing is unavailable.
  final String? reasonCode;

  /// Backend/user-safe message when trusted pricing is unavailable.
  final String? displayMessage;

  /// Real catalog product photo, when the source provides one (KicksDB
  /// today — PriceCharting's bulk catalog import has no image field).
  final String? imageUrl;

  /// Additional views of the same item, detail surfaces only. Empty for
  /// most items; populated where a source genuinely has several (sneaker
  /// galleries, coin obverse/reverse). When non-empty the first entry is
  /// the same photo as [imageUrl].
  final List<CatalogImage> images;

  /// The source's own product page URL for this item (e.g. PriceCharting),
  /// used to let users view the original listing outside the app.
  final String? productUrl;

  /// Link-only publisher-sourced card/product image URL (Funko/Pokemon/
  /// LEGO/Magic/Yu-Gi-Oh/Lorcana/One Piece), meant to be opened in an
  /// external/in-app browser tab -- never rendered inline via
  /// Image.network. Preferred over [productUrl] as a link target when
  /// present, since PriceCharting's own product page frequently has no
  /// image at all for these categories.
  final String? externalImageUrl;

  /// Observed catalog valuation history, newest first when supplied.
  final List<CatalogPriceHistoryPoint> history;

  /// Real, currently-available eBay listings for this item (top few
  /// results, already in [currency] -- the backend picks the eBay
  /// marketplace matching the requested display currency, so no further
  /// client-side conversion is needed). Empty when the marketplace
  /// listings feature is disabled, unmatched, or not yet loaded.
  final List<MarketplaceListing> marketplaceListings;

  /// Creates a copy with updated catalog detail fields.
  CatalogSearchResult copyWith({
    String? id,
    String? title,
    String? category,
    String? source,
    String? setName,
    String? identifier,
    String? currency,
    double? marketValue,
    double? lowEstimate,
    double? highEstimate,
    double? confidence,
    DateTime? lastUpdated,
    String? attribution,
    String? reasonCode,
    String? displayMessage,
    String? imageUrl,
    List<CatalogImage>? images,
    String? productUrl,
    String? externalImageUrl,
    List<CatalogPriceHistoryPoint>? history,
    List<MarketplaceListing>? marketplaceListings,
  }) {
    return CatalogSearchResult(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      source: source ?? this.source,
      setName: setName ?? this.setName,
      identifier: identifier ?? this.identifier,
      currency: currency ?? this.currency,
      marketValue: marketValue ?? this.marketValue,
      lowEstimate: lowEstimate ?? this.lowEstimate,
      highEstimate: highEstimate ?? this.highEstimate,
      confidence: confidence ?? this.confidence,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      attribution: attribution ?? this.attribution,
      reasonCode: reasonCode ?? this.reasonCode,
      displayMessage: displayMessage ?? this.displayMessage,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      productUrl: productUrl ?? this.productUrl,
      externalImageUrl: externalImageUrl ?? this.externalImageUrl,
      history: history ?? this.history,
      marketplaceListings: marketplaceListings ?? this.marketplaceListings,
    );
  }

  /// Parses a flexible backend response safely.
  factory CatalogSearchResult.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'] is Map<String, dynamic>
        ? json['pricing'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return CatalogSearchResult(
      id:
          _string(json['id']) ??
          _string(json['catalogId']) ??
          _string(json['pricechartingId']) ??
          _string(json['productId']) ??
          _string(json['title']) ??
          'catalog-result',
      title:
          _string(json['title']) ??
          _string(json['name']) ??
          _string(json['productName']) ??
          'Catalog item',
      category:
          _string(json['category']) ?? _string(json['sourceFile']) ?? 'Catalog',
      source:
          _string(json['source']) ??
          _string(json['pricingSource']) ??
          _string(pricing['pricingSource']) ??
          'PackLox catalog',
      setName:
          _string(json['setName']) ??
          _string(json['set']) ??
          _string(json['consoleName']),
      identifier:
          _string(json['identifier']) ??
          _string(json['cardNumber']) ??
          _string(json['productNumber']),
      currency:
          (_string(json['currency']) ?? _string(pricing['currency']) ?? 'AUD')
              .toUpperCase(),
      marketValue:
          _number(json['marketValue']) ??
          _number(json['valueAud']) ??
          _number(json['price']) ??
          _number(pricing['marketValue']) ??
          _number(pricing['loosePrice']) ??
          _number(pricing['cibPrice']) ??
          _number(pricing['newPrice']) ??
          _number(pricing['gradedPrice']) ??
          _number(pricing['estimatedMarketValue']),
      lowEstimate:
          _number(json['lowEstimate']) ?? _number(pricing['lowEstimate']),
      highEstimate:
          _number(json['highEstimate']) ?? _number(pricing['highEstimate']),
      confidence: _normalizedConfidence(
        json['confidence'] ?? json['confidenceScore'],
      ),
      lastUpdated:
          DateTime.tryParse(_string(json['lastUpdated']) ?? '') ??
          DateTime.tryParse(_string(json['lastChecked']) ?? ''),
      attribution:
          _string(json['attribution']) ?? _string(pricing['attributionText']),
      reasonCode:
          _string(json['reasonCode']) ??
          _string(json['reason_code']) ??
          _string(pricing['reasonCode']),
      displayMessage:
          _string(json['displayMessage']) ??
          _string(json['display_message']) ??
          _string(pricing['displayMessage']) ??
          _string(pricing['pricingExplanation']),
      imageUrl: _string(json['imageUrl']) ?? _string(json['image_url']),
      images: catalogImagesFromJson(json['images']),
      productUrl: _string(json['productUrl']) ?? _string(json['product_url']),
      externalImageUrl:
          _string(json['externalImageUrl']) ??
          _string(json['external_image_url']),
      history: _historyFromJson(json['history']),
    );
  }
}

/// A single observed valuation version for a catalog item.
class CatalogPriceHistoryPoint {
  /// Creates a catalog valuation history point.
  const CatalogPriceHistoryPoint({
    required this.validFrom,
    required this.currency,
    this.validTo,
    this.isCurrent = false,
    this.marketValue,
    this.lowEstimate,
    this.highEstimate,
    this.sourceFile,
    this.sourceDownloadedAt,
  });

  /// Start of this observed price version.
  final DateTime validFrom;

  /// End of this observed price version, null for current.
  final DateTime? validTo;

  /// Whether this point is the active version.
  final bool isCurrent;

  /// Display currency.
  final String currency;

  /// Primary observed value.
  final double? marketValue;

  /// Low observed value.
  final double? lowEstimate;

  /// High observed value.
  final double? highEstimate;

  /// Source CSV name.
  final String? sourceFile;

  /// Timestamp when source data was downloaded.
  final DateTime? sourceDownloadedAt;

  /// Parses a flexible backend response safely.
  factory CatalogPriceHistoryPoint.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'] is Map<String, dynamic>
        ? json['pricing'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final validFrom =
        DateTime.tryParse(_string(json['validFrom']) ?? '') ??
        DateTime.tryParse(_string(json['valid_from']) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return CatalogPriceHistoryPoint(
      validFrom: validFrom,
      validTo:
          DateTime.tryParse(_string(json['validTo']) ?? '') ??
          DateTime.tryParse(_string(json['valid_to']) ?? ''),
      isCurrent: json['isCurrent'] == true || json['is_current'] == true,
      currency:
          (_string(json['currency']) ?? _string(pricing['currency']) ?? 'AUD')
              .toUpperCase(),
      marketValue:
          _number(json['marketValue']) ??
          _number(json['valueAud']) ??
          _number(pricing['marketValue']) ??
          _number(pricing['estimatedMarketValue']),
      lowEstimate:
          _number(json['lowEstimate']) ?? _number(pricing['lowEstimate']),
      highEstimate:
          _number(json['highEstimate']) ?? _number(pricing['highEstimate']),
      sourceFile: _string(json['sourceFile']) ?? _string(json['source_file']),
      sourceDownloadedAt:
          DateTime.tryParse(_string(json['sourceDownloadedAt']) ?? '') ??
          DateTime.tryParse(_string(json['source_downloaded_at']) ?? ''),
    );
  }
}

/// A real, currently-available listing for this item on an external
/// marketplace (eBay today), meant to be opened in an external/in-app
/// browser tab -- never a purchase flow inside PackLox itself.
class MarketplaceListing {
  /// Creates a marketplace listing.
  const MarketplaceListing({
    required this.title,
    required this.price,
    required this.currency,
    required this.url,
    this.condition = '',
    this.source = 'eBay',
    this.size,
    this.totalAsks,
    this.salesLast30Days,
  });

  /// The listing's title, as written by the seller.
  final String title;

  /// Asking price, already in [currency].
  final double price;

  /// Currency the price is expressed in.
  final String currency;

  /// Seller-described condition string (e.g. "New", "Used"), when known.
  final String condition;

  /// Direct link to the real listing on the source marketplace.
  final String url;

  /// Which marketplace this listing came from.
  final String source;

  /// Shoe size label for sneaker (StockX) listings, null otherwise.
  final String? size;

  /// Active asks for this size on the marketplace, sneakers only. A
  /// listing with this set is a current lowest ask, not a completed sale.
  final int? totalAsks;

  /// Completed sales in the last 30 days for this size, sneakers only.
  final int? salesLast30Days;

  /// Parses a flexible backend response safely.
  factory MarketplaceListing.fromJson(Map<String, dynamic> json) {
    return MarketplaceListing(
      title: _string(json['title']) ?? '',
      price: _number(json['price']) ?? 0,
      currency: (_string(json['currency']) ?? '').toUpperCase(),
      condition: _string(json['condition']) ?? '',
      url: _string(json['url']) ?? '',
      source: _string(json['source']) ?? 'eBay',
      size: _string(json['size']),
      totalAsks: _int(json['totalAsks']),
      salesLast30Days: _int(json['salesLast30Days']),
    );
  }
}

int? _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

/// One image of a catalog item, for items that have more than one view.
///
/// [label] names the view ("Obverse"/"Reverse" for coins, "View 2" for a
/// sneaker gallery). [credit] carries a photo credit that MUST be shown
/// with the image when the source requires one.
class CatalogImage {
  /// Creates a catalog image.
  const CatalogImage({required this.url, this.label, this.credit});

  /// Direct image URL.
  final String url;

  /// Human-readable name of this view, when the source provides one.
  final String? label;

  /// Required photo credit, displayed alongside the image when set.
  final String? credit;

  /// Parses a flexible backend response safely.
  factory CatalogImage.fromJson(Map<String, dynamic> json) {
    return CatalogImage(
      url: _string(json['url']) ?? '',
      label: _string(json['label']),
      credit: _string(json['credit']),
    );
  }
}

/// Parses the backend's `images` list safely, dropping entries with no URL.
List<CatalogImage> catalogImagesFromJson(Object? value) {
  if (value is! List) {
    return const <CatalogImage>[];
  }
  return value
      .whereType<Map<String, dynamic>>()
      .map(CatalogImage.fromJson)
      .where((image) => image.url.isNotEmpty)
      .toList(growable: false);
}

String? _string(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

double? _number(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '');
}

double? _normalizedConfidence(Object? value) {
  final parsed = _number(value);
  if (parsed == null) {
    return null;
  }
  return parsed > 1 ? parsed / 100 : parsed;
}

List<CatalogPriceHistoryPoint> _historyFromJson(Object? value) {
  if (value is! List) {
    return const <CatalogPriceHistoryPoint>[];
  }
  return value
      .whereType<Map<String, dynamic>>()
      .map(CatalogPriceHistoryPoint.fromJson)
      .toList(growable: false);
}
