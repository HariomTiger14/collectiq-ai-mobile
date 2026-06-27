/// Domain entity representing the result of a completed collectible scan.
class ScanResult {
  /// Creates an immutable scan result.
  const ScanResult({
    required this.id,
    required this.title,
    required this.category,
    required this.estimatedValue,
    required this.confidence,
    required this.condition,
    required this.thumbnail,
    required this.scanDate,
  });

  /// Unique scan identifier.
  final String id;

  /// AI-generated or user-confirmed collectible title.
  final String title;

  /// Collectible category such as cards, coins, watches, or sneakers.
  final String category;

  /// Estimated market value for the scanned item.
  final double estimatedValue;

  /// AI confidence score from 0.0 to 1.0.
  final double confidence;

  /// Detected or selected condition label.
  final String condition;

  /// Thumbnail URI or local path for the scanned image.
  final String thumbnail;

  /// Date and time when the scan was created.
  final DateTime scanDate;
}
