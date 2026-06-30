import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

abstract class AnalyticsReporter {
  Future<void> trackEvent(
    String name, {
    Map<String, Object?> properties = const {},
  });
}

abstract class CrashReporter {
  Future<void> recordNonFatalError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, Object?> properties = const {},
  });
}

abstract class AppTelemetryService implements AnalyticsReporter, CrashReporter {
  TelemetryStatus get status;
}

class TelemetryEventNames {
  const TelemetryEventNames._();

  static const appOpen = 'app_open';
  static const scanStarted = 'scan_started';
  static const imageSelected = 'image_selected';
  static const analyzeStarted = 'analyze_started';
  static const analyzeSuccess = 'analyze_success';
  static const analyzeFailed = 'analyze_failed';
  static const saveToPortfolio = 'save_to_portfolio';
  static const priceAlertTriggered = 'price_alert_triggered';
  static const subscriptionPurchaseStarted = 'subscription_purchase_started';
  static const subscriptionPurchaseSuccess = 'subscription_purchase_success';
  static const syncStarted = 'sync_started';
  static const syncFailed = 'sync_failed';
  static const syncSuccess = 'sync_success';
}

enum TelemetryProviderType {
  noop(displayName: 'Noop'),
  firebase(displayName: 'Firebase'),
  sentry(displayName: 'Sentry placeholder');

  const TelemetryProviderType({required this.displayName});

  final String displayName;

  static TelemetryProviderType fromName(String value) {
    final normalized = value.trim().toLowerCase();
    for (final type in TelemetryProviderType.values) {
      if (type.name == normalized) {
        return type;
      }
    }
    return TelemetryProviderType.noop;
  }
}

class TelemetryConfig {
  const TelemetryConfig({
    required this.enabled,
    required this.providerType,
    required this.firebaseConfigured,
    required this.sentryConfigured,
    this.firebaseUseNativeConfig = false,
    this.firebaseApiKey = '',
    this.firebaseAppId = '',
    this.firebaseMessagingSenderId = '',
    this.firebaseProjectId = '',
    this.firebaseStorageBucket = '',
  });

  final bool enabled;
  final TelemetryProviderType providerType;
  final bool firebaseConfigured;
  final bool sentryConfigured;
  final bool firebaseUseNativeConfig;
  final String firebaseApiKey;
  final String firebaseAppId;
  final String firebaseMessagingSenderId;
  final String firebaseProjectId;
  final String firebaseStorageBucket;

  factory TelemetryConfig.fromEnvironment() {
    const firebaseUseNativeConfig = bool.fromEnvironment(
      'COLLECTIQ_FIREBASE_USE_NATIVE_CONFIG',
    );
    const firebaseApiKey = String.fromEnvironment('COLLECTIQ_FIREBASE_API_KEY');
    const firebaseAppId = String.fromEnvironment('COLLECTIQ_FIREBASE_APP_ID');
    const firebaseMessagingSenderId = String.fromEnvironment(
      'COLLECTIQ_FIREBASE_MESSAGING_SENDER_ID',
    );
    const firebaseProjectId = String.fromEnvironment(
      'COLLECTIQ_FIREBASE_PROJECT_ID',
    );
    const firebaseStorageBucket = String.fromEnvironment(
      'COLLECTIQ_FIREBASE_STORAGE_BUCKET',
    );
    final firebaseHasDartOptions =
        firebaseApiKey.trim().isNotEmpty &&
        firebaseAppId.trim().isNotEmpty &&
        firebaseMessagingSenderId.trim().isNotEmpty &&
        firebaseProjectId.trim().isNotEmpty;

    return TelemetryConfig(
      enabled: const bool.fromEnvironment('COLLECTIQ_TELEMETRY_ENABLED'),
      providerType: TelemetryProviderType.fromName(
        const String.fromEnvironment(
          'COLLECTIQ_TELEMETRY_PROVIDER',
          defaultValue: 'noop',
        ),
      ),
      firebaseConfigured: firebaseUseNativeConfig || firebaseHasDartOptions,
      sentryConfigured: const String.fromEnvironment(
        'COLLECTIQ_SENTRY_DSN',
      ).trim().isNotEmpty,
      firebaseUseNativeConfig: firebaseUseNativeConfig,
      firebaseApiKey: firebaseApiKey,
      firebaseAppId: firebaseAppId,
      firebaseMessagingSenderId: firebaseMessagingSenderId,
      firebaseProjectId: firebaseProjectId,
      firebaseStorageBucket: firebaseStorageBucket,
    );
  }

  bool get hasExternalConfiguration {
    return switch (providerType) {
      TelemetryProviderType.noop => false,
      TelemetryProviderType.firebase => firebaseConfigured,
      TelemetryProviderType.sentry => sentryConfigured,
    };
  }

  bool get canUseExternalReporter => enabled && hasExternalConfiguration;
}

class TelemetryStatus {
  const TelemetryStatus({
    required this.provider,
    required this.enabled,
    required this.crashReportingEnabled,
    required this.analyticsEnabled,
    required this.message,
  });

