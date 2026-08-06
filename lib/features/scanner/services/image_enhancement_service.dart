import 'dart:io';

import 'package:collectiq_ai/features/scanner/domain/entities/image_enhancement_preset.dart';
import 'package:image/image.dart' as image_lib;
import 'package:path_provider/path_provider.dart';

class ImageEnhancementResult {
  const ImageEnhancementResult({
    required this.originalPath,
    required this.activePath,
    required this.preset,
    required this.createdEnhancedFile,
  });

  final String originalPath;
  final String activePath;
  final ImageEnhancementPreset preset;
  final bool createdEnhancedFile;

  Map<String, Object?> toMetadataJson() {
    return {
      'originalImagePath': originalPath,
      'activeImagePath': activePath,
      'enhancementPreset': preset.id,
      'enhancementLabel': preset.label,
      'enhanced': preset.isEnhanced,
      'enhancedFileCreated': createdEnhancedFile,
    };
  }
}

class ImageEnhancementService {
  const ImageEnhancementService();

  Future<ImageEnhancementResult> enhance({
    required String originalPath,
    required ImageEnhancementPreset preset,
  }) async {
    final normalizedPath = originalPath.trim();
    if (!preset.isEnhanced || !_canProcessFile(normalizedPath)) {
      return ImageEnhancementResult(
        originalPath: normalizedPath,
        activePath: normalizedPath,
        preset: preset,
        createdEnhancedFile: false,
      );
    }

    final sourceFile = File(normalizedPath);
    if (!await sourceFile.exists()) {
      return ImageEnhancementResult(
        originalPath: normalizedPath,
        activePath: normalizedPath,
        preset: preset,
        createdEnhancedFile: false,
      );
    }

    final bytes = await sourceFile.readAsBytes();
    final decoded = image_lib.decodeImage(bytes);
    if (decoded == null) {
      return ImageEnhancementResult(
        originalPath: normalizedPath,
        activePath: normalizedPath,
        preset: preset,
        createdEnhancedFile: false,
      );
    }

    final enhanced = _applyPreset(decoded, preset);
    final directory = await getTemporaryDirectory();
    final safeName = preset.id;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final output = File(
      '${directory.path}${Platform.pathSeparator}packlox_${safeName}_$timestamp.png',
    );
    await output.writeAsBytes(image_lib.encodePng(enhanced), flush: true);
    return ImageEnhancementResult(
      originalPath: normalizedPath,
      activePath: output.path,
      preset: preset,
      createdEnhancedFile: true,
    );
  }

  bool _canProcessFile(String path) {
    if (path.isEmpty ||
        path.startsWith('sample://') ||
        path.startsWith('assets/') ||
        path.startsWith('http://') ||
        path.startsWith('https://')) {
      return false;
    }
    return true;
  }

  image_lib.Image _applyPreset(
    image_lib.Image source,
    ImageEnhancementPreset preset,
  ) {
    final working = image_lib.copyResize(
      source,
      width: source.width,
      height: source.height,
    );
    return switch (preset) {
      ImageEnhancementPreset.original => working,
      // Two earlier attempts just blended a raw 3x3 high-pass convolution
      // kernel back toward the original pixel at decreasing strength
      // (amount 1 -> 0.4 -> 0.2) and still showed visible noise on
      // glossy/holographic card surfaces (confirmed live both times). That
      // approach can't succeed at any blend strength: a plain convolution
      // kernel amplifies every local pixel difference uniformly, with no
      // way to tell "this is a real edge" from "this is fine holographic
      // texture/sensor noise" — turning the blend down scales both down
      // together, so noise can never be suppressed without also killing
      // the real enhancement. This is a real Unsharp Mask instead (the
      // technique Photoshop/Lightroom/most scanning apps actually use):
      // blur to get a "detail layer" (original minus blurred = edges +
      // noise mixed together), then only amplify differences that exceed
      // a threshold. Real edges (card borders, text) have large luminance
      // jumps and clear the threshold; fine texture/noise has small
      // differences and is left untouched entirely — a lever plain
      // convolution sharpening structurally cannot offer.
      ImageEnhancementPreset.autoEnhance => _thresholdedSharpen(
        image_lib.adjustColor(
          working,
          brightness: 1.08,
          contrast: 1.06,
          saturation: 1.02,
          gamma: 1.04,
        ),
        blurRadius: 2,
        amount: 1.2,
        threshold: 14,
      ),
      ImageEnhancementPreset.brighten => image_lib.adjustColor(
        working,
        brightness: 1.14,
        contrast: 1.02,
      ),
      ImageEnhancementPreset.contrast => image_lib.adjustColor(
        working,
        contrast: 1.18,
        saturation: 1.03,
      ),
      ImageEnhancementPreset.sharpen => image_lib.convolution(
        working,
        filter: _sharpenKernel,
      ),
      ImageEnhancementPreset.textPackageClarity => image_lib.convolution(
        image_lib.adjustColor(working, contrast: 1.22, saturation: 0.96),
        filter: _clarityKernel,
      ),
      // TODO: replace with highlight segmentation once glare detection exists.
      ImageEnhancementPreset.reduceGlare => image_lib.adjustColor(
        working,
        brightness: 0.96,
        contrast: 1.12,
        gamma: 1.08,
      ),
    };
  }

  /// Real unsharp mask: blurs [source] to isolate a "detail layer" (the
  /// difference between the original and the blurred version — a mix of
  /// real edges and fine texture/noise), then only amplifies differences
  /// that exceed [threshold]. Small differences (holographic texture,
  /// sensor noise) are left completely untouched; large ones (text
  /// strokes, card borders) are boosted by [amount]. This is what gives
  /// independent control over sharpening strength vs. noise sensitivity —
  /// a plain high-pass convolution kernel can't offer that; every local
  /// difference gets amplified by the same proportion regardless of
  /// whether it's a real edge or noise.
  image_lib.Image _thresholdedSharpen(
    image_lib.Image source, {
    required int blurRadius,
    required num amount,
    required num threshold,
  }) {
    final blurred = image_lib.gaussianBlur(
      image_lib.Image.from(source),
      radius: blurRadius,
    );
    final result = image_lib.Image.from(source);
    for (final frame in result.frames) {
      final blurredFrame = blurred.frames[frame.frameIndex];
      for (final p in frame) {
        final b = blurredFrame.getPixel(p.x, p.y);
        final dr = p.r - b.r;
        final dg = p.g - b.g;
        final db = p.b - b.b;
        p
          ..r = dr.abs() > threshold
              ? (p.r + dr * amount).clamp(0, p.maxChannelValue)
              : p.r
          ..g = dg.abs() > threshold
              ? (p.g + dg * amount).clamp(0, p.maxChannelValue)
              : p.g
          ..b = db.abs() > threshold
              ? (p.b + db * amount).clamp(0, p.maxChannelValue)
              : p.b;
      }
    }
    return result;
  }
}

const _sharpenKernel = <num>[0, -1, 0, -1, 5, -1, 0, -1, 0];
const _clarityKernel = <num>[-1, -1, -1, -1, 9, -1, -1, -1, -1];
