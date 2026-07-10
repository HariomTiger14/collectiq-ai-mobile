import 'package:collectiq_ai/features/scanner/presentation/pages/camera_capture_page.dart';
import 'package:collectiq_ai/features/scanner/services/camera_service.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  testWidgets('camera denied UI shows friendly message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cameraServiceProvider.overrideWithValue(_DeniedCameraService()),
        ],
        child: const MaterialApp(home: CameraCapturePage(imageRole: 'front')),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(
      find.text('Camera permission is required to capture scans.'),
      findsOneWidget,
    );
    expect(find.text('Try Again'), findsOneWidget);
  });
}

class _DeniedCameraService extends CameraService {
  @override
  Future<PermissionStatus> requestPermissionStatus() async {
    return PermissionStatus.denied;
  }
}
