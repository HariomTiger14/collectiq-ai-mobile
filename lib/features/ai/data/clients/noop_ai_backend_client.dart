import 'package:collectiq_ai/features/ai/data/models/ai_backend_analysis_models.dart';
import 'package:collectiq_ai/features/ai/data/models/ai_image_upload_payload.dart';
import 'package:collectiq_ai/features/ai/data/services/noop_ai_backend_api_service.dart';
import 'package:collectiq_ai/features/ai/domain/clients/ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/domain/services/ai_backend_api_service.dart';

/// No-network backend client used until the real CollectIQ AI backend endpoint
/// integration is implemented.
///
/// This intentionally never calls a live backend. It lets provider wiring,
/// configuration, and offline-safe error handling be tested without exposing
/// API keys or making paid AI requests from Flutter.
class NoopAiBackendClient implements AiBackendClient {
  /// Creates a no-op backend client.
  const NoopAiBackendClient({
    required this.endpointUrl,
    this.apiService = const NoopAiBackendApiService(),
    this.payloadPreparer = const AiImagePayloadPreparer(),
    this.simulatedError,
    this.simulatedBackendError,
  });

  /// Future backend endpoint supplied by build config.
  final String endpointUrl;

  /// Future backend API service boundary.
  final AiBackendApiService apiService;

  /// Image payload validation/preparation helper.
  final AiImagePayloadPreparer payloadPreparer;

  /// Optional test hook for exercising error mapping without network calls.
  final AiBackendClientErrorType? simulatedError;

  /// Optional structured backend error used with [simulatedError].
  final AiBackendAnalysisError? simulatedBackendError;

  @override
  Future<AiBackendAnalysisResponse> analyze(
    AiBackendAnalysisRequest request,
  ) async {
    if (endpointUrl.trim().isEmpty) {
      throw AiBackendClientException.endpointMissing();
    }

    final legacySimulatedError = simulatedError;
    if (legacySimulatedError != null) {
      _throwSimulatedError(legacySimulatedError);
    }

    try {
      final imagePayload = await payloadPreparer.fromLocalFile(
        localFilePath: request.imagePath,
        imageSource: request.imageSource,
      );
      return await apiService.analyzeImage(
        request: request,
        imagePayload: imagePayload,
      );
    } on AiImagePayloadException catch (error) {
      throw AiBackendClientException.invalidImagePayload(error.message);
    }
  }

  Never _throwSimulatedError(AiBackendClientErrorType errorType) {
    switch (errorType) {
      case AiBackendClientErrorType.endpointMissing:
        throw AiBackendClientException.endpointMissing();
      case AiBackendClientErrorType.networkUnavailable:
        throw AiBackendClientException.networkUnavailable();
      case AiBackendClientErrorType.timeout:
        throw AiBackendClientException.timeout();
      case AiBackendClientErrorType.invalidResponse:
        throw AiBackendClientException.invalidResponse();
      case AiBackendClientErrorType.invalidImagePayload:
        throw AiBackendClientException.invalidImagePayload(
          'Selected image could not be prepared for AI analysis.',
        );
      case AiBackendClientErrorType.backendError:
        throw AiBackendClientException.backendError(
          simulatedBackendError ??
              const AiBackendAnalysisError(
                code: 'backend_ai_error',
                message: 'Backend AI analysis failed. Please try again.',
                retryable: true,
                details: {},
              ),
          statusCode: 502,
        );
      case AiBackendClientErrorType.malformedJson:
        throw AiBackendClientException.malformedJson();
      case AiBackendClientErrorType.unsupportedProvider:
        throw AiBackendClientException.unsupportedProvider(
          'Backend AI analysis',
        );
    }
  }
}
