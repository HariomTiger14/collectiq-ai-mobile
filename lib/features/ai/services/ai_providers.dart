import 'package:collectiq_ai/core/network/api_client.dart';
import 'package:collectiq_ai/features/ai/data/repositories/recognition_repository_impl.dart';
import 'package:collectiq_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:collectiq_ai/features/ai/services/ai_recognition_service.dart';
import 'package:collectiq_ai/features/ai/services/backend_ai_recognition_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the AI recognition service boundary.
final aiRecognitionServiceProvider = Provider<AIRecognitionService>((ref) {
  return BackendAIRecognitionService(ref.watch(apiClientProvider));
});

/// Provides the AI recognition repository.
final recognitionRepositoryProvider = Provider<RecognitionRepository>((ref) {
  return RecognitionRepositoryImpl(ref.watch(aiRecognitionServiceProvider));
});
