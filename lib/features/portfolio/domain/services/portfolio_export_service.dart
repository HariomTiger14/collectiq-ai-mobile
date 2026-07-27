import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

/// Builds portable portfolio exports from saved collectibles.
class PortfolioExportService {
  /// Creates a portfolio export service.
  const PortfolioExportService();

  static const List<String> _headers = [
    'id',
    'title',
    'category',
    'condition',
    'estimated_value',
    'currency',
    'value_at_scan',
    'low_estimate',
    'high_estimate',
    'valuation_status',
    'valuation_source',
    'pricing_source',
    'pricing_confidence',
    'confidence',
    'year',
    'brand',
    'set_name',
    'series',
    'card_number',
    'player_or_character',
    'rarity',
    'estimated_grade',
    'language',
    'edition',
    'country',
    'mint',
    'material',
    'notes',
    'recommendation',
    'image_count',
    'sync_status',
    'created_at',
    'last_value_refreshed_at',
    'last_pricing_updated_at',
  ];

  /// Builds a standards-friendly CSV string.
  String buildCsv(List<CollectibleItem> items) {
    final rows = [_headers, for (final item in items) _rowFor(item)];
    return rows.map(_csvRow).join('\n');
  }

  List<String> _rowFor(CollectibleItem item) {
    final pricing = item.pricing;
    return [
      item.id,
      item.title,
      item.category,
      item.condition,
      _formatNumber(item.estimatedValue),
      pricing?.currency ?? '',
      _formatNullableNumber(item.valueAtScan),
      _formatNullableNumber(pricing?.lowEstimate),
      _formatNullableNumber(pricing?.highEstimate),
      item.valuationStatus.wireValue,
      item.valuationSource,
      pricing?.pricingSource ?? '',
      _formatNullableNumber(pricing?.pricingConfidence),
      _formatNumber(item.confidence),
      item.year ?? '',
      item.brand ?? '',
      item.setName ?? '',
      item.series ?? '',
      item.cardNumber ?? '',
      item.playerOrCharacter ?? '',
      item.rarity ?? '',
      item.estimatedGrade ?? '',
      item.language ?? '',
      item.edition ?? '',
      item.country ?? '',
      item.mint ?? '',
      item.material ?? '',
      item.notes ?? '',
      item.recommendation,
      item.effectiveGalleryImages.length.toString(),
      item.syncStatus.name,
      item.createdAt.toIso8601String(),
      item.lastValueRefreshedAt?.toIso8601String() ?? '',
      pricing?.lastUpdated?.toIso8601String() ?? '',
    ];
  }

  String _csvRow(List<String> fields) {
    return fields.map(_escape).join(',');
  }

  String _escape(String value) {
    final needsQuotes =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  String _formatNullableNumber(double? value) {
    if (value == null) {
      return '';
    }
    return _formatNumber(value);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }
}
