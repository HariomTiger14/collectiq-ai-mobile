import 'package:dio/dio.dart';

/// Exception thrown by the networking layer.
class NetworkException implements Exception {
  /// Creates a network exception.
  const NetworkException({required this.message, this.code, this.statusCode});

  /// User-safe message.
  final String message;

  /// Optional machine-readable code.
  final String? code;

  /// Optional HTTP status code.
  final int? statusCode;

  /// Creates a network exception from a Dio error.
  factory NetworkException.fromDioException(DioException exception) {
    return NetworkException(
      message: _messageFor(exception),
      code: exception.type.name,
      statusCode: exception.response?.statusCode,
    );
  }

  static String _messageFor(DioException exception) {
    return switch (exception.type) {
      DioExceptionType.connectionTimeout => 'Connection timed out.',
      DioExceptionType.sendTimeout => 'Request timed out.',
      DioExceptionType.receiveTimeout => 'Response timed out.',
      DioExceptionType.badCertificate => 'Secure connection failed.',
      DioExceptionType.badResponse => 'Unexpected server response.',
      DioExceptionType.cancel => 'Request was cancelled.',
      DioExceptionType.connectionError => 'Network connection failed.',
      DioExceptionType.unknown => 'Unexpected network error.',
    };
  }

  @override
  String toString() => 'NetworkException($code): $message';
}
