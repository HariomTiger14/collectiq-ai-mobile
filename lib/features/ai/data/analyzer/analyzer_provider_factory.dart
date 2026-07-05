import 'package:collectiq_ai/features/ai/data/analyzer/future_gemini_provider.dart';
import 'package:collectiq_ai/features/ai/data/analyzer/future_openai_provider.dart';
import 'package:collectiq_ai/features/ai/data/analyzer/future_vision_provider.dart';
import 'package:collectiq_ai/features/ai/data/analyzer/mock_analyzer_provider.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_models.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_provider.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';

/// Creates the configured analyzer provider.
class AnalyzerProviderFactory {
  const AnalyzerProviderFactory();

  AnalyzerProvider create({
    required AnalyzerConfig config,
    required AiAnalysisProvider legacyAnalysisProvider,
  }) {
    return switch (config.providerType) {
      AnalyzerProviderType.mock => MockAnalyzerProvider(
        analysisProvider: legacyAnalysisProvider,
      ),
      AnalyzerProviderType.futureVision => const FutureVisionProvider(),
      AnalyzerProviderType.futureOpenAI => const FutureOpenAIProvider(),
      AnalyzerProviderType.futureGemini => const FutureGeminiProvider(),
    };
  }
}
