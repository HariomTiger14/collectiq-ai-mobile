/// Supported backend environments for CollectIQ AI.
enum AppEnvironment {
  /// Local development and developer testing.
  development,

  /// Pre-production validation environment.
  staging,

  /// Live production environment.
  production,
}

/// Runtime environment configuration for API access.
class EnvironmentConfig {
  /// Creates an immutable environment configuration.
  const EnvironmentConfig({required this.environment});

  /// Active backend environment.
  final AppEnvironment environment;

  /// Base URL for the active environment.
  String get baseUrl => ApiConstants.baseUrlFor(environment);

  /// Creates environment configuration from a compile-time value.
  factory EnvironmentConfig.fromEnvironment() {
    const value = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );

    return EnvironmentConfig(environment: _parseEnvironment(value));
  }

  static AppEnvironment _parseEnvironment(String value) {
    return switch (value.toLowerCase()) {
      'production' || 'prod' => AppEnvironment.production,
      'staging' || 'stage' => AppEnvironment.staging,
      _ => AppEnvironment.development,
    };
  }
}

/// Centralized API constants for Azure backend integration.
class ApiConstants {
  const ApiConstants._();

  /// Connection timeout for API requests.
  static const connectionTimeout = Duration(seconds: 20);

  /// Receive timeout for API responses.
  static const receiveTimeout = Duration(seconds: 30);

  /// Scanner image upload endpoint.
  static const scannerUploadPath = '/scanner/images';

  /// Scanner recognition endpoint.
  static const scannerRecognitionPath = '/scanner/recognition';

  /// Scanner local AI analysis endpoint.
  static const scannerAnalyzePath = '/scanner/analyze';

  /// Portfolio endpoint.
  static const portfolioPath = '/portfolio';

  /// Portfolio item endpoint prefix.
  static const portfolioItemPath = '/portfolio/items';

  /// Returns the base URL for an environment.
  static String baseUrlFor(AppEnvironment environment) {
    return switch (environment) {
      AppEnvironment.development => 'http://127.0.0.1:8000',
      AppEnvironment.staging => 'https://staging-api.collectiq.ai',
      AppEnvironment.production => 'https://api.collectiq.ai',
    };
  }
}
