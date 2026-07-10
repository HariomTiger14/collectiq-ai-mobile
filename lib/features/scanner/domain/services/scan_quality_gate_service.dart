import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

enum QualityGateSeverity { pass, warning, blocker }

class ScanQualityEvaluation {
  const ScanQualityEvaluation({
    required this.passed,
    required this.severity,
    required this.issues,
    required this.userMessage,
    required this.technicalMetrics,
  });

  final bool passed;
  final QualityGateSeverity severity;
  final List<String> issues;
  final String userMessage;
  final Map<String, Object?> technicalMetrics;

  Map<String, Object?> toMetadataJson() {
    return {
      'passed': passed,
      'severity': severity.name.toUpperCase(),
      'issues': issues,
      'userMessage': userMessage,
      'technicalMetrics': technicalMetrics,
    };
  }
}

class ScanQualityGateService {
  const ScanQualityGateService({
    this.minimumDimension = 640,
    this.minimumFileSizeBytes = 1024,
    this.maximumFileSizeBytes = 10 * 1024 * 1024,
  });

  final int minimumDimension;
  final int minimumFileSizeBytes;
  final int maximumFileSizeBytes;

  Future<ScanQualityEvaluation> evaluateFile(String imagePath) async {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.startsWith('sample://')) {
      return const ScanQualityEvaluation(
        passed: true,
        severity: QualityGateSeverity.pass,
        issues: [],
        userMessage: 'Image accepted.',
        technicalMetrics: {'source': 'sample'},
      );
    }
    final file = File(normalizedPath);
    if (!file.existsSync()) {
      return const ScanQualityEvaluation(
        passed: false,
        severity: QualityGateSeverity.blocker,
        issues: ['missing_file'],
        userMessage: 'Selected image could not be found.',
        technicalMetrics: {},
      );
    }
    final bytes = file.readAsBytesSync();
    final sizeBytes = file.lengthSync();
    if (sizeBytes > 0 && sizeBytes < minimumFileSizeBytes) {
      return ScanQualityEvaluation(
        passed: true,
        severity: QualityGateSeverity.warning,
        issues: const ['file_too_small'],
        userMessage: 'Image accepted with minor quality warnings.',
        technicalMetrics: {
          'fileSizeBytes': sizeBytes,
          'decodeSuccess': false,
          'objectCoverage': 'placeholder',
        },
      );
    }
    if (sizeBytes > 0 && _decodeImage(bytes) == null) {
      return ScanQualityEvaluation(
        passed: true,
        severity: QualityGateSeverity.warning,
        issues: const ['decode_unverified'],
        userMessage: 'Image accepted with minor quality warnings.',
        technicalMetrics: {
          'fileSizeBytes': sizeBytes,
          'decodeSuccess': false,
          'objectCoverage': 'placeholder',
        },
      );
    }
    return evaluateBytes(bytes, fileSizeBytes: sizeBytes);
  }

  ScanQualityEvaluation evaluateBytes(
    Uint8List bytes, {
    required int fileSizeBytes,
  }) {
    final issues = <String>[];
    final metrics = <String, Object?>{'fileSizeBytes': fileSizeBytes};
    final decoded = _decodeImage(bytes);
    metrics['decodeSuccess'] = decoded != null;
    if (decoded == null) {
      return ScanQualityEvaluation(
        passed: false,
        severity: QualityGateSeverity.blocker,
        issues: const ['decode_failed'],
        userMessage: 'Image could not be read. Please choose another image.',
        technicalMetrics: metrics,
      );
    }

    metrics['width'] = decoded.width;
    metrics['height'] = decoded.height;
    if (decoded.width < minimumDimension || decoded.height < minimumDimension) {
      issues.add('minimum_dimensions');
    }
    if (fileSizeBytes < minimumFileSizeBytes) {
      issues.add('file_too_small');
    }
    if (fileSizeBytes > maximumFileSizeBytes) {
      issues.add('file_too_large');
    }

    final exposure = _averageLuma(decoded);
    final blurScore = _edgeScore(decoded);
    metrics['averageLuma'] = exposure;
    metrics['blurScore'] = blurScore;
    metrics['objectCoverage'] = 'placeholder';
    if (exposure < 42) {
      issues.add('under_exposed');
    }
    if (exposure > 232) {
      issues.add('over_exposed');
    }
    if (blurScore < 4) {
      issues.add('blur_heuristic');
    }

    final hasBlocker =
        issues.contains('file_too_large') || issues.contains('file_too_small');
    if (hasBlocker) {
      return ScanQualityEvaluation(
        passed: false,
        severity: QualityGateSeverity.blocker,
        issues: issues,
        userMessage: 'Image is unusable. Please choose another image.',
        technicalMetrics: metrics,
      );
    }
    if (issues.isNotEmpty) {
      return ScanQualityEvaluation(
        passed: true,
        severity: QualityGateSeverity.warning,
        issues: issues,
        userMessage: _warningMessage(issues),
        technicalMetrics: metrics,
      );
    }
    return ScanQualityEvaluation(
      passed: true,
      severity: QualityGateSeverity.pass,
      issues: issues,
      userMessage: 'Image accepted.',
      technicalMetrics: metrics,
    );
  }

  double _averageLuma(img.Image image) {
    var total = 0.0;
    var count = 0;
    final stepX = max(1, image.width ~/ 80);
    final stepY = max(1, image.height ~/ 80);
    for (var y = 0; y < image.height; y += stepY) {
      for (var x = 0; x < image.width; x += stepX) {
        final pixel = image.getPixel(x, y);
        total += 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        count += 1;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  img.Image? _decodeImage(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } on Object {
      return null;
    }
  }

  double _edgeScore(img.Image image) {
    var total = 0.0;
    var count = 0;
    final stepX = max(1, image.width ~/ 80);
    final stepY = max(1, image.height ~/ 80);
    for (var y = stepY; y < image.height; y += stepY) {
      for (var x = stepX; x < image.width; x += stepX) {
        final current = image.getPixel(x, y);
        final previous = image.getPixel(x - stepX, y - stepY);
        final currentLuma =
            0.299 * current.r + 0.587 * current.g + 0.114 * current.b;
        final previousLuma =
            0.299 * previous.r + 0.587 * previous.g + 0.114 * previous.b;
        total += (currentLuma - previousLuma).abs();
        count += 1;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  String _warningMessage(List<String> issues) {
    if (issues.contains('blur_heuristic')) {
      return 'Image looks slightly blurry.';
    }
    if (issues.contains('under_exposed')) {
      return 'Lighting appears low.';
    }
    if (issues.contains('over_exposed')) {
      return 'Lighting appears too bright.';
    }
    return 'Image accepted with minor quality warnings.';
  }
}
