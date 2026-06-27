import 'package:camera/camera.dart';
import 'package:collectiq_ai/core/errors/scanner_exception.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service responsible for camera lifecycle and capture operations.
class CameraService {
  /// Creates a camera service.
  CameraService();

  /// Currently active camera controller, if initialized.
  CameraController? _controller;

  /// Available device cameras discovered during initialization.
  List<CameraDescription> _availableCameras = const [];

  /// Index of the currently selected camera.
  int _selectedCameraIndex = 0;

  /// Current camera controller, if one has been opened.
  CameraController? get controller => _controller;

  /// Initializes camera metadata needed by the scanner feature.
  Future<void> initializeCamera() async {
    _availableCameras = await availableCameras();
  }

  /// Requests camera permissions from the operating system.
  Future<bool> requestPermissions() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Opens the selected camera and prepares it for capture.
  Future<void> openCamera() async {
    if (_availableCameras.isEmpty) {
      throw const ScannerException(
        message: 'No camera is available.',
        code: 'scanner.camera.unavailable',
      );
    }

    _controller = CameraController(
      _availableCameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller?.initialize();
  }

  /// Captures an image from the active camera.
  Future<XFile> captureImage() async {
    final activeController = _controller;
    if (activeController == null || !activeController.value.isInitialized) {
      throw const ScannerException(
        message: 'Camera is not initialized.',
        code: 'scanner.camera.not_initialized',
      );
    }

    return activeController.takePicture();
  }

  /// Switches between available device cameras.
  Future<void> switchCameras() async {
    if (_availableCameras.length < 2) {
      return;
    }

    _selectedCameraIndex =
        (_selectedCameraIndex + 1) % _availableCameras.length;
    await disposeCamera();
    await openCamera();
  }

  /// Updates the flash mode for the active camera.
  Future<void> setFlashMode(FlashMode mode) async {
    final activeController = _controller;
    if (activeController == null || !activeController.value.isInitialized) {
      throw const ScannerException(
        message: 'Camera is not initialized.',
        code: 'scanner.camera.not_initialized',
      );
    }

    await activeController.setFlashMode(mode);
  }

  /// Disposes the active camera controller.
  Future<void> disposeCamera() async {
    await _controller?.dispose();
    _controller = null;
  }
}
