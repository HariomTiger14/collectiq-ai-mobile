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

  /// Creates a recognition result from backend JSON.
  factory RecognitionResult.fromJson(Map<String, dynamic> json) {
    final confidence = (json['confidence'] as num).toDouble();

    return RecognitionResult(
      success: json['success'] as bool? ?? true,
      filename: json['filename'] as String?,
      imageUrl: json['imageUrl'] as String?,
      title: json['title'] as String,
      category: json['category'] as String,
      confidence: confidence > 1 ? confidence / 100 : confidence,
      description: json['description'] as String? ?? '',
      estimatedValue: (json['estimatedValue'] as num).toDouble(),
      condition: json['condition'] as String,
      recommendation: json['recommendation'] as String,
    );
  }
}
