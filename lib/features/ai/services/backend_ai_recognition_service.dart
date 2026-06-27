import 'package:collectiq_ai/core/network/api_client.dart';
import 'package:collectiq_ai/core/network/api_constants.dart';
import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:collectiq_ai/features/ai/services/ai_recognition_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

/// AI recognition service that calls the local FastAPI backend.
class BackendAIRecognitionService implements AIRecognitionService {
  /// Creates a backend AI recognition service.
  const BackendAIRecognitionService(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<RecognitionResult> recognizeCollectible(XFile image) async {
    final formData = FormData.fromMap({'image': await _multipartImage(image)});

    final response = await _apiClient.post(
      ApiConstants.scannerAnalyzePath,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const AIRecognitionException('Invalid AI service response.');
    }

    if (data['success'] != true) {
      throw const AIRecognitionException('AI service did not complete.');
    }

    try {
      return RecognitionResult.fromJson(data);
    } on Object catch (error) {
      throw AIRecognitionException('Invalid AI service response: $error');
    }
  }

  Future<MultipartFile> _multipartImage(XFile image) async {
    final filename = _filenameFor(image);
    final contentType = _contentTypeFor(filename);

    if (kIsWeb || image.path.isEmpty) {
      return MultipartFile.fromBytes(
        await image.readAsBytes(),
        filename: filename,
        contentType: contentType,
      );
    }

    return MultipartFile.fromFile(
      image.path,
      filename: filename,
      contentType: contentType,
    );
  }

  String _filenameFor(XFile image) {
    if (image.name.isNotEmpty) {
      return image.name;
    }

    final segments = image.path.split(RegExp(r'[\\/]'));
    final filename = segments.isEmpty ? '' : segments.last;
    return filename.isEmpty ? 'scanner-image.jpg' : filename;
  }

  MediaType _contentTypeFor(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    if (extension == 'png') {
      return MediaType('image', 'png');
    }

    return MediaType('image', 'jpeg');
  }
}

/// Exception thrown when AI recognition cannot be completed.
class AIRecognitionException implements Exception {
  /// Creates an AI recognition exception.
  const AIRecognitionException(this.message);

  /// Failure message for diagnostics.
  final String message;

  @override
  String toString() => 'AIRecognitionException: $message';
}
