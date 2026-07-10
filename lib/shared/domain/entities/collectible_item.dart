import 'package:collectiq_ai/features/market/domain/entities/market_summary.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';

class CollectibleAlternativeMatch {
  const CollectibleAlternativeMatch({
    required this.title,
    required this.category,
    required this.confidence,
    required this.reason,
  });

  final String title;
  final String category;
  final double confidence;
  final String reason;

  factory CollectibleAlternativeMatch.fromJson(Map<String, dynamic> json) {
    return CollectibleAlternativeMatch(
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'confidence': confidence,
      'reason': reason,
    };
  }
}

enum CloudItemSyncStatus {
  localOnly,
  pendingUpload,
  synced,
  failed;

  static CloudItemSyncStatus fromJson(Object? value) {
    if (value is! String) {
      return CloudItemSyncStatus.localOnly;
    }

    return switch (value.trim()) {
      'pendingUpload' => CloudItemSyncStatus.pendingUpload,
      'synced' => CloudItemSyncStatus.synced,
      'failed' => CloudItemSyncStatus.failed,
      _ => CloudItemSyncStatus.localOnly,
    };
  }
}

/// Shared domain entity representing a collectible stored in the portfolio.
class CollectibleItem {
  /// Creates an immutable collectible item.
  const CollectibleItem({
    required this.id,
    required this.title,
    required this.category,
    required this.estimatedValue,
    required this.confidence,
    required this.condition,
    required this.recommendation,
    required this.imagePath,
    required this.createdAt,
    this.imageStoragePath,
    this.cloudImageUrl,
    this.syncStatus = CloudItemSyncStatus.localOnly,
    this.lastSyncedAt,
    this.syncError,
    this.pricing,
    this.marketSummary,
    this.primaryMatch,
    this.alternativeMatches = const [],
    this.confidenceExplanation,
    this.detectionQuality,
    this.aiReasoning,
    this.year,
    this.brand,
    this.setName,
    this.series,
    this.cardNumber,
    this.playerOrCharacter,
    this.rarity,
    this.estimatedGrade,
    this.language,
    this.edition,
    this.country,
    this.mint,
    this.material,
    this.notes,
    this.valuationStatus = ValuationStatus.unavailable,
    this.valuationSource = 'unknown',
    this.aiEstimatedValue,
  });

  /// Unique item identifier.
  final String id;

  /// Display title for the collectible.
  final String title;

  /// Collectible category.
  final String category;

  /// Estimated market value.
  final double estimatedValue;

  /// AI confidence score from 0.0 to 1.0.
  final double confidence;

  /// Detected or selected item condition.
  final String condition;

  /// Suggested next action for the owner.
  final String recommendation;

  /// Local image path or sample image identifier.
  final String imagePath;

  /// Supabase Storage object path after background upload completes.
  final String? imageStoragePath;

  /// Public cloud image URL after background upload completes.
  final String? cloudImageUrl;

  final CloudItemSyncStatus syncStatus;

  final DateTime? lastSyncedAt;

  final String? syncError;

  /// Canonical date and time the item was saved into the local portfolio.
  final DateTime createdAt;

  final PricingInfo? pricing;

  final MarketSummary? marketSummary;

  final String? primaryMatch;
  final List<CollectibleAlternativeMatch> alternativeMatches;
  final String? confidenceExplanation;
  final String? detectionQuality;
  final String? aiReasoning;

  final String? year;
  final String? brand;
  final String? setName;
  final String? series;
  final String? cardNumber;
  final String? playerOrCharacter;
  final String? rarity;
  final String? estimatedGrade;
  final String? language;
  final String? edition;
  final String? country;
  final String? mint;
  final String? material;
  final String? notes;
  final ValuationStatus valuationStatus;
  final String valuationSource;
  final double? aiEstimatedValue;

