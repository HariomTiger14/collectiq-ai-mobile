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
    this.pricing,
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

  /// Date and time the item was added.
  final DateTime createdAt;

  final PricingInfo? pricing;

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
      createdAt: DateTime.parse(json['createdAt'] as String),
      pricing: json['pricing'] is Map<String, dynamic>
          ? PricingInfo.fromJson(json['pricing'] as Map<String, dynamic>)
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
      'createdAt': createdAt.toIso8601String(),
      'pricing': pricing?.toJson(),
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
    };
  }
}

String? _optionalString(Object? value) {
  if (value is! String) {
    return null;
  }

  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
