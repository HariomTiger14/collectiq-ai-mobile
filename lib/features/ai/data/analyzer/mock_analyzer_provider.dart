import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_models.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_provider.dart';
import 'package:collectiq_ai/features/ai/data/models/ai_backend_analysis_models.dart';
import 'package:collectiq_ai/features/ai/domain/clients/ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';

/// Production analyzer provider for the current mock/backend-SIT path.
class MockAnalyzerProvider implements AnalyzerProvider {
  const MockAnalyzerProvider({
    required this.analysisProvider,
    required this.backendClient,
    this.useBackendContract = false,
  });

  final AiAnalysisProvider analysisProvider;
  final AiBackendClient backendClient;
  final bool useBackendContract;

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

    if (useBackendContract) {
      final response = await backendClient.analyze(
        AiBackendAnalysisRequest(
          imagePath: request.imagePath,
          imageSource: _imageSourceFor(request),
          requestedCategory: _optionalMetadataString(
            request,
            'requestedCategory',
          ),
          timestamp: DateTime.now(),
        ),
      );
      request.cancellationToken?.throwIfCancelled();

      return AnalyzerResponse.fromAiAnalysisResult(
        AiAnalysisResult(
          scanResult: response.toScanResult(thumbnail: request.imagePath),
          recommendation: response.recommendation,
        ),
        rawProviderPayload: {'provider': id, 'contract': 'POST /analyze'},
      );
    }

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

  String _imageSourceFor(AnalyzerRequest request) {
    final configuredSource = _optionalMetadataString(request, 'imageSource');
    if (configuredSource != null) {
      return configuredSource;
    }

    final selectedTitle = _optionalMetadataString(request, 'selectedItemTitle');
    if (selectedTitle != null) {
      final normalizedTitle = selectedTitle.toLowerCase();
      if (normalizedTitle.contains('camera') ||
          normalizedTitle.contains('captured')) {
        return 'camera';
      }
      if (normalizedTitle.contains('gallery') ||
          normalizedTitle.contains('uploaded')) {
        return 'gallery';
      }
    }

    if (request.imagePath.startsWith('sample://')) {
      return 'sample';
    }

    return 'unknown';
  }

  String? _optionalMetadataString(AnalyzerRequest request, String key) {
    final value = request.metadata[key];
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }
}
