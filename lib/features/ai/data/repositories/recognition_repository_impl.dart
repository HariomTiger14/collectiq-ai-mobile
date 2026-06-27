import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:collectiq_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:collectiq_ai/features/ai/services/ai_recognition_service.dart';
import 'package:image_picker/image_picker.dart';

/// Stub recognition repository used until a real AI provider is connected.
class RecognitionRepositoryImpl implements RecognitionRepository {
  /// Creates a recognition repository implementation.
  const RecognitionRepositoryImpl(this._service);

  final AIRecognitionService _service;

  @override
  Future<RecognitionResult> recognizeCollectible(XFile image) {
    return _service.recognizeCollectible(image);
  }
}
