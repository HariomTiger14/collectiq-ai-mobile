/// User-safe billing exception.
class BillingException implements Exception {
  /// Creates a billing exception.
  const BillingException(this.message);

  /// User-safe message.
  final String message;

  @override
  String toString() => 'BillingException: $message';
}
