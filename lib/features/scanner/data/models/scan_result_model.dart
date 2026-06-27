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
    };
  }
}
