import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:flutter/foundation.dart';

class CloudAppStartup {
  const CloudAppStartup({required this.registry});

  final CloudServiceRegistry registry;

  Future<void> run() async {
    await registry.analyticsService.trackEvent('app_started');

    final environment = registry.config.environment;
    final flags = registry.config.featureFlags;
    if (!registry.config.allowsCloudServices) {
      return;
    }
    if (flags.anyCloudFeatureEnabled) {
      try {
        await registry.remoteConfigService.refresh();
      } on Object catch (error) {
        debugPrint(
          '[CloudAppStartup] remote config validation warning: $error',
        );
      }
    }
    if (flags.useCloudPortfolioSync || flags.useCloudImageStorage) {
      try {
        final status = await registry.cloudPortfolioSyncService.getSyncStatus();
        if (!status.enabled) {
          debugPrint(
            '[CloudAppStartup] cloud sync unavailable: ${status.message}',
          );
        }
      } on Object catch (error) {
        debugPrint(
          '[CloudAppStartup] Supabase sync validation warning: $error',
        );
      }
    }
    if (!flags.useCloudAuth) {
      return;
    }
    if (environment == AppEnvironment.sit ||
        environment == AppEnvironment.prod) {
      await registry.analyticsService.trackEvent('sit_email_auth_required');
      return;
    }

    try {
      await registry.authService.signInAnonymously();
      await registry.analyticsService.trackEvent('anonymous_auth_success');
    } on Object catch (error) {
      await registry.analyticsService.trackEvent(
        'anonymous_auth_failed',
        properties: {'error': error.runtimeType.toString()},
      );
    }
  }
}
