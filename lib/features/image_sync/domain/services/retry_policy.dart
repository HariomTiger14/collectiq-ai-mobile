class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 4,
    this.baseDelay = const Duration(seconds: 30),
  });

  final int maxAttempts;
  final Duration baseDelay;

  bool shouldRetry(int nextAttempt) {
    return nextAttempt < maxAttempts;
  }

  DateTime nextRetryAt(int nextAttempt, DateTime now) {
    final multiplier = 1 << (nextAttempt - 1).clamp(0, 5);
    return now.add(baseDelay * multiplier);
  }
}
