import 'dart:convert';
import 'dart:io';

/// Safe metadata-only image payload prepared for future backend analysis.
///
/// This does not upload or send bytes by itself. The full image body will be
/// attached later by a real backend API service implementation.
class AiImageUploadPayload {
  /// Creates an immutable image upload payload.
  const AiImageUploadPayload({
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.imageSource,
    required this.localFilePath,
    this.base64Preview,
  });

  /// Original local file name.
  final String fileName;

  /// Safe MIME type inferred from the extension.
  final String mimeType;

  /// Local file size in bytes.
  final int sizeBytes;

  /// Source such as camera, gallery, sample, or unknown.
  final String imageSource;

  /// Local path metadata. This is for future backend upload preparation only.
  final String localFilePath;

  /// Optional tiny preview/test placeholder. Full image bytes are not required.
  final String? base64Preview;

  /// Metadata that can be sent with a future multipart request.
  Map<String, dynamic> toMetadataJson() {
    return {
      'fileName': fileName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'imageSource': imageSource,
      'localFilePath': localFilePath,
      if (base64Preview != null) 'base64Preview': base64Preview,
    };
  }
}

/// Friendly validation error for preparing image upload metadata.
class AiImagePayloadException implements Exception {
  /// Creates an image payload validation exception.
  const AiImagePayloadException(this.message);

  /// User-safe validation message.
  final String message;

  @override
  String toString() => 'AiImagePayloadException: $message';
}

/// Builds and validates image payload metadata for future backend uploads.
class AiImagePayloadPreparer {
  /// Creates an image payload preparer.
  const AiImagePayloadPreparer({
    this.maxFileSizeBytes = 10 * 1024 * 1024,
    this.includeBase64Preview = false,
  });

  /// Maximum allowed local image size.
  final int maxFileSizeBytes;

  /// Whether to include a tiny base64 preview for tests/debugging.
  final bool includeBase64Preview;

  /// Builds a validated payload from a local file path.
  Future<AiImageUploadPayload> fromLocalFile({
    required String localFilePath,
    required String imageSource,
  }) async {
    final normalizedPath = localFilePath.trim();
    if (normalizedPath.isEmpty) {
      throw const AiImagePayloadException(
        'Selected image path is missing. Please choose another image.',
      );
    }

    final file = File(normalizedPath);
    if (!await file.exists()) {
      throw const AiImagePayloadException(
        'Selected image file was not found. Please choose another image.',
      );
    }

    final fileName = _fileNameFor(normalizedPath);
    final mimeType = _mimeTypeFor(fileName);
    if (mimeType == null) {
      throw const AiImagePayloadException(
        'Unsupported image type. Please choose a JPG, PNG, WEBP, HEIC, or HEIF image.',
      );
    }

    final sizeBytes = await file.length();
    if (sizeBytes <= 0) {
      throw const AiImagePayloadException(
        'Selected image file is empty. Please choose another image.',
      );
    }
    if (sizeBytes > maxFileSizeBytes) {
      throw AiImagePayloadException(
        'Selected image is too large. Please choose an image under ${_formatMegabytes(maxFileSizeBytes)} MB.',
      );
    }

    return AiImageUploadPayload(
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      imageSource: imageSource.trim().isEmpty ? 'unknown' : imageSource.trim(),
      localFilePath: normalizedPath,
      base64Preview: includeBase64Preview
          ? base64Encode(await file.openRead(0, sizeBytes.clamp(0, 128)).first)
          : null,
    );
  }

  String _fileNameFor(String path) {
    return path.replaceAll(r'\', '/').split('/').last;
  }

  String? _mimeTypeFor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => null,
    };
  }

  String _formatMegabytes(int bytes) {
    final megabytes = bytes / (1024 * 1024);
    return megabytes.toStringAsFixed(megabytes >= 10 ? 0 : 1);
  }
}
