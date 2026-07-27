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
    this.history = const <CatalogPriceHistoryPoint>[],
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

  /// Observed catalog valuation history, newest first when supplied.
  final List<CatalogPriceHistoryPoint> history;

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
    List<CatalogPriceHistoryPoint>? history,
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
      history: history ?? this.history,
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
