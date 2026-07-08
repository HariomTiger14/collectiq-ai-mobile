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
      ImageEnhancementPreset.autoEnhance => image_lib.adjustColor(
        image_lib.convolution(
          image_lib.adjustColor(working, brightness: 1.05, contrast: 1.08),
          filter: _sharpenKernel,
        ),
        saturation: 1.04,
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
}

const _sharpenKernel = <num>[0, -1, 0, -1, 5, -1, 0, -1, 0];
const _clarityKernel = <num>[-1, -1, -1, -1, 9, -1, -1, -1, -1];
