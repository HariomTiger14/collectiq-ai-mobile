import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_environment.dart';
import 'feature_flags.dart';

final environmentConfigProvider = Provider<EnvironmentConfig>((ref) {
  return EnvironmentConfig.fromEnvironment();
});

/// Top-level non-production cloud configuration.
///
/// This config intentionally contains no secrets. Credentials and provider
/// setup belong in future service-specific adapters and must be supplied
/// through environment/build configuration, never hardcoded in source.
class EnvironmentConfig {
  const EnvironmentConfig({
    required this.environment,
    this.featureFlags = const FeatureFlags(),
  });

  final AppEnvironment environment;
  final FeatureFlags featureFlags;

  factory EnvironmentConfig.local({
    FeatureFlags featureFlags = const FeatureFlags(),
  }) {
    return EnvironmentConfig(
      environment: AppEnvironment.local,
      featureFlags: featureFlags,
    );
  }

  factory EnvironmentConfig.fromEnvironment() {
    const appEnvironment = String.fromEnvironment('APP_ENV');
    const legacyEnvironment = String.fromEnvironment(
      'COLLECTIQ_ENV',
      defaultValue: 'local',
    );

    return EnvironmentConfig.fromValues(
      appEnvironment: appEnvironment,
      legacyEnvironment: legacyEnvironment,
      featureFlags: FeatureFlags.fromEnvironment(),
    );
  }

  factory EnvironmentConfig.fromValues({
    String appEnvironment = '',
    String legacyEnvironment = 'local',
    FeatureFlags featureFlags = const FeatureFlags(),
  }) {
    final rawEnvironment = appEnvironment.trim().isNotEmpty
        ? appEnvironment
        : legacyEnvironment;
    return EnvironmentConfig(
      environment: AppEnvironment.parse(rawEnvironment),
      featureFlags: featureFlags,
    );
  }

  bool get isLocal => environment == AppEnvironment.local;

  bool get allowsProductionServices {
    return environment.isProduction &&
        featureFlags.useCloudAuth &&
        featureFlags.useCloudPortfolioSync &&
        featureFlags.useCloudImageStorage;
  }

  bool get allowsCloudServices {
    return environment.allowsNonProductionCloud || allowsProductionServices;
  }

  String get cloudModeLabel {
    if (!featureFlags.anyCloudFeatureEnabled) {
      return 'Local mock services';
    }
    return '${environment.label} cloud flags enabled';
  }
}
