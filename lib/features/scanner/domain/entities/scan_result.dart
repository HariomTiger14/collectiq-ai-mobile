/// Alternative match displayed in the scan result review.
class ScanAlternativeMatch {
  /// Creates an immutable scan alternative match.
  const ScanAlternativeMatch({
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

  /// Explanation for why the alternative may fit.
  final String reason;
}

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
    required this.primaryMatch,
    required this.alternativeMatches,
    required this.confidenceExplanation,
    required this.detectionQuality,
    required this.aiReasoning,
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

  /// Primary AI match label.
  final String primaryMatch;

  /// Top alternative AI matches.
  final List<ScanAlternativeMatch> alternativeMatches;

  /// Explanation of the confidence score.
  final String confidenceExplanation;

  /// Image and detection quality assessment.
  final String detectionQuality;

  /// AI reasoning behind the primary match.
  final String aiReasoning;
}
