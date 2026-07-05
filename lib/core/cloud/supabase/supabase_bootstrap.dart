import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SupabaseBootstrapStatus {
  skipped,
  initialized,
  disabled,
  missingConfig,
  failed,
}

class SupabaseBootstrapResult {
  const SupabaseBootstrapResult({
    required this.status,
    required this.message,
    this.error,
  });

  final SupabaseBootstrapStatus status;
  final String message;
  final Object? error;

  bool get isInitialized => status == SupabaseBootstrapStatus.initialized;
}

typedef SupabaseInitializer =
    Future<Supabase> Function({
      required String url,
      required String publishableKey,
    });

class SupabaseBootstrap {
  SupabaseBootstrap({
    required this.config,
    this.url = const String.fromEnvironment('SUPABASE_URL'),
    this.anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY'),
    SupabaseInitializer? initializer,
  }) : _initializer =
           initializer ??
           (({required String url, required String publishableKey}) {
             return Supabase.initialize(
               url: url,
               publishableKey: publishableKey,
             );
           });

  final EnvironmentConfig config;
  final String url;
  final String anonKey;
  final SupabaseInitializer _initializer;

  SupabaseBootstrapResult? _result;

  Future<SupabaseBootstrapResult> ensureInitialized() async {
    final existing = _result;
    if (existing != null) {
      return existing;
    }

    if (config.environment == AppEnvironment.local) {
      return _result = const SupabaseBootstrapResult(
        status: SupabaseBootstrapStatus.skipped,
        message: 'Supabase skipped in local environment.',
      );
    }

    if (!_requiresSupabase(config)) {
      return _result = const SupabaseBootstrapResult(
        status: SupabaseBootstrapStatus.skipped,
        message: 'No Supabase-backed feature flags are enabled.',
      );
    }

    if (url.trim().isEmpty || anonKey.trim().isEmpty) {
      debugPrint(
        '[SupabaseBootstrap] missing SUPABASE_URL or SUPABASE_ANON_KEY; '
        'using safe no-op behavior.',
      );
      return _result = const SupabaseBootstrapResult(
        status: SupabaseBootstrapStatus.missingConfig,
        message: 'Supabase URL or anon key is missing.',
      );
    }

    try {
      await _initializer(url: url, publishableKey: anonKey);
      return _result = const SupabaseBootstrapResult(
        status: SupabaseBootstrapStatus.initialized,
        message: 'Supabase initialized for non-production environment.',
      );
    } on Object catch (error) {
      debugPrint('[SupabaseBootstrap] initialization failed: $error');
      return _result = SupabaseBootstrapResult(
        status: SupabaseBootstrapStatus.failed,
        message: 'Supabase initialization failed; using safe no-op behavior.',
        error: error,
      );
    }
  }

  SupabaseClient? get client {
    final result = _result;
    if (result == null || !result.isInitialized) {
      return null;
    }
    return Supabase.instance.client;
  }

  static bool canUseSupabase(EnvironmentConfig config) {
    return config.allowsCloudServices && _requiresSupabase(config);
  }

  static bool _requiresSupabase(EnvironmentConfig config) {
    final flags = config.featureFlags;
    return flags.useCloudAuth ||
        flags.useCloudPortfolioSync ||
        flags.useCloudImageStorage;
  }
}
