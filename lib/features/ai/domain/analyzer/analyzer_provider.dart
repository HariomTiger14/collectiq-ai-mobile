import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_models.dart';

/// Replaceable provider boundary for collectible image analysis.
abstract interface class AnalyzerProvider {
  /// Stable provider identifier used for logs and diagnostics.
  String get id;

  /// Analyzes a collectible image.
  Future<AnalyzerResponse> analyze(
    AnalyzerRequest request, {
    AnalyzerProgressCallback? onProgress,
  });
}