  final String provider;
  final bool enabled;
  final bool crashReportingEnabled;
  final bool analyticsEnabled;
  final String message;

  String get enabledLabel => enabled ? 'Enabled' : 'Disabled';

  String get crashReportingLabel =>
      crashReportingEnabled ? 'Enabled' : 'Disabled';

  String get analyticsLabel => analyticsEnabled ? 'Enabled' : 'Disabled';
}

class NoopTelemetryService implements AppTelemetryService {
  const NoopTelemetryService({TelemetryConfig? config})
    : _config =
          config ??
          const TelemetryConfig(
            enabled: false,
            providerType: TelemetryProviderType.noop,
            firebaseConfigured: false,
            sentryConfigured: false,
          );

  final TelemetryConfig _config;

  @override
  TelemetryStatus get status {
    final message =
        _config.enabled &&
            _config.providerType != TelemetryProviderType.noop &&
            !_config.hasExternalConfiguration
        ? 'Telemetry provider selected but not configured.'
        : 'Telemetry disabled. Local/offline mode is unaffected.';
    return TelemetryStatus(
      provider: _config.providerType.displayName,
      enabled: false,
      crashReportingEnabled: false,
      analyticsEnabled: false,
      message: message,
    );
  }

  @override
  Future<void> recordNonFatalError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, Object?> properties = const {},
  }) async {}

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, Object?> properties = const {},
  }) async {}
}

class FirebaseTelemetryService implements AppTelemetryService {
  FirebaseTelemetryService({required this.config});

  final TelemetryConfig config;
  Future<bool>? _initialization;
  Object? _initializationError;

  @override
  TelemetryStatus get status {
    if (!config.enabled) {
      return TelemetryStatus(
        provider: config.providerType.displayName,
        enabled: false,
        crashReportingEnabled: false,
        analyticsEnabled: false,
        message: 'Firebase telemetry disabled by build configuration.',
      );
    }

    if (!config.firebaseConfigured) {
      return TelemetryStatus(
        provider: config.providerType.displayName,
        enabled: false,
        crashReportingEnabled: false,
        analyticsEnabled: false,
        message: 'Firebase selected but not configured.',
      );
    }

    if (_initializationError != null) {
      return TelemetryStatus(
        provider: config.providerType.displayName,
        enabled: false,
        crashReportingEnabled: false,
        analyticsEnabled: false,
        message: 'Firebase initialization failed. App fallback is active.',
      );
    }

    return TelemetryStatus(
      provider: config.providerType.displayName,
      enabled: true,
      crashReportingEnabled: true,
      analyticsEnabled: true,
      message: 'Firebase telemetry configured. Events are sanitized.',
    );
  }

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, Object?> properties = const {},
  }) async {
    if (!status.analyticsEnabled || !await _ensureInitialized()) {
      return;
    }

    await FirebaseAnalytics.instance.logEvent(
      name: _firebaseSafeName(sanitizeTelemetryName(name)),
      parameters: _firebaseParameters(properties),
    );
  }

  @override
  Future<void> recordNonFatalError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, Object?> properties = const {},
  }) async {
    if (!status.crashReportingEnabled || !await _ensureInitialized()) {
      return;
    }

    final sanitizedProperties = sanitizeTelemetryProperties(properties);
    await FirebaseCrashlytics.instance.recordError(
      sanitizeTelemetryValue(error.toString()) ?? 'non_fatal_error',
      stackTrace,
      reason: sanitizeTelemetryValue(reason ?? 'non_fatal_error'),
      fatal: false,
      information: [
        for (final entry in sanitizedProperties.entries)
          '${entry.key}=${entry.value}',
      ],
    );
  }

  Future<bool> _ensureInitialized() {
    return _initialization ??= _initialize();
  }

  Future<bool> _initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        final options = _firebaseOptions();
        if (options == null) {
          await Firebase.initializeApp();
        } else {
          await Firebase.initializeApp(options: options);
        }
      }

      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      return true;
    } on Object catch (error) {
      _initializationError = error;
      debugPrint('[Telemetry] Firebase initialization failed: $error');
      return false;
    }
  }

  FirebaseOptions? _firebaseOptions() {
    if (config.firebaseUseNativeConfig) {
      return null;
    }

    if (!config.firebaseConfigured) {
      return null;
    }

    return FirebaseOptions(
      apiKey: config.firebaseApiKey,
      appId: config.firebaseAppId,
      messagingSenderId: config.firebaseMessagingSenderId,
      projectId: config.firebaseProjectId,
      storageBucket: config.firebaseStorageBucket.trim().isEmpty
          ? null
          : config.firebaseStorageBucket,
    );
  }
}

class PlaceholderTelemetryService implements AppTelemetryService {
  PlaceholderTelemetryService({required this.config});

  final TelemetryConfig config;
  final List<Map<String, Object?>> debugEvents = [];
  final List<Map<String, Object?>> debugErrors = [];

