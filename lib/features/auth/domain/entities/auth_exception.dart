/// User-safe auth exception for provider and cloud auth failures.
class AuthException implements Exception {
  /// Creates an auth exception.
  const AuthException(this.message);

  /// Message safe to show in Settings.
  final String message;

  @override
  String toString() => 'AuthException: $message';
}
