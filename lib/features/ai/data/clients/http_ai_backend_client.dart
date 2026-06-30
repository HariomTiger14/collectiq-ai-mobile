import 'package:collectiq_ai/features/ai/data/models/ai_backend_analysis_models.dart';
import 'package:collectiq_ai/features/ai/data/models/ai_backend_contract_validation.dart';
import 'package:collectiq_ai/features/ai/data/models/ai_image_upload_payload.dart';
import 'package:collectiq_ai/features/ai/domain/clients/ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/domain/services/ai_backend_api_service.dart';

/// HTTP backend client for server-side AI image analysis.
///
/// This client is opt-in through provider configuration. Mock mode keeps using
/// the no-network client so local development never calls a backend by default.
class HttpAiBackendClient implements AiBackendClient {
  /// Creates an HTTP backend client.
  const HttpAiBackendClient({
    required this.endpointUrl,
    required this.apiService,
    this.payloadPreparer = const AiImagePayloadPreparer(),
    this.readinessChecker = const AiBackendEndpointReadinessChecker(),
    this.isReleaseMode = false,
  });

  /// Backend/proxy endpoint supplied by build config.
  final String endpointUrl;

  /// Dio-backed API service boundary.
  final AiBackendApiService apiService;

  /// Image payload validation/preparation helper.
  final AiImagePayloadPreparer payloadPreparer;

  /// Endpoint readiness checker.
  final AiBackendEndpointReadinessChecker readinessChecker;

  /// Whether the app is running in release mode.
  final bool isReleaseMode;

  @override
  Future<AiBackendAnalysisResponse> analyze(
    AiBackendAnalysisRequest request,
  ) async {
    _validateEndpoint();

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

  void _validateEndpoint() {
    final readiness = readinessChecker.check(
      endpointUrl: endpointUrl,
      isReleaseMode: isReleaseMode,
    );
    if (!readiness.isConfigured) {
      throw AiBackendClientException.endpointMissing();
    }
    if (!readiness.isValid || !readiness.isReleaseSafe) {
      throw AiBackendClientException.invalidEndpoint(readiness.message);
    }
  }
}
