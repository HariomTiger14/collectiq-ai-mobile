import 'dart:async';
import 'dart:developer' as developer;

import 'package:collectiq_ai/core/cloud/cloud_app_startup.dart';
import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/core/navigation/app_shell.dart';
import 'package:collectiq_ai/core/network/api_constants.dart' as backend_config;
import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/auth/services/auth_deep_link_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

void main() {
  AppTelemetryService? bootstrapTelemetry;
  CloudServiceRegistry? cloudRegistry;

  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      _disableReleaseDebugLogs();
      _configureAndroidImagePicker();

      bootstrapTelemetry = createAppTelemetryService(
        TelemetryConfig.fromEnvironment(),
      );
      cloudRegistry = CloudServiceRegistry.fromConfig(
        EnvironmentConfig.fromEnvironment(),
      );
      _logSitConfigDiagnostics(cloudRegistry!.config);
      unawaited(CloudAppStartup(registry: cloudRegistry!).run());

      FlutterError.onError = (details) {
        _logStartupError(
          'FlutterError',
          details.exception,
          stackTrace: details.stack,
          context: 'FlutterError.onError',
        );
        FlutterError.presentError(details);
        unawaited(
          bootstrapTelemetry!.recordNonFatalError(
            details.exception,
            stackTrace: details.stack,
            reason: 'flutter_error',
          ),
        );
        unawaited(
          cloudRegistry!.crashReportingService.recordNonFatalError(
            details.exception,
            stackTrace: details.stack,
            reason: 'flutter_error',
          ),
        );
      };

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        _logStartupError(
          'PlatformDispatcher',
          error,
          stackTrace: stackTrace,
          context: 'PlatformDispatcher.onError',
        );
        unawaited(
          bootstrapTelemetry!.recordNonFatalError(
            error,
            stackTrace: stackTrace,
            reason: 'platform_dispatcher_error',
          ),
        );
        unawaited(
          cloudRegistry!.crashReportingService.recordNonFatalError(
            error,
            stackTrace: stackTrace,
            reason: 'platform_dispatcher_error',
          ),
        );
        return false;
      };

      runApp(const ProviderScope(child: CollectIqApp()));
    },
    (error, stackTrace) {
      _logStartupError(
        'Zone',
        error,
        stackTrace: stackTrace,
        context: 'runZonedGuarded',
      );
      final telemetry = bootstrapTelemetry;
      final registry = cloudRegistry;
      if (telemetry != null) {
        unawaited(
          telemetry.recordNonFatalError(
            error,
            stackTrace: stackTrace,
            reason: 'uncaught_zone_error',
          ),
        );
      }
      if (registry != null) {
        unawaited(
          registry.crashReportingService.recordNonFatalError(
            error,
            stackTrace: stackTrace,
            reason: 'uncaught_zone_error',
          ),
        );
      }
    },
  );
}

void _logStartupError(
  String scope,
  Object error, {
  StackTrace? stackTrace,
  String? context,
}) {
  final timestamp = DateTime.now().toIso8601String();
  developer.log(
    '[PackLox][$scope][$timestamp] ${context ?? 'error'}: $error',
    name: 'PackLox.$scope',
    error: error,
    stackTrace: stackTrace,
  );
}

void _logSitConfigDiagnostics(EnvironmentConfig config) {
  if (!kDebugMode || config.environment.name != 'sit') {
    return;
  }

  final supabaseConfig = SupabaseConfig.fromEnvironment();
  final apiConfig = backend_config.EnvironmentConfig.fromEnvironment();
  debugPrint('[CollectIQ SIT] app env: ${config.environment.name}');
  debugPrint(
    '[CollectIQ SIT] Supabase URL configured: ${supabaseConfig.hasUrl}',
  );
  debugPrint(
    '[CollectIQ SIT] Supabase anon key configured: '
    '${supabaseConfig.hasAnonKey}',
  );
  debugPrint(
    '[CollectIQ SIT] Supabase anon key length: '
    '${supabaseConfig.anonKeyLength}',
  );
  debugPrint(
    '[CollectIQ SIT] API base URL configured: '
    '${apiConfig.baseUrlOverride.trim().isNotEmpty}',
  );
}

void _disableReleaseDebugLogs() {
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
}

void _configureAndroidImagePicker() {
  final imagePickerImplementation = ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }
}

class CollectIqApp extends ConsumerStatefulWidget {
  const CollectIqApp({super.key});

  @override
  ConsumerState<CollectIqApp> createState() => _CollectIqAppState();
}

class _CollectIqAppState extends ConsumerState<CollectIqApp> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(authDeepLinkCoordinatorProvider).start());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PackLox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}
