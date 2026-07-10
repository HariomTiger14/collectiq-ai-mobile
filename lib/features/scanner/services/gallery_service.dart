import 'dart:io';

import 'package:collectiq_ai/core/errors/scanner_exception.dart';
import 'package:collectiq_ai/features/scanner/services/scan_image_processing_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Service responsible for selecting and validating gallery images.
class GalleryService {
  /// Creates a gallery service with an optional [imagePicker].
  GalleryService({ImagePicker? imagePicker, ScanImageProcessor? imageProcessor})
    : _imagePicker = imagePicker ?? ImagePicker(),
      _imageProcessor = imageProcessor ?? const ScanImageProcessor();

  static const _allowedExtensions = {'jpg', 'jpeg', 'png'};
  static const _maxImageBytes = 10 * 1024 * 1024;
  static const _maxPickerDimension = 1280.0;
  static const _pickerImageQuality = 82;

  final ImagePicker _imagePicker;
  final ScanImageProcessor _imageProcessor;

  /// Opens the gallery and returns the selected image file.
  Future<XFile?> pickImage() async {
    debugPrint('[GalleryService] gallery picker launch requested');
    _releaseImageCacheBeforeExternalPicker();
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxPickerDimension,
      maxHeight: _maxPickerDimension,
      imageQuality: _pickerImageQuality,
      requestFullMetadata: false,
    );
    debugPrint('[GalleryService] picker returned: ${image?.path ?? 'null'}');
    return image;
  }

  void _releaseImageCacheBeforeExternalPicker() {
    final cache = PaintingBinding.instance.imageCache;
    debugPrint(
      '[GalleryService] clearing image cache before gallery picker: '
      'current=${cache.currentSize} live=${cache.liveImageCount}',
    );
    cache.clear();
    cache.clearLiveImages();
  }

  /// Validates whether [image] can be used for scanner upload.
  Future<bool> validateImage(XFile image) async {
    final originalPath = image.path.trim();
    if (originalPath.isEmpty) {
      throw const ScannerException(
        message: 'Gallery image path is missing.',
        code: 'scanner.gallery.empty_path',
      );
    }

    final sourceFile = File(originalPath);
    if (!sourceFile.existsSync()) {
      throw const ScannerException(
        message: 'Selected image could not be found.',
        code: 'scanner.gallery.missing_file',
      );
    }

    final extension = _extensionFor(image);
    if (!_allowedExtensions.contains(extension)) {
      throw const ScannerException(
        message: 'Please select a PNG, JPG, or JPEG image.',
        code: 'scanner.gallery.unsupported_type',
      );
    }

    final length = sourceFile.lengthSync();
    if (length > _maxImageBytes) {
      throw const ScannerException(
        message: 'Image is too large. Please choose an image under 10MB.',
        code: 'scanner.gallery.file_too_large',
      );
    }

    return true;
  }

  /// Copies and optimizes a selected gallery image into app-owned storage.
  Future<XFile> persistSelectedImage(XFile image) async {
    final originalPath = image.path;
    debugPrint('[GalleryService] original gallery path: $originalPath');

    if (originalPath.isEmpty) {
      throw const ScannerException(
        message: 'Gallery image path is missing.',
        code: 'scanner.gallery.empty_path',
      );
    }

    final sourceFile = File(originalPath);
    final sourceExists = await sourceFile.exists();
    debugPrint('[GalleryService] original gallery file exists: $sourceExists');
    if (!sourceExists) {
      throw const ScannerException(
        message: 'Selected image could not be found.',
        code: 'scanner.gallery.missing_file',
      );
    }

    final sourceSize = await sourceFile.length();
    debugPrint('[GalleryService] original gallery file size: $sourceSize');

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final galleryDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}collectiq_gallery',
    );
    await galleryDirectory.create(recursive: true);

    final fileName = 'gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outputPath =
        '${galleryDirectory.path}${Platform.pathSeparator}$fileName';
    final optimized = await _imageProcessor.optimize(
      inputPath: sourceFile.path,
      outputPath: outputPath,
    );
    final copiedFile = File(optimized.outputPath);
    final copiedExists = await copiedFile.exists();
    final copiedSize = copiedExists ? await copiedFile.length() : 0;
    debugPrint('[GalleryService] copied persistent path: ${copiedFile.path}');
    debugPrint('[GalleryService] copied gallery file exists: $copiedExists');
    debugPrint('[GalleryService] copied gallery file size: $copiedSize');
    debugPrint(
      '[GalleryService] optimized gallery dimensions='
      '${optimized.width}x${optimized.height}',
    );

    return XFile(copiedFile.path, name: fileName);
  }

  String _extensionFor(XFile image) {
    final candidate = image.name.isNotEmpty
        ? image.name
        : image.path.split(RegExp(r'[\\/]')).last;
    final fileName = candidate.toLowerCase();
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1) {
      return '';
    }
    return fileName.substring(dotIndex + 1);
  }
}
