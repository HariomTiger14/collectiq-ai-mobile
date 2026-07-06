import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:collectiq_ai/core/errors/scanner_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ScanImageQualityWarning {
  const ScanImageQualityWarning({required this.code, required this.message});

  final String code;
  final String message;
}

class ScanImageQualityReport {
  const ScanImageQualityReport({
    required this.width,
    required this.height,
    required this.fileSizeBytes,
    required this.warnings,
  });

  final int width;
  final int height;
  final int fileSizeBytes;
  final List<ScanImageQualityWarning> warnings;

  bool get hasWarnings => warnings.isNotEmpty;
}

class ScanImageProcessingResult {
  const ScanImageProcessingResult({
    required this.outputPath,
    required this.width,
    required this.height,
    required this.fileSizeBytes,
  });

  final String outputPath;
  final int width;
  final int height;
  final int fileSizeBytes;
}

class ScanImageProcessor {
  const ScanImageProcessor({this.maxDimension = 1600, this.jpegQuality = 84});

  final int maxDimension;
  final int jpegQuality;

  Future<ScanImageQualityReport> inspect(String path) async {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) {
      throw const ScannerException(
        message: 'Captured image path is missing.',
        code: 'scanner.image.empty_path',
      );
    }

    final file = File(normalizedPath);
    if (!await file.exists()) {
      throw const ScannerException(
        message: 'Captured image could not be found.',
        code: 'scanner.image.missing_file',
      );
    }

    final fileSizeBytes = await file.length();
    if (fileSizeBytes <= 0) {
      throw const ScannerException(
        message: 'Captured image is empty. Please retake the photo.',
        code: 'scanner.image.empty_file',
      );
    }

    try {
      return Isolate.run(
        () => inspectScanImageBytes(file.readAsBytesSync(), fileSizeBytes),
      );
    } on ScannerException {
      rethrow;
    } on Object catch (error) {
      debugPrint('[ScanImageProcessor] decode failed: $error');
      throw const ScannerException(
        message: 'Captured image could not be read. Please retake the photo.',
        code: 'scanner.image.decode_failed',
      );
    }
  }

  Future<ScanImageProcessingResult> optimize({
    required String inputPath,
    required String outputPath,
  }) async {
    final normalizedInputPath = inputPath.trim();
    if (normalizedInputPath.isEmpty) {
      throw const ScannerException(
        message: 'Image path is missing.',
        code: 'scanner.image.empty_path',
      );
    }

    final inputFile = File(normalizedInputPath);
    if (!await inputFile.exists()) {
      throw const ScannerException(
        message: 'Selected image could not be found.',
        code: 'scanner.image.missing_file',
      );
    }

    final outputFile = File(outputPath);
    await outputFile.parent.create(recursive: true);

    try {
      final result = await Isolate.run(
        () => optimizeScanImageFile(
          inputPath: normalizedInputPath,
          outputPath: outputPath,
          maxDimension: maxDimension,
          jpegQuality: jpegQuality,
        ),
      );
      if (result.fileSizeBytes <= 0) {
        throw const ScannerException(
          message: 'Optimized image is empty. Please retake the photo.',
          code: 'scanner.image.optimized_empty',
        );
      }
      return result;
    } on ScannerException {
      rethrow;
    } on Object catch (error) {
      debugPrint('[ScanImageProcessor] optimize failed: $error');
      throw const ScannerException(
        message: 'Unable to prepare image. Please try another photo.',
        code: 'scanner.image.optimize_failed',
      );
    }
  }
}

@visibleForTesting
ScanImageQualityReport inspectScanImageBytes(
  Uint8List bytes,
  int fileSizeBytes,
) {
  final image = img.decodeImage(bytes);
  if (image == null) {
    throw const ScannerException(
      message: 'Captured image could not be read. Please retake the photo.',
      code: 'scanner.image.decode_failed',
    );
  }

  final warnings = <ScanImageQualityWarning>[];
  if (image.width < 640 || image.height < 640) {
    warnings.add(
      const ScanImageQualityWarning(
        code: 'low_resolution',
        message:
            'This photo is low resolution. Fine text, dates, or serials may be hard to read.',
      ),
    );
  }

  final metrics = _sampleImageMetrics(image);
  if (metrics.averageLuminance < 42) {
    warnings.add(
      const ScanImageQualityWarning(
        code: 'too_dark',
        message: 'This photo looks dark. Better light may improve analysis.',
      ),
    );
  }
  if (metrics.edgeScore < 7 && image.width >= 640 && image.height >= 640) {
    warnings.add(
      const ScanImageQualityWarning(
        code: 'likely_blurry',
        message:
            'This photo may be blurry. Retake if the year, mark, label, or serial is not sharp.',
      ),
    );
  }

  return ScanImageQualityReport(
    width: image.width,
    height: image.height,
    fileSizeBytes: fileSizeBytes,
    warnings: warnings,
  );
}

@visibleForTesting
ScanImageProcessingResult optimizeScanImageFile({
  required String inputPath,
  required String outputPath,
  required int maxDimension,
  required int jpegQuality,
}) {
  final source = File(inputPath);
  final image = img.decodeImage(source.readAsBytesSync());
  if (image == null) {
    throw const ScannerException(
      message: 'Selected image could not be read. Please choose another image.',
      code: 'scanner.image.decode_failed',
    );
  }

  final largestSide = math.max(image.width, image.height);
  final prepared = largestSide > maxDimension
      ? img.copyResize(
          image,
          width: image.width >= image.height ? maxDimension : null,
          height: image.height > image.width ? maxDimension : null,
          interpolation: img.Interpolation.average,
        )
      : image;
  final bytes = img.encodeJpg(prepared, quality: jpegQuality.clamp(1, 100));
  final output = File(outputPath)..writeAsBytesSync(bytes, flush: true);

  return ScanImageProcessingResult(
    outputPath: outputPath,
    width: prepared.width,
    height: prepared.height,
    fileSizeBytes: output.lengthSync(),
  );
}

_ScanImageMetrics _sampleImageMetrics(img.Image image) {
  final stepX = math.max(1, image.width ~/ 80);
  final stepY = math.max(1, image.height ~/ 80);
  var luminanceTotal = 0.0;
  var luminanceCount = 0;
  var edgeTotal = 0.0;
  var edgeCount = 0;

  for (var y = stepY; y < image.height; y += stepY) {
    for (var x = stepX; x < image.width; x += stepX) {
      final current = _luminance(image.getPixel(x, y));
      luminanceTotal += current;
      luminanceCount += 1;

      final left = _luminance(image.getPixel(x - stepX, y));
      final top = _luminance(image.getPixel(x, y - stepY));
      edgeTotal += (current - left).abs() + (current - top).abs();
      edgeCount += 2;
    }
  }

  return _ScanImageMetrics(
    averageLuminance: luminanceCount == 0 ? 0 : luminanceTotal / luminanceCount,
    edgeScore: edgeCount == 0 ? 0 : edgeTotal / edgeCount,
  );
}

double _luminance(img.Pixel pixel) {
  return 0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b;
}

class _ScanImageMetrics {
  const _ScanImageMetrics({
    required this.averageLuminance,
    required this.edgeScore,
  });

  final double averageLuminance;
  final double edgeScore;
}
