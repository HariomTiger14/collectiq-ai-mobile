import 'package:flutter/foundation.dart';

/// Supported backend environments for CollectIQ AI.
enum AppEnvironment {
  /// Local development and developer testing.
  development,

  /// Phone/system integration testing against safe non-production services.
  sit,

  /// Pre-production validation environment.
  staging,

  /// Live production environment.
  production,
}

/// Runtime environment configuration for API access.
class EnvironmentConfig {
  /// Creates an immutable environment configuration.
  const EnvironmentConfig({
    required this.environment,
    this.baseUrlOverride = '',
  });

  /// Active backend environment.
  final AppEnvironment environment;

  /// Optional backend base URL supplied by local ignored config.
  final String baseUrlOverride;

  /// Base URL for the active environment.
  String get baseUrl {
    final override = baseUrlOverride.trim();
    if (override.isNotEmpty) {
      return override;
    }
    return ApiConstants.baseUrlFor(environment);
  }

  /// Creates environment configuration from a compile-time value.
  factory EnvironmentConfig.fromEnvironment() {
    const value = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const legacyApiBaseUrl = String.fromEnvironment('COLLECTIQ_API_BASE_URL');
    final baseUrlOverride = apiBaseUrl.trim().isNotEmpty
        ? apiBaseUrl
        : legacyApiBaseUrl;

    return EnvironmentConfig(
      environment: _parseEnvironment(value),
      baseUrlOverride: baseUrlOverride,
    );
  }

  static AppEnvironment _parseEnvironment(String value) {
    return switch (value.toLowerCase()) {
      'production' || 'prod' => AppEnvironment.production,
      'sit' || 'system-test' || 'system_integration_test' => AppEnvironment.sit,
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

  /// Production analyzer endpoint.
  static const analyzerPath = '/analyze';

  /// Portfolio endpoint.
  static const portfolioPath = '/portfolio';

  /// Portfolio item endpoint prefix.
  static const portfolioItemPath = '/portfolio/items';

  /// Returns the base URL for an environment.
  static String baseUrlFor(AppEnvironment environment) {
    return switch (environment) {
      AppEnvironment.development => _developmentBaseUrl,
      AppEnvironment.sit => _developmentBaseUrl,
      AppEnvironment.staging => 'https://staging-api.collectiq.ai',
      AppEnvironment.production => 'https://api.collectiq.ai',
    };
  }

  static String get _developmentBaseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.0.81:8000';
    }

    return 'http://127.0.0.1:8000';
  }
}