  /// Creates a collectible item from a JSON map.
  factory CollectibleItem.fromJson(Map<String, dynamic> json) {
    return CollectibleItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      estimatedValue: (json['estimatedValue'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      condition: json['condition'] as String,
      recommendation: json['recommendation'] as String,
      imagePath: json['imagePath'] as String,
      imageStoragePath: _optionalString(json['imageStoragePath']),
      cloudImageUrl: _optionalString(json['cloudImageUrl']),
      syncStatus: CloudItemSyncStatus.fromJson(json['syncStatus']),
      lastSyncedAt: _optionalDateTime(json['lastSyncedAt']),
      syncError: _optionalString(json['syncError']),
      createdAt: _savedAtFromJson(json),
      pricing: json['pricing'] is Map<String, dynamic>
          ? PricingInfo.fromJson(json['pricing'] as Map<String, dynamic>)
          : null,
      marketSummary: json['marketSummary'] is Map<String, dynamic>
          ? MarketSummary.fromJson(
              json['marketSummary'] as Map<String, dynamic>,
            )
          : null,
      primaryMatch: _optionalString(json['primaryMatch']),
      alternativeMatches:
          (json['alternativeMatches'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(CollectibleAlternativeMatch.fromJson)
              .toList(),
      confidenceExplanation: _optionalString(json['confidenceExplanation']),
      detectionQuality: _optionalString(json['detectionQuality']),
      aiReasoning: _optionalString(json['aiReasoning']),
      year: _optionalString(json['year']),
      brand: _optionalString(json['brand']),
      setName: _optionalString(json['setName']),
      series: _optionalString(json['series']),
      cardNumber: _optionalString(json['cardNumber']),
      playerOrCharacter: _optionalString(json['playerOrCharacter']),
      rarity: _optionalString(json['rarity']),
      estimatedGrade: _optionalString(json['estimatedGrade']),
      language: _optionalString(json['language']),
      edition: _optionalString(json['edition']),
      country: _optionalString(json['country']),
      mint: _optionalString(json['mint']),
      material: _optionalString(json['material']),
      notes: _optionalString(json['notes']),
      valuationStatus: ValuationStatus.fromJson(json['valuationStatus']),
      valuationSource: _optionalString(json['valuationSource']) ?? 'unknown',
      aiEstimatedValue: _optionalDouble(json['aiEstimatedValue']),
    );
  }

  /// Converts the collectible item to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'estimatedValue': estimatedValue,
      'confidence': confidence,
      'condition': condition,
      'recommendation': recommendation,
      'imagePath': imagePath,
      'imageStoragePath': imageStoragePath,
      'cloudImageUrl': cloudImageUrl,
      'syncStatus': syncStatus.name,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncError': syncError,
      'savedAt': createdAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'pricing': pricing?.toJson(),
      'marketSummary': marketSummary?.toJson(),
      'primaryMatch': primaryMatch,
      'alternativeMatches': [
        for (final match in alternativeMatches) match.toJson(),
      ],
      'confidenceExplanation': confidenceExplanation,
      'detectionQuality': detectionQuality,
      'aiReasoning': aiReasoning,
      'year': year,
      'brand': brand,
      'setName': setName,
      'series': series,
      'cardNumber': cardNumber,
      'playerOrCharacter': playerOrCharacter,
      'rarity': rarity,
      'estimatedGrade': estimatedGrade,
      'language': language,
      'edition': edition,
      'country': country,
      'mint': mint,
      'material': material,
      'notes': notes,
      'valuationStatus': valuationStatus.wireValue,
      'valuationSource': valuationSource,
      'aiEstimatedValue': aiEstimatedValue,
    };
  }

  /// Creates a copy with updated background image sync metadata.
  CollectibleItem copyWithImageSync({
    required String imageStoragePath,
    required String cloudImageUrl,
  }) {
    return CollectibleItem(
      id: id,
      title: title,
      category: category,
      estimatedValue: estimatedValue,
      confidence: confidence,
      condition: condition,
      recommendation: recommendation,
      imagePath: imagePath,
      imageStoragePath: imageStoragePath,
      cloudImageUrl: cloudImageUrl,
      syncStatus: CloudItemSyncStatus.synced,
      lastSyncedAt: DateTime.now(),
      syncError: null,
      createdAt: createdAt,
      pricing: pricing,
      marketSummary: marketSummary,
      primaryMatch: primaryMatch,
      alternativeMatches: alternativeMatches,
      confidenceExplanation: confidenceExplanation,
      detectionQuality: detectionQuality,
      aiReasoning: aiReasoning,
      year: year,
      brand: brand,
      setName: setName,
      series: series,
      cardNumber: cardNumber,
      playerOrCharacter: playerOrCharacter,
      rarity: rarity,
      estimatedGrade: estimatedGrade,
      language: language,
      edition: edition,
      country: country,
      mint: mint,
      material: material,
      notes: notes,
    );
  }

  /// Creates a copy with a fresh local portfolio save timestamp.
  CollectibleItem copyWithSavedAt(DateTime savedAt) {
    return CollectibleItem(
      id: id,
      title: title,
      category: category,
      estimatedValue: estimatedValue,
      confidence: confidence,
      condition: condition,
      recommendation: recommendation,
      imagePath: imagePath,
      imageStoragePath: imageStoragePath,
      cloudImageUrl: cloudImageUrl,
      syncStatus: syncStatus,
      lastSyncedAt: lastSyncedAt,
      syncError: syncError,
      createdAt: savedAt,
      pricing: pricing,
      marketSummary: marketSummary,
      primaryMatch: primaryMatch,
      alternativeMatches: alternativeMatches,
      confidenceExplanation: confidenceExplanation,
      detectionQuality: detectionQuality,
      aiReasoning: aiReasoning,
      year: year,
      brand: brand,
      setName: setName,
      series: series,
      cardNumber: cardNumber,
      playerOrCharacter: playerOrCharacter,
      rarity: rarity,
      estimatedGrade: estimatedGrade,
      language: language,
      edition: edition,
      country: country,
      mint: mint,
      material: material,
      notes: notes,
    );
  }

  CollectibleItem copyWithCloudSync({
    CloudItemSyncStatus? syncStatus,
    String? imageStoragePath,
    String? cloudImageUrl,
    DateTime? lastSyncedAt,
    String? syncError,
    bool clearSyncError = false,
  }) {
    return CollectibleItem(
      id: id,
      title: title,
      category: category,
      estimatedValue: estimatedValue,
      confidence: confidence,
      condition: condition,
      recommendation: recommendation,
      imagePath: imagePath,
      imageStoragePath: imageStoragePath ?? this.imageStoragePath,
      cloudImageUrl: cloudImageUrl ?? this.cloudImageUrl,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncError: clearSyncError ? null : syncError ?? this.syncError,
      createdAt: createdAt,
      pricing: pricing,
      marketSummary: marketSummary,
      primaryMatch: primaryMatch,
      alternativeMatches: alternativeMatches,
      confidenceExplanation: confidenceExplanation,
      detectionQuality: detectionQuality,
      aiReasoning: aiReasoning,
      year: year,
      brand: brand,
      setName: setName,
      series: series,
      cardNumber: cardNumber,
      playerOrCharacter: playerOrCharacter,
      rarity: rarity,
      estimatedGrade: estimatedGrade,
      language: language,
      edition: edition,
      country: country,
      mint: mint,
      material: material,
      notes: notes,
    );
  }

  /// Creates a copy with locally editable profile fields changed.
  CollectibleItem copyWith({
    String? title,
    String? category,
    double? estimatedValue,
    PricingInfo? pricing,
    MarketSummary? marketSummary,
    String? year,
    String? brand,
    String? series,
    String? country,
    String? notes,
  }) {
    return CollectibleItem(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      confidence: confidence,
      condition: condition,
      recommendation: recommendation,
      imagePath: imagePath,
      imageStoragePath: imageStoragePath,
      cloudImageUrl: cloudImageUrl,
      syncStatus: syncStatus,
      lastSyncedAt: lastSyncedAt,
      syncError: syncError,
      createdAt: createdAt,
      pricing: pricing ?? this.pricing,
      marketSummary: marketSummary ?? this.marketSummary,
      primaryMatch: primaryMatch,
      alternativeMatches: alternativeMatches,
      confidenceExplanation: confidenceExplanation,
      detectionQuality: detectionQuality,
      aiReasoning: aiReasoning,
      year: year ?? this.year,
      brand: brand ?? this.brand,
      setName: setName,
      series: series ?? this.series,
      cardNumber: cardNumber,
      playerOrCharacter: playerOrCharacter,
      rarity: rarity,
      estimatedGrade: estimatedGrade,
      language: language,
      edition: edition,
      country: country ?? this.country,
      mint: mint,
      material: material,
      notes: notes ?? this.notes,
    );
  }
}

String? _optionalString(Object? value) {
  if (value is! String) {
    return null;
  }

  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

DateTime _savedAtFromJson(Map<String, dynamic> json) {
  return _optionalDateTime(json['savedAt']) ??
      _optionalDateTime(json['createdAt']) ??
      _optionalDateTime(json['updatedAt']) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

double? _optionalDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

DateTime? _optionalDateTime(Object? value) {
  if (value is! String) {
    return null;
  }

  final normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }

  return DateTime.tryParse(normalized);
}
