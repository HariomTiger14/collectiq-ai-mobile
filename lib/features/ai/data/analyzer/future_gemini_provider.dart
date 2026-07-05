import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_models.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_provider.dart';

/// Placeholder for a future backend-only Gemini provider.
class FutureGeminiProvider implements AnalyzerProvider {
  const FutureGeminiProvider();

  @override
  String get id => AnalyzerProviderType.futureGemini.configValue;

  @override
  Future<AnalyzerResponse> analyze(
    AnalyzerRequest request, {
    AnalyzerProgressCallback? onProgress,
  }) {
    throw const AnalyzerException(
      type: AnalyzerErrorType.providerUnavailable,
      message:
          'Future Gemini is not connected yet. Gemini keys must stay server-side.',
    );
  }
}
