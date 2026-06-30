import 'package:collectiq_ai/features/ai/data/models/ai_backend_analysis_models.dart';
import 'package:collectiq_ai/features/ai/domain/clients/ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';

/// Skeleton for future OpenAI Vision analysis.
///
/// Important security note:
/// - Do not put OpenAI API keys in Flutter, dart-define, app storage, or any
///   mobile-distributed artifact.
/// - Real OpenAI calls must happen on a trusted backend/proxy controlled by
///   CollectIQ AI.
/// - The Flutter app should send the image only to that backend endpoint, and
///   the backend should call OpenAI with server-side credentials.
class OpenAiVisionAnalysisProvider implements AiAnalysisProvider {
  /// Creates an OpenAI Vision skeleton provider.
  const OpenAiVisionAnalysisProvider({required this.backendClient});

  /// Future CollectIQ backend client.
  final AiBackendClient backendClient;

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisRequest request) async {
    try {
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

      return AiAnalysisResult(
        scanResult: response.toScanResult(thumbnail: request.imagePath),
        recommendation: response.recommendation,
      );
    } on AiBackendClientException catch (error) {
      throw AiAnalysisException(error.message);
    } on Object {
      throw const AiAnalysisException(
        'AI analysis is not available right now. Please try again later.',
      );
    }
  }

  String _imageSourceFor(AiAnalysisRequest request) {
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

  String? _optionalMetadataString(AiAnalysisRequest request, String key) {
    final value = request.metadata[key];
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }
}
