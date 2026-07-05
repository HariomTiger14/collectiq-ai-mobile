import 'package:flutter_test/flutter_test.dart';

import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/cloud/services/noop_cloud_services.dart';
import 'package:collectiq_ai/core/cloud/supabase/supabase_auth_service.dart';
import 'package:collectiq_ai/core/cloud/supabase/supabase_bootstrap.dart';
import 'package:collectiq_ai/core/cloud/supabase/supabase_cloud_portfolio_sync_service.dart';
import 'package:collectiq_ai/core/cloud/supabase/supabase_cloud_storage_service.dart';
import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/core/config/feature_flags.dart';
import 'package:collectiq_ai/core/network/api_constants.dart' as network_config;

void main() {
  group('AppEnvironment', () {
    test('defaults unknown values to local', () {
      expect(AppEnvironment.parse(''), AppEnvironment.local);
      expect(AppEnvironment.parse('sandbox'), AppEnvironment.local);
    });

    test('parses supported environment aliases', () {
      expect(AppEnvironment.parse('local'), AppEnvironment.local);
      expect(AppEnvironment.parse('development'), AppEnvironment.dev);
      expect(AppEnvironment.parse('dev'), AppEnvironment.dev);
      expect(AppEnvironment.parse('sit'), AppEnvironment.sit);
      expect(
        AppEnvironment.parse('system_integration_test'),
        AppEnvironment.sit,
      );
      expect(AppEnvironment.parse('staging'), AppEnvironment.staging);
      expect(AppEnvironment.parse('stage'), AppEnvironment.staging);
      expect(AppEnvironment.parse('production'), AppEnvironment.prod);
      expect(AppEnvironment.parse('prod'), AppEnvironment.prod);
    });
  });

  group('FeatureFlags', () {
    test('defaults every cloud flag to false', () {
      const flags = FeatureFlags();

      expect(flags.useCloudAuth, isFalse);
      expect(flags.useCloudPortfolioSync, isFalse);
      expect(flags.useCloudImageStorage, isFalse);
      expect(flags.useCrashReporting, isFalse);
      expect(flags.useAnalytics, isFalse);
      expect(flags.useRealAiProvider, isFalse);
      expect(flags.anyCloudFeatureEnabled, isFalse);
    });

    test('reads dev feature flags from public dart-define names', () {
      final flags = FeatureFlags.fromRawMap({
        'USE_CLOUD_AUTH': 'true',
        'USE_CLOUD_PORTFOLIO_SYNC': 'true',
        'USE_CLOUD_IMAGE_STORAGE': 'true',
        'USE_ANALYTICS': 'true',
        'USE_CRASH_REPORTING': 'true',
        'USE_REAL_AI_PROVIDER': 'false',
      });

      expect(flags.useCloudAuth, isTrue);
      expect(flags.useCloudPortfolioSync, isTrue);
      expect(flags.useCloudImageStorage, isTrue);
      expect(flags.useAnalytics, isTrue);
      expect(flags.useCrashReporting, isTrue);
      expect(flags.useRealAiProvider, isFalse);
    });

    test('keeps legacy CollectIQ flag names as fallback', () {
      final flags = FeatureFlags.fromRawMap({
        'COLLECTIQ_USE_CLOUD_AUTH': 'true',
      });

      expect(flags.useCloudAuth, isTrue);
    });
  });

  group('EnvironmentConfig', () {
    test('fromEnvironment defaults to local with no cloud flags', () {
      final config = EnvironmentConfig.fromEnvironment();

      expect(config.environment, AppEnvironment.local);
      expect(config.isLocal, isTrue);
      expect(config.featureFlags.anyCloudFeatureEnabled, isFalse);
      expect(config.cloudModeLabel, 'Local mock services');
    });

    test('APP_ENV selects dev cloud environment', () {
      final config = EnvironmentConfig.fromValues(appEnvironment: 'dev');

      expect(config.environment, AppEnvironment.dev);
      expect(config.isLocal, isFalse);
    });

    test('APP_ENV selects SIT cloud environment', () {
      final config = EnvironmentConfig.fromValues(appEnvironment: 'sit');

      expect(config.environment, AppEnvironment.sit);
      expect(config.environment.label, 'SIT');
      expect(config.environment.allowsNonProductionCloud, isTrue);
      expect(config.isLocal, isFalse);
    });

    test('APP_ENV takes precedence over legacy environment name', () {
      final config = EnvironmentConfig.fromValues(
        appEnvironment: 'staging',
        legacyEnvironment: 'dev',
      );

      expect(config.environment, AppEnvironment.staging);
    });

    test('invalid APP_ENV falls back safely to local', () {
      final config = EnvironmentConfig.fromValues(appEnvironment: 'sandbox');

      expect(config.environment, AppEnvironment.local);
      expect(config.isLocal, isTrue);
    });

    test('does not allow production services without explicit flags', () {
      const config = EnvironmentConfig(environment: AppEnvironment.prod);

      expect(config.allowsProductionServices, isFalse);
      expect(config.allowsCloudServices, isFalse);
    });

    test(
      'prod allows Supabase foundation only when core cloud flags are enabled',
      () {
        const config = EnvironmentConfig(
          environment: AppEnvironment.prod,
          featureFlags: FeatureFlags(
            useCloudAuth: true,
            useCloudPortfolioSync: true,
            useCloudImageStorage: true,
            useAnalytics: true,
            useCrashReporting: true,
            useRealAiProvider: true,
          ),
        );

        expect(config.allowsProductionServices, isTrue);
        expect(config.allowsCloudServices, isTrue);
      },
    );
  });

  group('CloudServiceRegistry', () {
    test('returns no-op services in local mode', () {
      final registry = CloudServiceRegistry.local(
        config: EnvironmentConfig.local(),
      );

      expect(registry.authService, isA<NoOpAuthService>());
      expect(registry.cloudStorageService, isA<NoOpCloudStorageService>());
      expect(registry.analyticsService, isA<NoOpAnalyticsService>());
      expect(registry.crashReportingService, isA<NoOpCrashReportingService>());
      expect(registry.remoteConfigService, isA<NoOpRemoteConfigService>());
      expect(registry.isUsingNoOpServices, isTrue);
    });

    test('app-safe no-op services do not crash without cloud config', () async {
      final registry = CloudServiceRegistry.local(
        config: EnvironmentConfig.local(),
      );

      final user = await registry.authService.currentUser();
      final upload = await registry.cloudStorageService.uploadImage(
        localPath: 'missing-local-file.jpg',
        destinationPath: 'local/missing-local-file.jpg',
      );
      await registry.analyticsService.trackEvent('test_event');
      await registry.crashReportingService.recordNonFatalError(
        StateError('test'),
        reason: 'unit_test',
      );
      await registry.remoteConfigService.refresh();

      expect(user?.id, 'local-user');
      expect(upload, isNull);
      expect(registry.remoteConfigService.getBool('missing'), isFalse);
      expect(registry.remoteConfigService.getString('missing'), isEmpty);
    });

    test(
      'dev uses Supabase data services and no-op telemetry placeholders',
      () {
        const config = EnvironmentConfig(
          environment: AppEnvironment.dev,
          featureFlags: FeatureFlags(
            useCloudAuth: true,
            useCloudPortfolioSync: true,
            useCloudImageStorage: true,
            useAnalytics: true,
            useCrashReporting: true,
          ),
        );

        final registry = CloudServiceRegistry.fromConfig(config);

        expect(registry.authService, isA<SupabaseAuthService>());
        expect(
          registry.cloudStorageService,
          isA<SupabaseCloudStorageService>(),
        );
        expect(
          registry.cloudPortfolioSyncService,
          isA<SupabaseCloudPortfolioSyncService>(),
        );
        expect(registry.analyticsService, isA<NoOpAnalyticsService>());
        expect(
          registry.crashReportingService,
          isA<NoOpCrashReportingService>(),
        );
        expect(registry.remoteConfigService, isA<NoOpRemoteConfigService>());
      },
    );

    test('SIT uses non-production services when matching flags are true', () {
      const config = EnvironmentConfig(
        environment: AppEnvironment.sit,
        featureFlags: FeatureFlags(
          useCloudAuth: true,
          useCloudPortfolioSync: true,
          useCloudImageStorage: true,
        ),
      );

      final registry = CloudServiceRegistry.fromConfig(config);

      expect(registry.authService, isA<SupabaseAuthService>());
      expect(registry.cloudStorageService, isA<SupabaseCloudStorageService>());
      expect(
        registry.cloudPortfolioSyncService,
        isA<SupabaseCloudPortfolioSyncService>(),
      );
      expect(registry.analyticsService, isA<NoOpAnalyticsService>());
      expect(registry.crashReportingService, isA<NoOpCrashReportingService>());
    });

    test(
      'Supabase is the only selected auth storage and portfolio provider',
      () {
        const config = EnvironmentConfig(
          environment: AppEnvironment.dev,
          featureFlags: FeatureFlags(
            useCloudAuth: true,
            useCloudPortfolioSync: true,
            useCloudImageStorage: true,
          ),
        );

        final registry = CloudServiceRegistry.fromConfig(config);

        expect(registry.authService.providerName, contains('Supabase'));
        expect(registry.cloudStorageService.providerName, contains('Supabase'));
        expect(
          registry.cloudPortfolioSyncService.providerName,
          contains('Supabase'),
        );
      },
    );

    test('staging uses no-op services when flags are false', () {
      const config = EnvironmentConfig(environment: AppEnvironment.staging);

      final registry = CloudServiceRegistry.fromConfig(config);

      expect(registry.isUsingNoOpServices, isTrue);
    });

    test('prod uses Supabase foundation when core cloud flags are true', () {
      const config = EnvironmentConfig(
        environment: AppEnvironment.prod,
        featureFlags: FeatureFlags(
          useCloudAuth: true,
          useAnalytics: true,
          useCrashReporting: true,
          useCloudPortfolioSync: true,
          useCloudImageStorage: true,
          useRealAiProvider: true,
        ),
      );

      final registry = CloudServiceRegistry.fromConfig(config);

      expect(registry.authService, isA<SupabaseAuthService>());
      expect(registry.cloudStorageService, isA<SupabaseCloudStorageService>());
      expect(
        registry.cloudPortfolioSyncService,
        isA<SupabaseCloudPortfolioSyncService>(),
      );
    });
  });

  group('SupabaseBootstrap', () {
    test('skips Supabase in local mode', () async {
      final bootstrap = SupabaseBootstrap(config: EnvironmentConfig.local());

      final result = await bootstrap.ensureInitialized();

      expect(result.status, SupabaseBootstrapStatus.skipped);
      expect(result.isInitialized, isFalse);
    });

    test('missing URL or anon key in prod falls back safely', () async {
      final bootstrap = SupabaseBootstrap(
        config: const EnvironmentConfig(
          environment: AppEnvironment.prod,
          featureFlags: FeatureFlags(
            useCloudAuth: true,
            useCloudPortfolioSync: true,
            useCloudImageStorage: true,
          ),
        ),
        url: '',
        anonKey: '',
      );

      final result = await bootstrap.ensureInitialized();

      expect(result.status, SupabaseBootstrapStatus.missingConfig);
      expect(result.isInitialized, isFalse);
    });

    test('missing URL or anon key in dev falls back safely', () async {
      final bootstrap = SupabaseBootstrap(
        config: const EnvironmentConfig(
          environment: AppEnvironment.dev,
          featureFlags: FeatureFlags(useCloudAuth: true),
        ),
        url: '',
        anonKey: '',
      );

      final result = await bootstrap.ensureInitialized();

      expect(result.status, SupabaseBootstrapStatus.missingConfig);
      expect(result.isInitialized, isFalse);
    });

    test('missing URL or anon key in SIT falls back safely', () async {
      final bootstrap = SupabaseBootstrap(
        config: const EnvironmentConfig(
          environment: AppEnvironment.sit,
          featureFlags: FeatureFlags(useCloudAuth: true),
        ),
        url: '',
        anonKey: '',
      );

      final result = await bootstrap.ensureInitialized();

      expect(result.status, SupabaseBootstrapStatus.missingConfig);
      expect(result.isInitialized, isFalse);
    });
  });

  group('network EnvironmentConfig', () {
    test('SIT maps to live SIT backend unless overridden', () {
      const config = network_config.EnvironmentConfig(
        environment: network_config.AppEnvironment.sit,
      );

      expect(config.baseUrl, 'https://api-sit.packlox.com');
    });

    test('backend base URL override is used for phone SIT builds', () {
      const config = network_config.EnvironmentConfig(
        environment: network_config.AppEnvironment.sit,
        baseUrlOverride: 'http://192.168.1.20:8000',
      );

      expect(config.baseUrl, 'http://192.168.1.20:8000');
    });
  });
}
