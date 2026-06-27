/// Base exception type for application-level errors.
class AppException implements Exception {
  /// Creates an application exception with a [message] and optional [code].
  const AppException({required this.message, this.code, this.cause});

  /// Human-readable exception message.
  final String message;

  /// Optional machine-readable exception code.
  final String? code;

  /// Optional original error or platform exception.
  final Object? cause;

  @override
  String toString() {
    final codeText = code == null ? '' : '[$code] ';
    return 'AppException: $codeText$message';
  }
}
