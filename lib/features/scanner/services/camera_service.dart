import 'dart:io';

import 'package:camera/camera.dart';
import 'package:collectiq_ai/core/errors/scanner_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service responsible for camera lifecycle and capture operations.
class CameraService {
  /// Creates a camera service.
  CameraService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

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

  /// Opens the native camera capture flow and returns the captured image.
  Future<XFile?> pickImageFromCamera() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      throw const ScannerException(
        message: 'Camera permission is required to scan collectibles.',
        code: 'scanner.camera.permission_denied',
      );
    }

    return _imagePicker.pickImage(source: ImageSource.camera);
  }

  /// Copies a camera capture from temporary storage into app documents storage.
  Future<XFile> persistCapturedImage(XFile image) async {
    final originalPath = image.path;
    debugPrint('[CameraService] original camera path: $originalPath');

    if (originalPath.isEmpty) {
      throw const ScannerException(
        message: 'Camera image path is missing.',
        code: 'scanner.camera.empty_path',
      );
    }

    final sourceFile = File(originalPath);
    final sourceExists = await sourceFile.exists();
    debugPrint('[CameraService] original camera file exists: $sourceExists');
    if (!sourceExists) {
      throw const ScannerException(
        message: 'Captured image could not be found.',
        code: 'scanner.camera.missing_file',
      );
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final capturesDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}collectiq_camera',
    );
    await capturesDirectory.create(recursive: true);

    final extension = _extensionFor(image);
    final fileName =
        'camera_${DateTime.now().millisecondsSinceEpoch}$extension';
    final copiedFile = await sourceFile.copy(
      '${capturesDirectory.path}${Platform.pathSeparator}$fileName',
    );
    final copiedExists = await copiedFile.exists();
    debugPrint('[CameraService] copied persistent path: ${copiedFile.path}');
    debugPrint('[CameraService] copied camera file exists: $copiedExists');

    return XFile(copiedFile.path, name: fileName);
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

  String _extensionFor(XFile image) {
    final candidate = image.name.isNotEmpty
        ? image.name
        : image.path.split(RegExp(r'[\\/]')).last;
    final dotIndex = candidate.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == candidate.length - 1) {
      return '.jpg';
    }

    return candidate.substring(dotIndex);
  }
}