  @override
  TelemetryStatus get status {
    if (!config.enabled) {
      return TelemetryStatus(
        provider: config.providerType.displayName,
        enabled: false,
        crashReportingEnabled: false,
        analyticsEnabled: false,
        message: 'Telemetry disabled by build configuration.',
      );
    }

    if (!config.hasExternalConfiguration) {
      return TelemetryStatus(
        provider: config.providerType.displayName,
        enabled: false,
        crashReportingEnabled: false,
        analyticsEnabled: false,
        message: 'Telemetry provider selected but not configured.',
      );
    }

    return TelemetryStatus(
      provider: config.providerType.displayName,
      enabled: true,
      crashReportingEnabled: true,
      analyticsEnabled: true,
      message: 'Placeholder telemetry enabled. No SDK credentials are bundled.',
    );
  }

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, Object?> properties = const {},
  }) async {
    if (!status.analyticsEnabled) {
      return;
    }
    final sanitized = sanitizeTelemetryProperties(properties);
    debugEvents.add({'name': sanitizeTelemetryName(name), ...sanitized});
    debugPrint('[Telemetry] event=${sanitizeTelemetryName(name)}');
  }

  @override
  Future<void> recordNonFatalError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, Object?> properties = const {},
  }) async {
    if (!status.crashReportingEnabled) {
      return;
    }
    final sanitized = sanitizeTelemetryProperties(properties);
    debugErrors.add({
      'reason': sanitizeTelemetryValue(reason ?? 'non_fatal_error'),
      'error': sanitizeTelemetryValue(error.toString()),
      ...sanitized,
    });
    debugPrint(
      '[Telemetry] nonFatal=${sanitizeTelemetryValue(reason ?? error)}',
    );
  }
}

final telemetryConfigProvider = Provider<TelemetryConfig>((ref) {
  return TelemetryConfig.fromEnvironment();
});

final appTelemetryServiceProvider = Provider<AppTelemetryService>((ref) {
  return createAppTelemetryService(ref.watch(telemetryConfigProvider));
});

AppTelemetryService createAppTelemetryService(TelemetryConfig config) {
  if (!config.enabled || config.providerType == TelemetryProviderType.noop) {
    return NoopTelemetryService(config: config);
  }
  if (config.providerType == TelemetryProviderType.firebase) {
    if (!config.firebaseConfigured) {
      return NoopTelemetryService(config: config);
    }
    return FirebaseTelemetryService(config: config);
  }
  return PlaceholderTelemetryService(config: config);
}

final telemetryStatusProvider = Provider<TelemetryStatus>((ref) {
  return ref.watch(appTelemetryServiceProvider).status;
});

String sanitizeTelemetryName(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

Map<String, Object> sanitizeTelemetryProperties(
  Map<String, Object?> properties,
) {
  final sanitized = <String, Object>{};
  for (final entry in properties.entries) {
    final key = sanitizeTelemetryName(entry.key);
    if (key.isEmpty || _isSensitiveKey(key)) {
      continue;
    }
    final value = sanitizeTelemetryValue(entry.value);
    if (value != null) {
      sanitized[key] = value;
    }
  }
  return sanitized;
}

Object? sanitizeTelemetryValue(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is bool || value is num) {
    return value;
  }
  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  if (_looksSensitive(text)) {
    return '[redacted]';
  }
  return text.length > 80 ? '${text.substring(0, 80)}...' : text;
}

bool _isSensitiveKey(String key) {
  const sensitiveFragments = [
    'email',
    'password',
    'secret',
    'token',
    'apikey',
    'api_key',
    'key',
    'dsn',
    'path',
    'image',
    'file',
    'url',
    'payload',
    'content',
  ];
  return sensitiveFragments.any(key.contains);
}

bool _looksSensitive(String value) {
  if (RegExp(r'[\w\-.]+@[\w\-.]+\.\w+').hasMatch(value)) {
    return true;
  }
  if (RegExp(r'[A-Za-z]:\\|/data/user/|/storage/|file://').hasMatch(value)) {
    return true;
  }
  if (RegExp(r'https?://').hasMatch(value)) {
    return true;
  }
  if (RegExp(r'[A-Za-z0-9_\-]{32,}').hasMatch(value)) {
    return true;
  }
  return false;
}

String _firebaseSafeName(String value) {
  final normalized = value.isEmpty ? 'event' : value;
  final prefixed = RegExp(r'^[a-zA-Z]').hasMatch(normalized)
      ? normalized
      : 'c_$normalized';
  return prefixed.length > 40 ? prefixed.substring(0, 40) : prefixed;
}

Map<String, Object> _firebaseParameters(Map<String, Object?> properties) {
  final sanitized = sanitizeTelemetryProperties(properties);
  return {
    for (final entry in sanitized.entries)
      _firebaseSafeName(entry.key): switch (entry.value) {
        final bool value => value ? 'true' : 'false',
        final num value => value,
        final Object value => value.toString(),
      },
  };
}
