import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:image_picker/image_picker.dart';

/// Repository contract for AI collectible recognition.
abstract interface class RecognitionRepository {
  /// Recognizes a collectible from a selected image.
  Future<RecognitionResult> recognizeCollectible(XFile image);
}
