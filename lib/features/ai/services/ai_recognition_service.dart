import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:image_picker/image_picker.dart';

/// Service boundary for future AI provider integrations.
///
/// Implementations will handle provider-specific image recognition once a
/// production AI backend is selected.
abstract interface class AIRecognitionService {
  /// Recognizes a collectible from a selected image.
  Future<RecognitionResult> recognizeCollectible(XFile image);
}
