import 'dart:io';

import 'package:camera/camera.dart';
import 'package:collectiq_ai/core/errors/scanner_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service responsible for camera lifecycle and capture operations.
class CameraService {
  /// Creates a camera service.
  CameraService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;
  static const _maxPickerDimension = 1280.0;
  static const _pickerImageQuality = 82;

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
    debugPrint('[CameraService] camera permission request start');
    final status = await Permission.camera.request();
    debugPrint('[CameraService] camera permission status: $status');
    return status.isGranted;
  }

  /// Opens the native camera capture flow and returns the captured image.
  Future<XFile?> pickImageFromCamera() async {
    debugPrint('[CameraService] camera picker launch requested');
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      throw const ScannerException(
        message: 'Camera permission is required to scan collectibles.',
        code: 'scanner.camera.permission_denied',
      );
    }

    _releaseImageCacheBeforeExternalPicker();
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: _maxPickerDimension,
      maxHeight: _maxPickerDimension,
      imageQuality: _pickerImageQuality,
      requestFullMetadata: false,
    );
    debugPrint('[CameraService] camera picker completed: ${image?.path}');
    return image;
  }

  void _releaseImageCacheBeforeExternalPicker() {
    final cache = PaintingBinding.instance.imageCache;
    debugPrint(
      '[CameraService] clearing image cache before camera picker: '
      'current=${cache.currentSize} live=${cache.liveImageCount}',
    );
    cache.clear();
    cache.clearLiveImages();
  }

  /// Recovers a picker image after Android destroys and recreates MainActivity.
  Future<XFile?> retrieveLostImage() async {
    debugPrint('[CameraService] checking image_picker lost data');
    final LostDataResponse response;
    try {
      response = await _imagePicker.retrieveLostData();
    } on MissingPluginException {
      debugPrint('[CameraService] lost data unsupported: missing plugin');
      return null;
    } on UnimplementedError {
      debugPrint('[CameraService] lost data unsupported on this platform');
      return null;
    }
    if (response.isEmpty) {
      debugPrint('[CameraService] no lost picker data');
      return null;
    }

    final exception = response.exception;
    if (exception != null) {
      debugPrint(
        '[CameraService] lost picker data exception: '
        '${exception.code} ${exception.message}',
      );
      throw ScannerException(
        message: exception.message ?? 'Unable to recover camera image.',
        code: 'scanner.picker.lost_data_error',
      );
    }

    final files = response.files;
    final image = files != null && files.isNotEmpty
        ? files.last
        : response.file;
    debugPrint('[CameraService] recovered lost picker image: ${image?.path}');
    return image;
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
