import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_models.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_provider.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';

/// Production analyzer provider for the current mock/backend-SIT path.
class MockAnalyzerProvider implements AnalyzerProvider {
  const MockAnalyzerProvider({required this.analysisProvider});

  final AiAnalysisProvider analysisProvider;

  @override
  String get id => AnalyzerProviderType.mock.configValue;

  @override
  Future<AnalyzerResponse> analyze(
    AnalyzerRequest request, {
    AnalyzerProgressCallback? onProgress,
  }) async {
    request.cancellationToken?.throwIfCancelled();
    onProgress?.call(
      const AnalyzerProgressEvent(status: AnalysisStatus.uploading),
    );
    onProgress?.call(
      const AnalyzerProgressEvent(status: AnalysisStatus.analyzing),
    );

    final result = await analysisProvider.analyze(
      AiAnalysisRequest(
        imagePath: request.imagePath,
        image: request.image,
        metadata: request.metadata,
      ),
    );
    request.cancellationToken?.throwIfCancelled();

    return AnalyzerResponse.fromAiAnalysisResult(
      result,
      rawProviderPayload: {'provider': id},
    );
  }
}
