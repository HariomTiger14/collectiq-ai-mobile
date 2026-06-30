import 'package:collectiq_ai/features/ai/data/providers/mock_ai_analysis_provider.dart';
import 'package:collectiq_ai/features/ai/data/providers/open_ai_vision_analysis_provider.dart';
import 'package:collectiq_ai/features/ai/domain/clients/ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:collectiq_ai/features/market/domain/repositories/market_provider.dart';

/// Creates the configured AI analysis provider.
class AiAnalysisProviderFactory {
  /// Creates a provider factory.
  const AiAnalysisProviderFactory();

  /// Builds a provider for the supplied configuration.
  AiAnalysisProvider create({
    required AiAnalysisProviderConfig config,
    required RecognitionRepository recognitionRepository,
    required MarketProvider marketProvider,
    required AiBackendClient backendClient,
  }) {
    return switch (config.type) {
      AiAnalysisProviderType.mock => MockAiAnalysisProvider(
        recognitionRepository: recognitionRepository,
        marketProvider: marketProvider,
      ),
      AiAnalysisProviderType.openAiVision => OpenAiVisionAnalysisProvider(
        backendClient: backendClient,
      ),
      AiAnalysisProviderType.geminiVision => const _PlaceholderAiProvider(
        providerName: 'Gemini Vision',
      ),
    };
  }
}

class _PlaceholderAiProvider implements AiAnalysisProvider {
  const _PlaceholderAiProvider({required this.providerName});

  final String providerName;

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisRequest request) {
    throw AiAnalysisException(
      '$providerName analysis is not enabled yet. Switch AI_ANALYSIS_PROVIDER back to mock.',
    );
  }
}
