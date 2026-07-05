import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';

import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/cloud_portfolio_sync_service.dart';
import 'services/cloud_storage_service.dart';
import 'services/crash_reporting_service.dart';
import 'services/noop_cloud_services.dart';
import 'services/remote_config_service.dart';
import 'supabase/supabase_auth_service.dart';
import 'supabase/supabase_bootstrap.dart';
import 'supabase/supabase_cloud_portfolio_sync_service.dart';
import 'supabase/supabase_cloud_storage_service.dart';

final cloudServiceRegistryProvider = Provider<CloudServiceRegistry>((ref) {
  return CloudServiceRegistry.fromConfig(
    ref.watch(environmentConfigProvider),
    supabaseDataGateway: ref.watch(supabaseServiceProvider),
  );
});

/// Registry for cloud-capable services.
///
/// The registry gives controllers and future adapters a single place to resolve
/// service implementations without binding UI code to Supabase directly.
class CloudServiceRegistry {
  const CloudServiceRegistry({
    required this.config,
    required this.authService,
    required this.cloudStorageService,
    required this.cloudPortfolioSyncService,
    required this.analyticsService,
    required this.crashReportingService,
    required this.remoteConfigService,
  });

  factory CloudServiceRegistry.local({required EnvironmentConfig config}) {
    return CloudServiceRegistry(
      config: config,
      authService: const NoOpAuthService(),
      cloudStorageService: const NoOpCloudStorageService(),
      cloudPortfolioSyncService: const NoOpCloudPortfolioSyncService(),
      analyticsService: const NoOpAnalyticsService(),
      crashReportingService: const NoOpCrashReportingService(),
      remoteConfigService: const NoOpRemoteConfigService(),
    );
  }

  factory CloudServiceRegistry.fromConfig(
    EnvironmentConfig config, {
    SupabaseDataGateway? supabaseDataGateway,
  }) {
    if (!SupabaseBootstrap.canUseSupabase(config)) {
      return CloudServiceRegistry.local(config: config);
    }

    final supabaseBootstrap = SupabaseBootstrap(config: config);
    final flags = config.featureFlags;
    final authService = flags.useCloudAuth
        ? SupabaseAuthService(
            bootstrap: supabaseBootstrap,
            supabaseAuthGateway: supabaseDataGateway,
          )
        : const NoOpAuthService();

    return CloudServiceRegistry(
      config: config,
      authService: authService,
      cloudStorageService: flags.useCloudImageStorage
          ? SupabaseCloudStorageService(
              bootstrap: supabaseBootstrap,
              authService: authService,
              supabaseDataGateway: supabaseDataGateway,
            )
          : const NoOpCloudStorageService(),
      cloudPortfolioSyncService: flags.useCloudPortfolioSync
          ? SupabaseCloudPortfolioSyncService(
              bootstrap: supabaseBootstrap,
              authService: authService,
              supabaseDataGateway: supabaseDataGateway,
            )
          : const NoOpCloudPortfolioSyncService(),
      analyticsService: const NoOpAnalyticsService(),
      crashReportingService: const NoOpCrashReportingService(),
      remoteConfigService: const NoOpRemoteConfigService(),
    );
  }

  final EnvironmentConfig config;
  final AuthService authService;
  final CloudStorageService cloudStorageService;
  final CloudPortfolioSyncService cloudPortfolioSyncService;
  final AnalyticsService analyticsService;
  final CrashReportingService crashReportingService;
  final RemoteConfigService remoteConfigService;

  bool get isUsingNoOpServices =>
      authService is NoOpAuthService &&
      cloudStorageService is NoOpCloudStorageService &&
      cloudPortfolioSyncService is NoOpCloudPortfolioSyncService &&
      analyticsService is NoOpAnalyticsService &&
      crashReportingService is NoOpCrashReportingService &&
      remoteConfigService is NoOpRemoteConfigService;

  String get modeLabel => config.cloudModeLabel;
}
