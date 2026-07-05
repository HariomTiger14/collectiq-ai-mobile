import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_models.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_provider.dart';

/// Placeholder for a future CollectIQ-managed vision provider.
class FutureVisionProvider implements AnalyzerProvider {
  const FutureVisionProvider();

  @override
  String get id => AnalyzerProviderType.futureVision.configValue;

  @override
  Future<AnalyzerResponse> analyze(
    AnalyzerRequest request, {
    AnalyzerProgressCallback? onProgress,
  }) {
    throw const AnalyzerException(
      type: AnalyzerErrorType.providerUnavailable,
      message:
          'Future Vision is not connected yet. Switch AI_ANALYSIS_PROVIDER back to mock.',
    );
  }
}
