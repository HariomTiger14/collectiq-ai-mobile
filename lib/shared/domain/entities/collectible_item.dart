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
    };
  }
}
