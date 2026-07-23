import 'package:camera/camera.dart';
// ignore: depend_on_referenced_packages
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/camera_capture_page.dart';
import 'package:collectiq_ai/features/scanner/services/camera_service.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  testWidgets(
    'camera preview is initialized on page load without black screen',
    (WidgetTester tester) async {
      final cameraService = _ReadyCameraService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cameraServiceProvider.overrideWithValue(cameraService)],
          child: const MaterialApp(home: CameraCapturePage(imageRole: 'front')),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(cameraService.initializeCount, 1);
      expect(cameraService.openCount, 0);
      expect(find.byType(CameraPreview), findsOneWidget);
      expect(
        find.byKey(const ValueKey('camera-authority-viewfinder')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('camera-guidance-pill')),
        findsOneWidget,
      );
      final viewfinderRect = tester.getRect(
        find.byKey(const ValueKey('camera-authority-viewfinder')),
      );
      final shutterRect = tester.getRect(
        find.byKey(const ValueKey('camera-capture-button')),
      );
      expect(viewfinderRect.top, greaterThan(0));
      expect(viewfinderRect.bottom, lessThan(shutterRect.top));
      expect(shutterRect.size, const Size(78, 78));
      expect(
        find.byKey(const ValueKey('camera-preview-initializing-black')),
        findsNothing,
      );
    },
  );

  testWidgets('capture button takes picture without reinitializing camera', (
    WidgetTester tester,
  ) async {
    final cameraService = _ReadyCameraService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cameraServiceProvider.overrideWithValue(cameraService)],
        child: const MaterialApp(home: CameraCapturePage(imageRole: 'front')),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('camera-capture-button')));
    await tester.pump();

    expect(cameraService.captureCount, 1);
    expect(cameraService.disposeCount, 1);
    expect(cameraService.isAlive, isFalse);
    expect(cameraService.initializeCount, 1);
    expect(cameraService.openCount, 0);
  });

  testWidgets('camera page shows premium close button', (
    WidgetTester tester,
  ) async {
    final cameraService = _ReadyCameraService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cameraServiceProvider.overrideWithValue(cameraService)],
        child: const MaterialApp(home: CameraCapturePage(imageRole: 'front')),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('camera-close-button')), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byTooltip('Close camera'), findsOneWidget);
    expect(find.byType(MotionReveal), findsWidgets);
    expect(find.byType(MotionTapScale), findsWidgets);
  });

  testWidgets('close button disposes camera and returns to scan hub', (
    WidgetTester tester,
  ) async {
    final cameraService = _ReadyCameraService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cameraServiceProvider.overrideWithValue(cameraService)],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const CameraCapturePage(imageRole: 'front'),
                        ),
                      );
                    },
                    child: const Text('Open camera'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();
    expect(find.byType(CameraCapturePage), findsOneWidget);

    await tester.tap(find.byTooltip('Close camera'));
    await tester.pumpAndSettle();

    expect(cameraService.disposeCount, 1);
    expect(cameraService.isAlive, isFalse);
    expect(find.text('Open camera'), findsOneWidget);
    expect(find.byType(CameraCapturePage), findsNothing);
    expect(
      find.byKey(const ValueKey('camera-preview-initializing-black')),
      findsNothing,
    );
  });

  testWidgets('system back disposes camera and returns to previous screen', (
    WidgetTester tester,
  ) async {
    final cameraService = _ReadyCameraService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cameraServiceProvider.overrideWithValue(cameraService)],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const CameraCapturePage(imageRole: 'front'),
                        ),
                      );
                    },
                    child: const Text('Open camera'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();
    expect(find.byType(CameraCapturePage), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(cameraService.disposeCount, 1);
    expect(cameraService.isAlive, isFalse);
    expect(find.text('Open camera'), findsOneWidget);
    expect(find.byType(CameraCapturePage), findsNothing);
  });

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

    expect(find.byKey(const ValueKey('camera-error-card')), findsOneWidget);
    expect(find.text('Camera access needed'), findsOneWidget);
    expect(
      find.text('PackLox needs camera access to capture a collectible scan.'),
      findsOneWidget,
    );
    expect(find.text('Allow Camera'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
  });

  testWidgets('camera unavailable UI offers retry and gallery fallback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cameraServiceProvider.overrideWithValue(_UnavailableCameraService()),
        ],
        child: const MaterialApp(home: CameraCapturePage(imageRole: 'front')),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('camera-error-card')), findsOneWidget);
    expect(find.text('Camera unavailable'), findsOneWidget);
    expect(
      find.text(
        'The camera could not start on this device. You can try again or choose a photo from your gallery.',
      ),
      findsOneWidget,
    );
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
  });
}

