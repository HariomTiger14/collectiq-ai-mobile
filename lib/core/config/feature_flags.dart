/// Feature flags controlling non-production cloud integrations.
///
/// Every flag defaults to false. Future service implementations must opt in
/// explicitly through environment/build configuration.
class FeatureFlags {
  const FeatureFlags({
    this.useCloudAuth = false,
    this.useCloudPortfolioSync = false,
    this.useCloudImageStorage = false,
    this.useCrashReporting = false,
    this.useAnalytics = false,
    this.useRealAiProvider = false,
  });

  final bool useCloudAuth;
  final bool useCloudPortfolioSync;
  final bool useCloudImageStorage;
  final bool useCrashReporting;
  final bool useAnalytics;
  final bool useRealAiProvider;

  factory FeatureFlags.fromEnvironment() {
    return const FeatureFlags(
      useCloudAuth:
          bool.fromEnvironment('USE_CLOUD_AUTH') ||
          bool.fromEnvironment('COLLECTIQ_USE_CLOUD_AUTH'),
      useCloudPortfolioSync:
          bool.fromEnvironment('USE_CLOUD_PORTFOLIO_SYNC') ||
          bool.fromEnvironment('COLLECTIQ_USE_CLOUD_PORTFOLIO_SYNC'),
      useCloudImageStorage:
          bool.fromEnvironment('USE_CLOUD_IMAGE_STORAGE') ||
          bool.fromEnvironment('COLLECTIQ_USE_CLOUD_IMAGE_STORAGE'),
      useCrashReporting:
          bool.fromEnvironment('USE_CRASH_REPORTING') ||
          bool.fromEnvironment('COLLECTIQ_USE_CRASH_REPORTING'),
      useAnalytics:
          bool.fromEnvironment('USE_ANALYTICS') ||
          bool.fromEnvironment('COLLECTIQ_USE_ANALYTICS'),
      useRealAiProvider:
          bool.fromEnvironment('USE_REAL_AI_PROVIDER') ||
          bool.fromEnvironment('COLLECTIQ_USE_REAL_AI_PROVIDER'),
    );
  }

  factory FeatureFlags.fromRawMap(Map<String, String> values) {
    bool enabled(String key) {
      return switch (values[key]?.trim().toLowerCase()) {
        'true' || '1' || 'yes' || 'y' || 'on' => true,
        _ => false,
      };
    }

    return FeatureFlags(
      useCloudAuth:
          enabled('USE_CLOUD_AUTH') || enabled('COLLECTIQ_USE_CLOUD_AUTH'),
      useCloudPortfolioSync:
          enabled('USE_CLOUD_PORTFOLIO_SYNC') ||
          enabled('COLLECTIQ_USE_CLOUD_PORTFOLIO_SYNC'),
      useCloudImageStorage:
          enabled('USE_CLOUD_IMAGE_STORAGE') ||
          enabled('COLLECTIQ_USE_CLOUD_IMAGE_STORAGE'),
      useCrashReporting:
          enabled('USE_CRASH_REPORTING') ||
          enabled('COLLECTIQ_USE_CRASH_REPORTING'),
      useAnalytics:
          enabled('USE_ANALYTICS') || enabled('COLLECTIQ_USE_ANALYTICS'),
      useRealAiProvider:
          enabled('USE_REAL_AI_PROVIDER') ||
          enabled('COLLECTIQ_USE_REAL_AI_PROVIDER'),
    );
  }

  bool get anyCloudFeatureEnabled =>
      useCloudAuth ||
      useCloudPortfolioSync ||
      useCloudImageStorage ||
      useCrashReporting ||
      useAnalytics ||
      useRealAiProvider;

  Map<String, bool> toMap() {
    return {
      'useCloudAuth': useCloudAuth,
      'useCloudPortfolioSync': useCloudPortfolioSync,
      'useCloudImageStorage': useCloudImageStorage,
      'useCrashReporting': useCrashReporting,
      'useAnalytics': useAnalytics,
      'useRealAiProvider': useRealAiProvider,
    };
  }
}
