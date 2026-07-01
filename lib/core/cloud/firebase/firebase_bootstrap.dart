import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/config/environment_config.dart';

enum FirebaseBootstrapStatus { skipped, initialized, disabled, failed }

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({
    required this.status,
    required this.message,
    this.error,
  });

  final FirebaseBootstrapStatus status;
  final String message;
  final Object? error;

  bool get isInitialized => status == FirebaseBootstrapStatus.initialized;
}

typedef FirebaseInitializer = Future<FirebaseApp> Function();

class FirebaseBootstrap {
  FirebaseBootstrap({required this.config, FirebaseInitializer? initializer})
    : _initializer = initializer ?? Firebase.initializeApp;

  final EnvironmentConfig config;
  final FirebaseInitializer _initializer;

  FirebaseBootstrapResult? _result;

  Future<FirebaseBootstrapResult> ensureInitialized() async {
    final existing = _result;
    if (existing != null) {
      return existing;
    }

    if (config.environment == AppEnvironment.local) {
      return _result = const FirebaseBootstrapResult(
        status: FirebaseBootstrapStatus.skipped,
        message: 'Firebase skipped in local environment.',
      );
    }

    if (config.environment == AppEnvironment.prod) {
      return _result = const FirebaseBootstrapResult(
        status: FirebaseBootstrapStatus.disabled,
        message: 'Firebase production wiring is disabled.',
      );
    }

    if (!_requiresFirebase(config)) {
      return _result = const FirebaseBootstrapResult(
        status: FirebaseBootstrapStatus.skipped,
        message: 'No Firebase-backed feature flags are enabled.',
      );
    }

    try {
      await _initializer();
      return _result = const FirebaseBootstrapResult(
        status: FirebaseBootstrapStatus.initialized,
        message: 'Firebase initialized for non-production environment.',
      );
    } catch (error) {
      debugPrint('[FirebaseBootstrap] initialization failed: $error');
      return _result = FirebaseBootstrapResult(
        status: FirebaseBootstrapStatus.failed,
        message: 'Firebase initialization failed; using safe no-op behavior.',
        error: error,
      );
    }
  }

  static bool canUseFirebase(EnvironmentConfig config) {
    return switch (config.environment) {
      AppEnvironment.dev ||
      AppEnvironment.sit ||
      AppEnvironment.staging => _requiresFirebase(config),
      AppEnvironment.local || AppEnvironment.prod => false,
    };
  }

  static bool _requiresFirebase(EnvironmentConfig config) {
    final flags = config.featureFlags;
    return flags.useCrashReporting || flags.useAnalytics;
  }
}
