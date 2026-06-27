/// Represents a recoverable application failure that can be displayed or logged.
class Failure {
  /// Creates a failure with a user-safe [message] and optional [code].
  const Failure({required this.message, this.code});

  /// Human-readable failure message.
  final String message;

  /// Optional machine-readable failure code.
  final String? code;
}
