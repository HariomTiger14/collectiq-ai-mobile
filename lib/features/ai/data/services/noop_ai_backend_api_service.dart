import 'package:collectiq_ai/features/ai/data/models/ai_backend_analysis_models.dart';
import 'package:collectiq_ai/features/ai/data/models/ai_image_upload_payload.dart';
import 'package:collectiq_ai/features/ai/domain/clients/ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/domain/services/ai_backend_api_service.dart';

/// No-network API service used until the real backend transport exists.
class NoopAiBackendApiService implements AiBackendApiService {
  /// Creates a no-op backend API service.
  const NoopAiBackendApiService({
    this.injectedResponse,
    this.simulatedError,
    this.simulatedBackendError,
  });

  /// Optional test response. When set, no error is thrown.
  final AiBackendAnalysisResponse? injectedResponse;

  /// Optional test hook for exercising API-service error mapping.
  final AiBackendClientErrorType? simulatedError;

  /// Optional structured backend error used with [simulatedError].
  final AiBackendAnalysisError? simulatedBackendError;

  @override
  Future<AiBackendAnalysisResponse> analyzeImage({
    required AiBackendAnalysisRequest request,
    required AiImageUploadPayload imagePayload,
  }) async {
    final response = injectedResponse;
    if (response != null) {
      return response;
    }

    final errorType =
        simulatedError ?? AiBackendClientErrorType.endpointMissing;
    switch (errorType) {
      case AiBackendClientErrorType.endpointMissing:
        throw AiBackendClientException.endpointMissing();
      case AiBackendClientErrorType.networkUnavailable:
        throw AiBackendClientException.networkUnavailable();
      case AiBackendClientErrorType.timeout:
        throw AiBackendClientException.timeout();
      case AiBackendClientErrorType.invalidEndpoint:
        throw AiBackendClientException.invalidEndpoint(
          'Backend AI endpoint is not valid for this build.',
        );
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
