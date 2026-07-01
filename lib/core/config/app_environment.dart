/// Runtime environments supported by CollectIQ AI.
///
/// The app defaults to [AppEnvironment.local] so developer and tester builds
/// never connect to cloud services unless explicitly configured.
enum AppEnvironment {
  local,
  dev,
  sit,
  staging,
  prod;

  String get label {
    return switch (this) {
      AppEnvironment.local => 'Local',
      AppEnvironment.dev => 'Development',
      AppEnvironment.sit => 'SIT',
      AppEnvironment.staging => 'Staging',
      AppEnvironment.prod => 'Production',
    };
  }

  bool get isProduction => this == AppEnvironment.prod;

  bool get allowsNonProductionCloud =>
      this == AppEnvironment.dev ||
      this == AppEnvironment.sit ||
      this == AppEnvironment.staging;

  static AppEnvironment parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'dev' || 'development' => AppEnvironment.dev,
      'sit' || 'system-test' || 'system_integration_test' => AppEnvironment.sit,
      'stage' || 'staging' => AppEnvironment.staging,
      'prod' || 'production' => AppEnvironment.prod,
      _ => AppEnvironment.local,
    };
  }
}
