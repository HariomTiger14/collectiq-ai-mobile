import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';

/// Data model for serializing and deserializing scanner results.
class ScanResultModel extends ScanResult {
  /// Creates a scanner result model.
  const ScanResultModel({
    required super.id,
    required super.title,
    required super.category,
    required super.estimatedValue,
    required super.confidence,
    required super.condition,
    required super.thumbnail,
    required super.scanDate,
    required super.primaryMatch,
    required super.alternativeMatches,
    required super.confidenceExplanation,
    required super.detectionQuality,
    required super.aiReasoning,
  });

  /// Creates a model from a JSON map.
  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    return ScanResultModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      estimatedValue: (json['estimatedValue'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      condition: json['condition'] as String,
      thumbnail: json['thumbnail'] as String,
      scanDate: DateTime.parse(json['scanDate'] as String),
      primaryMatch: json['primaryMatch'] as String? ?? json['title'] as String,
      alternativeMatches: (json['alternativeMatches'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (match) => ScanAlternativeMatch(
              title: match['title'] as String? ?? 'Unknown alternative',
              category: match['category'] as String? ?? 'Collectible',
              confidence: (match['confidence'] as num? ?? 0).toDouble(),
              reason: match['reason'] as String? ?? '',
            ),
          )
          .toList(),
      confidenceExplanation:
          json['confidenceExplanation'] as String? ??
          'Confidence is based on visible collectible details.',
      detectionQuality:
          json['detectionQuality'] as String? ??
          'Image quality was sufficient for analysis.',
      aiReasoning:
          json['aiReasoning'] as String? ??
          json['description'] as String? ??
          '',
    );
  }

  /// Converts the model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'estimatedValue': estimatedValue,
      'confidence': confidence,
      'condition': condition,
      'thumbnail': thumbnail,
      'scanDate': scanDate.toIso8601String(),
      'primaryMatch': primaryMatch,
      'alternativeMatches': [
        for (final match in alternativeMatches)
          {
            'title': match.title,
            'category': match.category,
            'confidence': match.confidence,
            'reason': match.reason,
          },
      ],
      'confidenceExplanation': confidenceExplanation,
      'detectionQuality': detectionQuality,
      'aiReasoning': aiReasoning,
    };
  }
}
