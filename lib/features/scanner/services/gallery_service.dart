import 'package:collectiq_ai/core/errors/scanner_exception.dart';
import 'package:image_picker/image_picker.dart';

/// Service responsible for selecting and validating gallery images.
class GalleryService {
  /// Creates a gallery service with an optional [imagePicker].
  GalleryService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  static const _allowedExtensions = {'jpg', 'jpeg', 'png'};
  static const _maxImageBytes = 10 * 1024 * 1024;

  final ImagePicker _imagePicker;

  /// Opens the gallery and returns the selected image file.
  Future<XFile?> pickImage() {
    return _imagePicker.pickImage(source: ImageSource.gallery);
  }

  /// Validates whether [image] can be used for scanner upload.
  Future<bool> validateImage(XFile image) async {
    final extension = _extensionFor(image);
    if (!_allowedExtensions.contains(extension)) {
      throw const ScannerException(
        message: 'Please select a PNG, JPG, or JPEG image.',
        code: 'scanner.gallery.unsupported_type',
      );
    }

    final length = await image.length();
    if (length > _maxImageBytes) {
      throw const ScannerException(
        message: 'Image is too large. Please choose an image under 10MB.',
        code: 'scanner.gallery.file_too_large',
      );
    }

    return true;
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
