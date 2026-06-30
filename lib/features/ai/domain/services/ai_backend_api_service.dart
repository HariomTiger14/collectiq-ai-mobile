import 'package:collectiq_ai/features/ai/data/models/ai_backend_analysis_models.dart';
import 'package:collectiq_ai/features/ai/data/models/ai_image_upload_payload.dart';

/// Future API-service boundary for backend AI image analysis.
///
/// Implementations must call only the CollectIQ AI backend/proxy. Mobile code
/// must never call OpenAI, Gemini, marketplace, or pricing APIs directly.
abstract interface class AiBackendApiService {
  /// Future method shape for backend image analysis.
  Future<AiBackendAnalysisResponse> analyzeImage({
    required AiBackendAnalysisRequest request,
    required AiImageUploadPayload imagePayload,
  });
}
