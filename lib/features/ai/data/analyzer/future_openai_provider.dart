import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_models.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_provider.dart';

/// Placeholder for a future backend-only OpenAI provider.
class FutureOpenAIProvider implements AnalyzerProvider {
  const FutureOpenAIProvider();

  @override
  String get id => AnalyzerProviderType.futureOpenAI.configValue;

  @override
  Future<AnalyzerResponse> analyze(
    AnalyzerRequest request, {
    AnalyzerProgressCallback? onProgress,
  }) {
    throw const AnalyzerException(
      type: AnalyzerErrorType.providerUnavailable,
      message:
          'Future OpenAI is not connected yet. OpenAI keys must stay server-side.',
    );
  }
}
