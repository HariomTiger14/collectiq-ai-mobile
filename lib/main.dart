import 'package:collectiq_ai/core/navigation/app_shell.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

void main() {
  _disableReleaseDebugLogs();
  _configureAndroidImagePicker();
  runApp(const ProviderScope(child: CollectIqApp()));
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
