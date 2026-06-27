import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:collectiq_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:collectiq_ai/features/ai/services/ai_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Immutable presentation state for collectible recognition.
class RecognitionState {
  /// Creates recognition state.
  const RecognitionState({
    this.isLoading = false,
    this.result,
    this.errorMessage,
  });

  /// Whether recognition is currently running.
  final bool isLoading;

  /// Latest recognition result.
  final RecognitionResult? result;

  /// Latest user-safe recognition error message.
  final String? errorMessage;

  /// Creates a copy of the current recognition state.
  RecognitionState copyWith({
    bool? isLoading,
    RecognitionResult? result,
    String? errorMessage,
    bool clearResult = false,
    bool clearErrorMessage = false,
  }) {
    return RecognitionState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : result ?? this.result,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

/// Controller that coordinates AI recognition workflow state.
class RecognitionController extends Notifier<RecognitionState> {
  late final RecognitionRepository _recognitionRepository;

  @override
  RecognitionState build() {
    _recognitionRepository = ref.watch(recognitionRepositoryProvider);
    return const RecognitionState();
  }

  /// Runs recognition for the provided image path.
  Future<RecognitionResult> recognizeCollectible(String imagePath) async {
    state = state.copyWith(
      isLoading: true,
      clearResult: true,
      clearErrorMessage: true,
    );

    try {
      final result = await _recognitionRepository.recognizeCollectible(
        XFile(imagePath),
      );
      state = state.copyWith(isLoading: false, result: result);
      return result;
    } on Exception catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      rethrow;
    }
  }
}

/// Provides AI recognition workflow state and actions.
final recognitionControllerProvider =
    NotifierProvider<RecognitionController, RecognitionState>(
      RecognitionController.new,
    );
