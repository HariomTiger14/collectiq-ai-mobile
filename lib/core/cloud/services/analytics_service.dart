abstract interface class AnalyticsService {
  String get providerName;

  Future<void> trackEvent(
    String name, {
    Map<String, Object?> properties = const {},
  });
}
