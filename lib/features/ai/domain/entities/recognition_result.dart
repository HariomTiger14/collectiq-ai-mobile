/// Alternative collectible match returned by the AI review system.
class RecognitionAlternativeMatch {
  /// Creates an immutable alternative match.
  const RecognitionAlternativeMatch({
    required this.title,
    required this.category,
    required this.confidence,
    required this.reason,
  });

  /// Alternative collectible title.
  final String title;

  /// Alternative collectible category.
  final String category;

  /// Alternative confidence score from 0.0 to 1.0.
  final double confidence;

  /// Short explanation for why this alternative may fit.
  final String reason;

  /// Creates an alternative match from backend JSON.
  factory RecognitionAlternativeMatch.fromJson(Map<String, dynamic> json) {
    final confidence = (json['confidence'] as num? ?? 0).toDouble();

    return RecognitionAlternativeMatch(
      title: json['title'] as String? ?? 'Unknown alternative',
      category: json['category'] as String? ?? 'Collectible',
      confidence: confidence > 1 ? confidence / 100 : confidence,
      reason: json['reason'] as String? ?? '',
    );
  }
}

/// Domain entity for AI collectible recognition output.
class RecognitionResult {
  /// Creates an immutable recognition result.
  const RecognitionResult({
    required this.success,
    required this.filename,
    required this.imageUrl,
    required this.title,
    required this.category,
    required this.confidence,
    required this.description,
    required this.estimatedValue,
    required this.condition,
    required this.recommendation,
    required this.primaryMatch,
    required this.alternativeMatches,
    required this.confidenceExplanation,
    required this.detectionQuality,
    required this.aiReasoning,
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

  /// Whether the backend completed analysis successfully.
  final bool success;

  /// Stored backend filename for the uploaded image.
  final String? filename;

  /// Public backend URL for the uploaded image.
  final String? imageUrl;

  /// AI-generated collectible title.
  final String title;

  /// AI-generated collectible category.
  final String category;

  /// Recognition confidence score from 0.0 to 1.0.
  final double confidence;

  /// Short explanation of what the recognition model detected.
  final String description;

  /// Estimated market value returned by the backend.
  final double estimatedValue;

  /// Estimated collectible condition returned by the backend.
  final String condition;

  /// Suggested next action returned by the backend.
  final String recommendation;

  /// Primary AI match label.
  final String primaryMatch;

  /// Top alternative matches returned by the AI.
  final List<RecognitionAlternativeMatch> alternativeMatches;

  /// Explanation for the confidence score.
  final String confidenceExplanation;

  /// Image and detection quality assessment.
  final String detectionQuality;

  /// AI reasoning for the selected match.
  final String aiReasoning;

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

  /// Creates a recognition result from backend JSON.
  factory RecognitionResult.fromJson(Map<String, dynamic> json) {
    final confidence = (json['confidence'] as num).toDouble();
    final alternativeMatches =
        (json['alternativeMatches'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(RecognitionAlternativeMatch.fromJson)
            .toList();

    return RecognitionResult(
      success: json['success'] as bool? ?? true,
      filename: json['filename'] as String?,
      imageUrl: (json['imageUrl'] ?? json['image_url']) as String?,
      title: json['title'] as String,
      category: json['category'] as String,
      confidence: confidence > 1 ? confidence / 100 : confidence,
      description: json['description'] as String? ?? '',
      estimatedValue: (json['estimatedValue'] as num).toDouble(),
      condition: json['condition'] as String,
      recommendation: json['recommendation'] as String,
      primaryMatch: json['primaryMatch'] as String? ?? json['title'] as String,
      alternativeMatches: alternativeMatches,
      confidenceExplanation:
          json['confidenceExplanation'] as String? ??
          'Confidence is based on visible collectible details.',
      detectionQuality:
          json['detectionQuality'] as String? ??
          'Image quality was sufficient for analysis.',
      aiReasoning:
          json['aiReasoning'] as String? ??
          (json['description'] as String? ?? ''),
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
}

String? _optionalString(Object? value) {
  if (value is! String) {
    return null;
  }

  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
