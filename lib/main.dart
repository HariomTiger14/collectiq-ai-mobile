import 'dart:async';

import 'package:collectiq_ai/core/navigation/app_shell.dart';
import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _disableReleaseDebugLogs();
  _configureAndroidImagePicker();
  final bootstrapTelemetry = createAppTelemetryService(
    TelemetryConfig.fromEnvironment(),
  );
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      bootstrapTelemetry.recordNonFatalError(
        details.exception,
        stackTrace: details.stack,
        reason: 'flutter_error',
      ),
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(
      bootstrapTelemetry.recordNonFatalError(
        error,
        stackTrace: stackTrace,
        reason: 'platform_dispatcher_error',
      ),
    );
    return false;
  };
  runZonedGuarded(
    () => runApp(const ProviderScope(child: CollectIqApp())),
    (error, stackTrace) => unawaited(
      bootstrapTelemetry.recordNonFatalError(
        error,
        stackTrace: stackTrace,
        reason: 'uncaught_zone_error',
      ),
    ),
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

class CollectIqApp extends StatelessWidget {
  const CollectIqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CollectIQ AI',
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'collectiq_ai',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}
