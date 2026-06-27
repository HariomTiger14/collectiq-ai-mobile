import 'package:collectiq_ai/core/errors/app_exception.dart';

/// Exception type for Scanner feature failures.
class ScannerException extends AppException {
  /// Creates a scanner exception with a [message] and optional [code].
  const ScannerException({required super.message, super.code, super.cause});
}
