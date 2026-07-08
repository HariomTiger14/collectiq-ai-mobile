import 'dart:io';
import 'dart:math' as math;

import 'package:collectiq_ai/features/scanner/domain/entities/image_enhancement_preset.dart';
import 'package:image/image.dart' as image_lib;

class ImageQualityAssessment {
  const ImageQualityAssessment({
    required this.recommendedPreset,
    required this.readinessScore,
    required this.lighting,
    required this.sharpness,
    required this.glareRisk,
    required this.textClarity,
    required this.framingConfidence,
    required this.reason,
    this.recommendationConfidence = 0,
    this.warnings = const [],
  });

  final ImageEnhancementPreset recommendedPreset;
  final int readinessScore;
  final double lighting;
  final double sharpness;
  final double glareRisk;
  final double textClarity;
  final double framingConfidence;
  final double recommendationConfidence;
  final String reason;
  final List<String> warnings;

  String get stateLabel {
    if (readinessScore >= 84) {
      return 'Excellent';
    }
    if (readinessScore >= 68) {
      return 'Good';
    }
    return 'Needs improvement';
  }

  Map<String, Object?> toMetadataJson() {
    return {
      'readinessScore': readinessScore,
      'readinessState': stateLabel,
      'recommendedEnhancementPreset': recommendedPreset.id,
      'recommendedEnhancementLabel': recommendedPreset.label,
      'recommendationConfidence': recommendationConfidence,
      'qualityReason': reason,
      'qualityWarnings': warnings,
      'qualityMetrics': {
        'lighting': lighting,
        'sharpness': sharpness,
        'glareRisk': glareRisk,
        'textClarity': textClarity,
        'framingConfidence': framingConfidence,
      },
    };
  }
}

class ImageQualityAssessmentService {
  const ImageQualityAssessmentService();

  Future<ImageQualityAssessment> assess(String imagePath) async {
    final normalized = imagePath.trim();
    if (!_canRead(normalized)) {
      return _fallback();
    }
    final file = File(normalized);
    if (!await file.exists()) {
      return _fallback();
    }
    final decoded = image_lib.decodeImage(await file.readAsBytes());
    if (decoded == null || decoded.width <= 1 || decoded.height <= 1) {
      return _fallback();
    }

    final sampleStep = math.max(
      1,
      math.sqrt(decoded.width * decoded.height / 900).round(),
    );
    var count = 0;
    var luminanceTotal = 0.0;
    var saturationTotal = 0.0;
    var brightPixels = 0;
    var darkPixels = 0;
    var edgeTotal = 0.0;
    var previousLuma = 0.0;
    var first = true;

    for (var y = 0; y < decoded.height; y += sampleStep) {
      for (var x = 0; x < decoded.width; x += sampleStep) {
        final pixel = decoded.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        final luma = ((0.299 * r) + (0.587 * g) + (0.114 * b)) / 255.0;
        final maxChannel = math.max(r, math.max(g, b));
        final minChannel = math.min(r, math.min(g, b));
        luminanceTotal += luma;
        saturationTotal += maxChannel == 0
            ? 0
            : (maxChannel - minChannel) / maxChannel;
        if (luma > 0.9) {
          brightPixels += 1;
        }
        if (luma < 0.18) {
          darkPixels += 1;
        }
        if (!first) {
          edgeTotal += (luma - previousLuma).abs();
        }
        previousLuma = luma;
        first = false;
        count += 1;
      }
    }

    if (count == 0) {
      return _fallback();
    }

    final averageLuma = luminanceTotal / count;
    final averageSaturation = saturationTotal / count;
    final glareRatio = brightPixels / count;
    final darkRatio = darkPixels / count;
    final edgeEnergy = (edgeTotal / math.max(1, count - 1)).clamp(0.0, 1.0);
    final lighting =
        (1.0 - ((averageLuma - 0.52).abs() * 1.9) - (darkRatio * 0.35)).clamp(
          0.0,
          1.0,
        );
    final sharpness = (edgeEnergy * 7.5).clamp(0.0, 1.0);
    final glareRisk = (glareRatio * 8.0).clamp(0.0, 1.0);
    final contrastProxy = (edgeEnergy * 4.5 + averageSaturation * 0.3).clamp(
      0.0,
      1.0,
    );
    final textClarity =
        ((sharpness * 0.7) + (contrastProxy * 0.3) - (glareRisk * 0.2)).clamp(
          0.0,
          1.0,
        );
    final framing = 0.82;

    final warnings = <String>[
      if (lighting < 0.55) 'Too dark for best analysis',
      if (sharpness < 0.42) 'Slight blur detected',
      if (glareRisk > 0.38) 'Glare may affect packaging text',
      if (textClarity < 0.48) 'Package text may be hard to read',
    ];

    var recommended = ImageEnhancementPreset.autoEnhance;
    var reason = 'Balances light and detail for AI analysis.';
    var confidence = 0.62;
    if (glareRisk > 0.42) {
      recommended = ImageEnhancementPreset.reduceGlare;
      reason = 'Reduces bright reflections that can hide package text.';
      confidence = 0.82;
    } else if (averageLuma < 0.38 || darkRatio > 0.24) {
      recommended = ImageEnhancementPreset.brighten;
      reason = 'Adds light so item details are easier to read.';
      confidence = 0.78;
    } else if (sharpness < 0.4) {
      recommended = ImageEnhancementPreset.sharpen;
      reason = 'Improves edges for logos, corners, and small markings.';
      confidence = 0.76;
    } else if (textClarity < 0.58 || contrastProxy < 0.44) {
      recommended = ImageEnhancementPreset.textPackageClarity;
      reason = 'Best for barcode, package text, and small labels.';
      confidence = 0.74;
    } else if (lighting > 0.78 && sharpness > 0.62 && glareRisk < 0.24) {
      recommended = ImageEnhancementPreset.original;
      reason = 'No major correction needed.';
      confidence = 0.7;
    }

    final readiness =
        ((lighting * 31) +
                (sharpness * 25) +
                ((1 - glareRisk) * 18) +
                (textClarity * 18) +
                (framing * 8))
            .round()
            .clamp(0, 100);

    return ImageQualityAssessment(
      recommendedPreset: recommended,
      readinessScore: readiness,
      lighting: lighting,
      sharpness: sharpness,
      glareRisk: glareRisk,
      textClarity: textClarity,
      framingConfidence: framing,
      recommendationConfidence: confidence,
      reason: reason,
      warnings: warnings,
    );
  }

  bool _canRead(String path) {
    return path.isNotEmpty &&
        !path.startsWith('sample://') &&
        !path.startsWith('assets/') &&
        !path.startsWith('http://') &&
        !path.startsWith('https://');
  }

  ImageQualityAssessment _fallback() {
    return const ImageQualityAssessment(
      recommendedPreset: ImageEnhancementPreset.autoEnhance,
      readinessScore: 78,
      lighting: 0.72,
      sharpness: 0.68,
      glareRisk: 0.18,
      textClarity: 0.66,
      framingConfidence: 0.8,
      recommendationConfidence: 0.55,
      reason: 'Auto enhancement is a safe starting point for analysis.',
    );
  }
}
