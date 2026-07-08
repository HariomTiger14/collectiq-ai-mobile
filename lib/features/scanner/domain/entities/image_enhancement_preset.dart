enum ImageEnhancementPreset {
  original,
  autoEnhance,
  brighten,
  contrast,
  sharpen,
  textPackageClarity,
  reduceGlare;

  String get id {
    return switch (this) {
      ImageEnhancementPreset.original => 'original',
      ImageEnhancementPreset.autoEnhance => 'auto_enhance',
      ImageEnhancementPreset.brighten => 'brighten',
      ImageEnhancementPreset.contrast => 'contrast',
      ImageEnhancementPreset.sharpen => 'sharpen',
      ImageEnhancementPreset.textPackageClarity => 'text_package_clarity',
      ImageEnhancementPreset.reduceGlare => 'reduce_glare',
    };
  }

  String get label {
    return switch (this) {
      ImageEnhancementPreset.original => 'Original',
      ImageEnhancementPreset.autoEnhance => 'Auto Enhance',
      ImageEnhancementPreset.brighten => 'Brighten',
      ImageEnhancementPreset.contrast => 'Contrast',
      ImageEnhancementPreset.sharpen => 'Sharpen',
      ImageEnhancementPreset.textPackageClarity => 'Text / Package Clarity',
      ImageEnhancementPreset.reduceGlare => 'Reduce Glare',
    };
  }

  bool get isEnhanced => this != ImageEnhancementPreset.original;

  static ImageEnhancementPreset fromId(Object? value) {
    if (value is! String) {
      return ImageEnhancementPreset.original;
    }
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'auto_enhance' || 'autoenhance' => ImageEnhancementPreset.autoEnhance,
      'brighten' => ImageEnhancementPreset.brighten,
      'contrast' => ImageEnhancementPreset.contrast,
      'sharpen' => ImageEnhancementPreset.sharpen,
      'text_package_clarity' ||
      'textpackageclarity' ||
      'clarity' => ImageEnhancementPreset.textPackageClarity,
      'reduce_glare' || 'reduceglare' => ImageEnhancementPreset.reduceGlare,
      _ => ImageEnhancementPreset.original,
    };
  }
}
