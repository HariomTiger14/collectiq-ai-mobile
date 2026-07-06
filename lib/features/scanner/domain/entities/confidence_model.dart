class ConfidenceModel {
  const ConfidenceModel({
    required this.confidenceTarget,
    this.confidenceAchieved,
  });

  final double confidenceTarget;
  final double? confidenceAchieved;

  bool get isTargetMet {
    final achieved = confidenceAchieved;
    return achieved != null && achieved >= confidenceTarget;
  }

  double? get deltaFromTarget {
    final achieved = confidenceAchieved;
    return achieved == null ? null : achieved - confidenceTarget;
  }
}
