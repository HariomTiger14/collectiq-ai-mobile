import 'package:flutter/foundation.dart';

import '../config/app_environment.dart';

// AppEnvironment is defined once, in core/config/app_environment.dart. It used
// to be declared a second time here with different members (development /
// production instead of local / dev / prod), and both copies independently
// parsed the same APP_ENV flag with different fallbacks -- so a build could be
// "production" to one half of the app and something else to the other.
// Re-exported so existing importers of api_constants.dart keep resolving it.
export '../config/app_environment.dart' show AppEnvironment;

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
      environment: AppEnvironment.parse(value),
      baseUrlOverride: baseUrlOverride,
    );
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

  /// Pricing-only quote endpoint for user-confirmed scan details.
  static const pricingQuotePath = '/api/pricing/quote';

  /// Pricing reprice endpoint for corrected item identity.
  static const pricingRepricePath = '/api/pricing/reprice';

  /// Price/catalog search endpoint for Discover.
  static const pricingCatalogSearchPath = '/api/pricing/catalog/search';

  /// Price/catalog detail endpoint prefix.
  static const pricingCatalogDetailPath = '/api/pricing/catalog';

  /// FX rate history endpoint, used to convert stored values into the
  /// user's chosen display currency.
  static const pricingFxRatesPath = '/api/pricing/fx-rates';

  /// Portfolio endpoint.
  static const portfolioPath = '/portfolio';

  /// Portfolio item endpoint prefix.
  static const portfolioItemPath = '/portfolio/items';

  /// Server-side signup-start guard endpoint.
  static const authSignupStartPath = '/auth/signup-start';

  /// Returns the base URL for an environment.
  static String baseUrlFor(AppEnvironment environment) {
    return switch (environment) {
      AppEnvironment.local || AppEnvironment.dev => _developmentBaseUrl,
      AppEnvironment.sit => 'https://api-sit.packlox.com',
      // TODO: both of these are stale CollectIQ domains that do not resolve.
      // They must become real packlox.com hosts before a staging or production
      // build can talk to anything.
      AppEnvironment.staging => 'https://staging-api.collectiq.ai',
      AppEnvironment.prod => 'https://api.collectiq.ai',
    };
  }

  static String get _developmentBaseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.0.81:8000';
    }

    return 'http://127.0.0.1:8000';
  }
}
