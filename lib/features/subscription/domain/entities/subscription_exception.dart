/// User-safe subscription and usage exception.
class SubscriptionException implements Exception {
  /// Creates a subscription exception.
  const SubscriptionException(this.message);

  /// Message safe for inline scan errors and Settings.
  final String message;

  @override
  String toString() => 'SubscriptionException: $message';
}
