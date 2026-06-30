import 'package:collectiq_ai/core/network/api_client.dart';
import 'package:collectiq_ai/features/ai/data/clients/noop_ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/data/providers/ai_analysis_provider_factory.dart';
import 'package:collectiq_ai/features/ai/data/repositories/recognition_repository_impl.dart';
import 'package:collectiq_ai/features/ai/data/services/noop_ai_backend_api_service.dart';
import 'package:collectiq_ai/features/ai/domain/clients/ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:collectiq_ai/features/ai/domain/services/ai_backend_api_service.dart';
import 'package:collectiq_ai/features/ai/services/ai_recognition_service.dart';
import 'package:collectiq_ai/features/ai/services/backend_ai_recognition_service.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
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
/// This is a no-network implementation until the CollectIQ backend/proxy is
/// ready.
final aiBackendApiServiceProvider = Provider<AiBackendApiService>((ref) {
  return const NoopAiBackendApiService();
});

/// Provides the future backend AI client.
///
/// The current implementation is intentionally no-network. It validates
/// configuration and returns safe errors until the backend/proxy integration is
/// implemented.
final aiBackendClientProvider = Provider<AiBackendClient>((ref) {
  final config = ref.watch(aiAnalysisProviderConfigProvider);
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