class _DeniedCameraService extends CameraService {
  @override
  Future<PermissionStatus> requestPermissionStatus() async {
    return PermissionStatus.denied;
  }
}

class _UnavailableCameraService extends CameraService {
  @override
  Future<PermissionStatus> requestPermissionStatus() async {
    return PermissionStatus.granted;
  }

  @override
  Future<void> initializeCamera() async {
    throw PlatformException(code: 'camera_unavailable');
  }
}

class _ReadyCameraService extends CameraService {
  _ReadyCameraService() {
    _controller.value = _controller.value.copyWith(
      isInitialized: true,
      previewSize: const Size(480, 640),
    );
  }

  final _FakeCameraController _controller = _FakeCameraController();
  int initializeCount = 0;
  int openCount = 0;
  int captureCount = 0;
  int disposeCount = 0;
  bool isAlive = true;

  @override
  CameraController? get controller => _controller;

  @override
  bool get canToggleFlash => false;

  @override
  Future<PermissionStatus> requestPermissionStatus() async {
    return PermissionStatus.granted;
  }

  @override
  Future<void> initializeCamera() async {
    initializeCount += 1;
  }

  @override
  Future<void> openCamera() async {
    openCount += 1;
  }

  @override
  Future<XFile> captureImage() async {
    captureCount += 1;
    return XFile('test/fixtures/persistent-camera-card.jpg');
  }

  @override
  Future<void> disposeCamera() async {
    disposeCount += 1;
    isAlive = false;
  }
}

class _FakeCameraController extends ValueNotifier<CameraValue>
    implements CameraController {
  _FakeCameraController()
    : super(const CameraValue.uninitialized(_description));

  static const CameraDescription _description = CameraDescription(
    name: 'test-camera',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 0,
    lensType: CameraLensType.wide,
  );

  @override
  Widget buildPreview() => const Texture(textureId: 1);

  @override
  int get cameraId => 1;

  @override
  void debugCheckIsDisposed() {}

  @override
  CameraDescription get description => value.description;

  @override
  bool get enableAudio => false;

  @override
  ImageFormatGroup? get imageFormatGroup => null;

  @override
  MediaSettings get mediaSettings => const MediaSettings(
    resolutionPreset: ResolutionPreset.high,
    fps: 30,
    videoBitrate: 200000,
    audioBitrate: 32000,
    enableAudio: false,
  );

  @override
  ResolutionPreset get resolutionPreset => ResolutionPreset.high;

  @override
  Future<void> dispose() async {
    super.dispose();
  }

  @override
  Future<double> getExposureOffsetStepSize() async => 1;

  @override
  Future<double> getMaxExposureOffset() async => 1;

  @override
  Future<double> getMaxZoomLevel() async => 1;

  @override
  Future<double> getMinExposureOffset() async => 0;

  @override
  Future<double> getMinZoomLevel() async => 1;

  @override
  Future<Iterable<VideoStabilizationMode>>
  getSupportedVideoStabilizationModes() async => const [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> lockCaptureOrientation([DeviceOrientation? orientation]) async {}

  @override
  Future<void> pausePreview() async {}

  @override
  Future<void> pauseVideoRecording() async {}

  @override
  Future<void> prepareForVideoRecording() async {}

  @override
  Future<void> resumePreview() async {}

  @override
  Future<void> resumeVideoRecording() async {}

  @override
  Future<void> setDescription(CameraDescription description) async {}

  @override
  Future<void> setExposureMode(ExposureMode mode) async {}

  @override
  Future<double> setExposureOffset(double offset) async => offset;

  @override
  Future<void> setExposurePoint(Offset? point) async {}

  @override
  Future<void> setFlashMode(FlashMode mode) async {}

  @override
  Future<void> setFocusMode(FocusMode mode) async {}

  @override
  Future<void> setFocusPoint(Offset? point) async {}

  @override
  Future<void> setVideoStabilizationMode(
    VideoStabilizationMode mode, {
    bool allowFallback = true,
  }) async {}

  @override
  Future<void> setZoomLevel(double zoom) async {}

  @override
  Future<void> startImageStream(onLatestImageAvailable onAvailable) async {}

  @override
  Future<void> startVideoRecording({
    onLatestImageAvailable? onAvailable,
    bool enablePersistentRecording = true,
  }) async {}

  @override
  Future<void> stopImageStream() async {}

  @override
  Future<XFile> stopVideoRecording() async => XFile('');

  @override
  bool supportsImageStreaming() => false;

  @override
  Future<XFile> takePicture() async {
    return XFile('test/fixtures/persistent-camera-card.jpg');
  }

  @override
  Future<void> unlockCaptureOrientation() async {}
}
