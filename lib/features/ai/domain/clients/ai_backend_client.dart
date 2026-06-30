import 'package:collectiq_ai/features/ai/data/models/ai_backend_analysis_models.dart';

/// Safe error categories for the future backend AI analysis client.
enum AiBackendClientErrorType {
  endpointMissing,
  networkUnavailable,
  timeout,
  invalidResponse,
  invalidImagePayload,
  backendError,
  malformedJson,
  unsupportedProvider,
}

/// Exception thrown by backend AI client implementations.
class AiBackendClientException implements Exception {
  /// Creates a backend client exception.
  const AiBackendClientException({
    required this.type,
    required this.message,
    this.statusCode,
    this.details = const {},
  });

  /// Missing backend endpoint configuration.
  factory AiBackendClientException.endpointMissing() {
    return const AiBackendClientException(
      type: AiBackendClientErrorType.endpointMissing,
      message:
          'Backend AI endpoint not configured. OpenAI Vision must run through the CollectIQ AI backend.',
    );
  }

  /// Device or backend network is unavailable.
  factory AiBackendClientException.networkUnavailable() {
    return const AiBackendClientException(
      type: AiBackendClientErrorType.networkUnavailable,
      message:
          'AI analysis is unavailable offline. Check your connection and try again.',
    );
  }

  /// Backend request timed out.
  factory AiBackendClientException.timeout() {
    return const AiBackendClientException(
      type: AiBackendClientErrorType.timeout,
      message:
          'AI analysis timed out. Please check your connection and try again.',
    );
  }

  /// Backend returned a response the app cannot use.
  factory AiBackendClientException.invalidResponse() {
    return const AiBackendClientException(
      type: AiBackendClientErrorType.invalidResponse,
      message: 'AI analysis returned an invalid response. Please try again.',
    );
  }

  /// Selected image cannot be prepared for upload.
  factory AiBackendClientException.invalidImagePayload(String message) {
    return AiBackendClientException(
      type: AiBackendClientErrorType.invalidImagePayload,
      message: message,
    );
  }

  /// Backend returned a structured error response.
  factory AiBackendClientException.backendError(
    AiBackendAnalysisError error, {
    int? statusCode,
  }) {
    return AiBackendClientException(
      type: AiBackendClientErrorType.backendError,
      message: error.message,
      statusCode: statusCode,
      details: error.toJson(),
    );
  }

  /// Backend returned malformed JSON.
  factory AiBackendClientException.malformedJson() {
    return const AiBackendClientException(
      type: AiBackendClientErrorType.malformedJson,
      message: 'AI analysis response could not be read. Please try again.',
    );
  }

  /// Selected provider is not supported by the mobile client yet.
  factory AiBackendClientException.unsupportedProvider(String providerName) {
    return AiBackendClientException(
      type: AiBackendClientErrorType.unsupportedProvider,
      message:
          '$providerName is not connected yet. Switch AI_ANALYSIS_PROVIDER back to mock.',
    );
  }

  /// Error category used by callers and tests.
  final AiBackendClientErrorType type;

  /// User-safe message for the scan error panel.
  final String message;

  /// Optional HTTP status code for future real clients.
  final int? statusCode;

  /// Optional non-secret diagnostic details.
  final Map<String, dynamic> details;

  @override
  String toString() => 'AiBackendClientException($type): $message';
}

/// Future backend client boundary for server-side AI image analysis.
///
/// Implementations must call only the CollectIQ AI backend/proxy. API keys for
/// OpenAI, Gemini, pricing providers, or marketplaces must stay server-side.
abstract interface class AiBackendClient {
  /// Sends a future backend analysis request and returns the parsed response.
  Future<AiBackendAnalysisResponse> analyze(AiBackendAnalysisRequest request);
}
