import 'package:collectiq_ai/features/ai/data/models/ai_backend_analysis_models.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_models.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_provider.dart';
import 'package:collectiq_ai/features/ai/domain/clients/ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';

/// Backend-backed Gemini analyzer provider.
///
/// The mobile app never calls Gemini directly. It sends the scan payload to the
/// PackLox backend contract, where the server can use Gemini with server-side
/// credentials.
class FutureGeminiProvider implements AnalyzerProvider {
  const FutureGeminiProvider({required this.backendClient});

  final AiBackendClient backendClient;

  @override
  String get id => AnalyzerProviderType.futureGemini.configValue;

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

    final response = await backendClient.analyze(
      AiBackendAnalysisRequest(
        imagePath: request.imagePath,
        imageSource: _imageSourceFor(request),
        requestedCategory: _optionalMetadataString(request, 'requestedCategory'),
        timestamp: DateTime.now(),
        scanGoal: _optionalMetadataString(request, 'scanGoal'),
        confidenceTarget: _optionalMetadataDouble(
          request,
          'confidenceTarget',
        ),
        scannerUxVersion: _optionalMetadataString(request, 'scannerUxVersion'),
        qualityMetadata: _optionalMetadataMap(request, 'qualityMetadata'),
        images: [
          for (final image in request.images)
            AiBackendAnalysisImage(
              imagePath: image.path,
              imageSource: image.source ?? _imageSourceFor(request),
              imageRole: image.role,
            ),
        ],
      ),
    );
    request.cancellationToken?.throwIfCancelled();

    return AnalyzerResponse.fromAiAnalysisResult(
      AiAnalysisResult(
        scanResult: response.toScanResult(thumbnail: request.imagePath),
        recommendation: response.recommendation,
      ),
      rawProviderPayload: {
        'provider': id,
        'analysisPath': 'remote_backend_contract',
        'contract': 'POST /analyze',
        'backendModelHint': 'gemini',
        ...response.rawProviderPayload,
      },
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

  double? _optionalMetadataDouble(AnalyzerRequest request, String key) {
    final value = request.metadata[key];
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  Map<String, Object?> _optionalMetadataMap(
    AnalyzerRequest request,
    String key,
  ) {
    final value = request.metadata[key];
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return Map<String, Object?>.from(value);
    }
    return const {};
  }
}
