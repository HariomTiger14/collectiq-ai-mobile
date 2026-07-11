import 'package:camera/camera.dart';
// ignore: depend_on_referenced_packages
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/camera_capture_page.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/scan_hub_page.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/scanner_screen.dart';
import 'package:collectiq_ai/features/scanner/presentation/scanner_visual_theme.dart';
import 'package:collectiq_ai/features/scanner/services/camera_service.dart';
import 'package:collectiq_ai/features/scanner/services/gallery_service.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  testWidgets('S01 renders the approved hub and excludes workspace controls', (
    WidgetTester tester,
  ) async {
    await _pumpHub(tester);

    expect(find.byType(ScanHubPage), findsOneWidget);
    expect(find.text('Good morning.'), findsOneWidget);
    expect(find.text('Harry 👋'), findsOneWidget);
    expect(find.text('Scan a\ncollectible.'), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-hub-hero-card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scan-hub-capture-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('scan-hub-gallery-button')),
      findsOneWidget,
    );
    expect(find.text('Take a Photo'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
    expect(find.text('Try Sample Scan'), findsOneWidget);
    expect(find.textContaining('Auto Detect'), findsNothing);
    expect(find.textContaining('Confidence'), findsNothing);
    expect(find.textContaining('Photo readiness'), findsNothing);
    expect(find.textContaining('Analyze'), findsNothing);
  });

  testWidgets(
    'capture opens full-screen camera and close returns to scan hub',
    (WidgetTester tester) async {
      final cameraService = _ReadyCameraService();
      await _pumpHub(tester, cameraService: cameraService);

      await tester.tap(find.byKey(const ValueKey('scan-hub-capture-button')));
      await tester.pumpAndSettle();

      expect(cameraService.openedCount, 1);
      expect(find.byType(CameraCapturePage), findsOneWidget);
      expect(find.byKey(const ValueKey('camera-close-button')), findsOneWidget);

      await tester.tap(find.byTooltip('Close camera'));
      await tester.pumpAndSettle();

      expect(cameraService.disposeCount, 1);
      expect(cameraService.isAlive, isFalse);
      expect(find.byType(CameraCapturePage), findsNothing);
      expect(find.byType(ScanHubPage), findsOneWidget);
      expect(find.text('Scan a\ncollectible.'), findsOneWidget);
    },
  );

  testWidgets('scan hub fits at compact 360px width without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHub(tester);

    expect(find.byType(ScanHubPage), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-hub-hero-card')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scan hub uses dark scanner visual mode', (
    WidgetTester tester,
  ) async {
    await _pumpHub(tester);

    final scaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey('scan-hub-page')),
    );
    expect(scaffold.backgroundColor, ScannerVisualTheme.background);
    expect(
      find.byKey(const ValueKey('scanner-dark-background')),
      findsOneWidget,
    );
    expect(find.text('Take a Photo'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
    expect(find.text('Try Sample Scan'), findsOneWidget);
  });

  testWidgets('gallery and sample actions remain connected', (
    WidgetTester tester,
  ) async {
    final gallery = _TrackingGalleryService();
    await _pumpHub(tester, galleryService: gallery);

    await tester.tap(find.byKey(const ValueKey('scan-hub-gallery-button')));
    await tester.pump();
    expect(gallery.pickCount, 1);

    await tester.tap(find.byKey(const ValueKey('scan-hub-sample-button')));
    await tester.pump();
    expect(find.byType(ScannerScreen), findsOneWidget);
  });

  testWidgets('S01 exposes meaningful accessibility labels', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpHub(tester);

    expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
    expect(find.bySemanticsLabel('Take a Photo. Use Camera.'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Choose from Gallery. Pick from photos.'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Try Sample Scan. See how it works.'),
      findsOneWidget,
    );
    semantics.dispose();
  });
}

Future<void> _pumpHub(
  WidgetTester tester, {
  CameraService? cameraService,
  GalleryService? galleryService,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cameraServiceProvider.overrideWithValue(
          cameraService ?? _ReadyCameraService(),
        ),
        galleryServiceProvider.overrideWithValue(
          galleryService ?? _TrackingGalleryService(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: const ScanHubPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

class _TrackingGalleryService extends GalleryService {
  int pickCount = 0;

  @override
  Future<XFile?> pickImage() async {
    pickCount += 1;
    return null;
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
  int openedCount = 0;
  int disposeCount = 0;
  bool isAlive = true;

  @override
  CameraController? get controller => _controller;

  @override
  bool get canToggleFlash => false;

  @override
  Future<CameraCaptureFlowResult?> captureWithInAppCamera(
    BuildContext context, {
    String imageRole = 'front',
  }) {
    openedCount += 1;
    return super.captureWithInAppCamera(context, imageRole: imageRole);
  }

  @override
  Future<PermissionStatus> requestPermissionStatus() async {
    isAlive = true;
    return PermissionStatus.granted;
  }

  @override
  Future<void> initializeCamera() async {
    isAlive = true;
  }

  @override
  Future<XFile> captureImage() async {
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
