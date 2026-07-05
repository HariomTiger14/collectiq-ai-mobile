import 'package:collectiq_ai/core/network/api_client.dart';
import 'package:collectiq_ai/features/ai/data/analyzer/analyzer_provider_factory.dart';
import 'package:collectiq_ai/features/ai/data/clients/http_ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/data/clients/noop_ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/data/models/ai_backend_contract_validation.dart';
import 'package:collectiq_ai/features/ai/data/providers/ai_analysis_provider_factory.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_models.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_provider.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_service.dart';
import 'package:collectiq_ai/features/ai/data/repositories/recognition_repository_impl.dart';
import 'package:collectiq_ai/features/ai/data/services/dio_ai_backend_api_service.dart';
import 'package:collectiq_ai/features/ai/data/services/noop_ai_backend_api_service.dart';
import 'package:collectiq_ai/features/ai/domain/clients/ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:collectiq_ai/features/ai/domain/services/ai_backend_api_service.dart';
import 'package:collectiq_ai/features/ai/services/ai_recognition_service.dart';
import 'package:collectiq_ai/features/ai/services/backend_ai_recognition_service.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the AI recognition service boundary.
final aiRecognitionServiceProvider = Provider<AIRecognitionService>((ref) {
  return BackendAIRecognitionService(ref.watch(apiClientProvider));
});

/// Provides the AI recognition repository.
final recognitionRepositoryProvider = Provider<RecognitionRepository>((ref) {
  return RecognitionRepositoryImpl(ref.watch(aiRecognitionServiceProvider));
});

/// Provides compile-time AI analysis provider configuration.
final aiAnalysisProviderConfigProvider = Provider<AiAnalysisProviderConfig>((
  ref,
) {
  return AiAnalysisProviderConfig.fromEnvironment();
});

/// Provides the future backend API service.
///
/// Mock mode always uses the no-network implementation. The Dio-backed service
/// is only enabled for the backend/OpenAI placeholder when the endpoint is
/// configured and safe for the current build mode.
final aiBackendApiServiceProvider = Provider<AiBackendApiService>((ref) {
  final config = ref.watch(aiAnalysisProviderConfigProvider);
  final readiness = const AiBackendEndpointReadinessChecker().check(
    endpointUrl: config.backendAnalysisEndpointUrl,
    isReleaseMode: kReleaseMode,
  );
  if (readiness.isConfigured && readiness.isValid && readiness.isReleaseSafe) {
    return DioAiBackendApiService(
      endpointUrl: config.backendAnalysisEndpointUrl,
      isReleaseMode: kReleaseMode,
    );
  }

  return const NoopAiBackendApiService();
});

/// Provides the future backend AI client.
///
/// Mock mode remains intentionally no-network. The HTTP client is selected only
/// when a backend-only provider is configured, and it blocks unsafe endpoints
/// before transport.
final aiBackendClientProvider = Provider<AiBackendClient>((ref) {
  final config = ref.watch(aiAnalysisProviderConfigProvider);
  final readiness = const AiBackendEndpointReadinessChecker().check(
    endpointUrl: config.backendAnalysisEndpointUrl,
    isReleaseMode: kReleaseMode,
  );
  if (readiness.isConfigured && readiness.isValid && readiness.isReleaseSafe) {
    return HttpAiBackendClient(
      endpointUrl: config.backendAnalysisEndpointUrl,
      apiService: ref.watch(aiBackendApiServiceProvider),
      isReleaseMode: kReleaseMode,
    );
  }

  return NoopAiBackendClient(
    endpointUrl: config.backendAnalysisEndpointUrl,
    apiService: ref.watch(aiBackendApiServiceProvider),
  );
});

/// Provides the configured high-level scan analysis provider.
final aiAnalysisProviderProvider = Provider<AiAnalysisProvider>((ref) {
  return const AiAnalysisProviderFactory().create(
    config: ref.watch(aiAnalysisProviderConfigProvider),
    recognitionRepository: ref.watch(recognitionRepositoryProvider),
    marketProvider: ref.watch(marketProviderProvider),
    backendClient: ref.watch(aiBackendClientProvider),
  );
});

/// Provides the production analyzer configuration.
final analyzerConfigProvider = Provider<AnalyzerConfig>((ref) {
  return AnalyzerConfig.fromEnvironment();
});

/// Provides the configured analyzer provider.
final analyzerProviderProvider = Provider<AnalyzerProvider>((ref) {
  final aiConfig = ref.watch(aiAnalysisProviderConfigProvider);
  return const AnalyzerProviderFactory().create(
    config: ref.watch(analyzerConfigProvider),
    legacyAnalysisProvider: ref.watch(aiAnalysisProviderProvider),
    backendClient: ref.watch(aiBackendClientProvider),
    useBackendContract: aiConfig.hasBackendAnalysisEndpoint,
  );
});

/// Provides the only analyzer boundary used by app workflow code.
final analyzerServiceProvider = Provider<AnalyzerService>((ref) {
  return AnalyzerService(
    provider: ref.watch(analyzerProviderProvider),
    config: ref.watch(analyzerConfigProvider),
  );
});
