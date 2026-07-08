import 'dart:async';
import 'dart:io';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/image_enhancement_preset.dart';
import 'package:collectiq_ai/features/scanner/services/image_enhancement_service.dart';
import 'package:collectiq_ai/features/scanner/services/image_quality_assessment_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageEnhancementPreviewResult {
  const ImageEnhancementPreviewResult({
    required this.originalImage,
    required this.activeImage,
    required this.preset,
    required this.metadata,
    this.assessment,
  });

  final XFile originalImage;
  final XFile activeImage;
  final ImageEnhancementPreset preset;
  final Map<String, Object?> metadata;
  final ImageQualityAssessment? assessment;

  bool get isEnhanced => preset.isEnhanced;
}

class ImageEnhancementPreviewPage extends StatelessWidget {
  const ImageEnhancementPreviewPage({
    required this.image,
    this.initialPreset = ImageEnhancementPreset.original,
    this.title = 'Review Photo',
    this.subtitle = 'Choose the clearest version for analysis.',
    this.enhancementService = const ImageEnhancementService(),
    this.assessmentService = const ImageQualityAssessmentService(),
    super.key,
  });

  final XFile image;
  final ImageEnhancementPreset initialPreset;
  final String title;
  final String subtitle;
  final ImageEnhancementService enhancementService;
  final ImageQualityAssessmentService assessmentService;

  static Future<ImageEnhancementPreviewResult?> show(
    BuildContext context, {
    required XFile image,
    ImageEnhancementPreset initialPreset = ImageEnhancementPreset.original,
    String title = 'Review Photo',
    String subtitle = 'Choose the clearest version for analysis.',
    ImageEnhancementService enhancementService =
        const ImageEnhancementService(),
    ImageQualityAssessmentService assessmentService =
        const ImageQualityAssessmentService(),
  }) {
    return Navigator.of(context).push<ImageEnhancementPreviewResult?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImageEnhancementPreviewPage(
          image: image,
          initialPreset: initialPreset,
          title: title,
          subtitle: subtitle,
          enhancementService: enhancementService,
          assessmentService: assessmentService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ImageEnhancementPreviewSurface(
          image: image,
          initialPreset: initialPreset,
          title: title,
          subtitle: subtitle,
          enhancementService: enhancementService,
          assessmentService: assessmentService,
          onCancel: () => Navigator.of(context).pop(),
          onRetake: () => Navigator.of(context).pop(),
          onUsePhoto: (result) => Navigator.of(context).pop(result),
        ),
      ),
    );
  }
}

class ImageEnhancementPreviewSurface extends StatefulWidget {
  const ImageEnhancementPreviewSurface({
    required this.image,
    required this.initialPreset,
    required this.title,
    required this.subtitle,
    required this.onCancel,
    required this.onRetake,
    required this.onUsePhoto,
    this.retakeLabel = 'Retake',
    this.enhancementService = const ImageEnhancementService(),
    this.assessmentService = const ImageQualityAssessmentService(),
    super.key,
  });

  final XFile image;
  final ImageEnhancementPreset initialPreset;
  final String title;
  final String subtitle;
  final VoidCallback onCancel;
  final VoidCallback onRetake;
  final ValueChanged<ImageEnhancementPreviewResult> onUsePhoto;
  final String retakeLabel;
  final ImageEnhancementService enhancementService;
  final ImageQualityAssessmentService assessmentService;

  @override
  State<ImageEnhancementPreviewSurface> createState() =>
      _ImageEnhancementPreviewSurfaceState();
}

class _ImageEnhancementPreviewSurfaceState
    extends State<ImageEnhancementPreviewSurface> {
  late ImageEnhancementPreset _selectedPreset;
  late String _activePath;
  Map<String, Object?> _metadata = const {};
  ImageQualityAssessment? _assessment;
  ImageEnhancementResult? _cachedAiEnhance;
  Future<ImageEnhancementResult>? _aiEnhanceFuture;
  bool _isEnhancing = false;

  @override
  void initState() {
    super.initState();
    _selectedPreset = _simplifiedPreset(widget.initialPreset);
    _activePath = widget.image.path;
    _metadata = _metadataForPreset(ImageEnhancementPreset.original);
    unawaited(_assessImage());
    unawaited(_warmAiEnhance());
    if (_selectedPreset.isEnhanced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_selectPreset(_selectedPreset));
        }
      });
    }
  }

  Future<void> _assessImage() async {
    final assessment = await widget.assessmentService.assess(widget.image.path);
    if (!mounted) {
      return;
    }
    setState(() {
      _assessment = assessment;
      _metadata = _metadataWithAssessment(_metadata, assessment);
    });
  }

  Future<void> _warmAiEnhance() async {
    if (_cachedAiEnhance != null) {
      return;
    }
    _aiEnhanceFuture ??= widget.enhancementService.enhance(
      originalPath: widget.image.path,
      preset: ImageEnhancementPreset.autoEnhance,
    );
    final result = await _aiEnhanceFuture!;
    if (!mounted) {
      return;
    }
    _cachedAiEnhance = result;
    _aiEnhanceFuture = null;
    if (_selectedPreset == ImageEnhancementPreset.autoEnhance) {
      setState(() {
        _activePath = result.activePath;
        _metadata = _metadataForResult(result);
        _isEnhancing = false;
      });
    }
  }

  Future<void> _selectPreset(ImageEnhancementPreset preset) async {
    final simplifiedPreset = _simplifiedPreset(preset);
    if (simplifiedPreset == ImageEnhancementPreset.original) {
      setState(() {
        _selectedPreset = simplifiedPreset;
        _activePath = widget.image.path;
        _metadata = _metadataForPreset(simplifiedPreset);
        _isEnhancing = false;
      });
      return;
    }

    final cached = _cachedAiEnhance;
    setState(() {
      _selectedPreset = simplifiedPreset;
      _isEnhancing = cached == null;
      if (cached != null) {
        _activePath = cached.activePath;
        _metadata = _metadataForResult(cached);
      } else {
        _metadata = _metadataForPreset(simplifiedPreset);
      }
    });

    if (cached != null) {
      return;
    }

    await _warmAiEnhance();
  }

  Map<String, Object?> _metadataForPreset(ImageEnhancementPreset preset) {
    return {
      'originalImagePath': widget.image.path,
      'activeImagePath': preset.isEnhanced ? _activePath : widget.image.path,
      'enhancementPreset': preset.id,
      'selectedEnhancement': preset.isEnhanced ? 'aiEnhance' : 'original',
      'enhancementLabel': preset.label,
      'enhanced': preset.isEnhanced,
      'enhancedFileCreated': false,
      if (_assessment != null) ..._assessment!.toMetadataJson(),
    };
  }

  Map<String, Object?> _metadataForResult(ImageEnhancementResult result) {
    return {
      ...result.toMetadataJson(),
      'enhancementPreset': ImageEnhancementPreset.autoEnhance.id,
      'selectedEnhancement': 'aiEnhance',
      'enhancementLabel': ImageEnhancementPreset.autoEnhance.label,
      'enhanced': true,
      if (_assessment != null) ..._assessment!.toMetadataJson(),
    };
  }

  Map<String, Object?> _metadataWithAssessment(
    Map<String, Object?> metadata,
    ImageQualityAssessment assessment,
  ) {
    return {...metadata, ...assessment.toMetadataJson()};
  }

  Future<void> _usePhoto() async {
    if (_selectedPreset == ImageEnhancementPreset.autoEnhance &&
        _cachedAiEnhance == null) {
      setState(() => _isEnhancing = true);
      await _warmAiEnhance();
      if (!mounted) {
        return;
      }
    }
    widget.onUsePhoto(
      ImageEnhancementPreviewResult(
        originalImage: widget.image,
        activeImage: XFile(_activePath),
        preset: _selectedPreset,
        metadata: _metadata,
        assessment: _assessment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewFile = File(_activePath);
    final canShowImage = previewFile.existsSync();
    final recommended = _assessment?.recommendedPreset.isEnhanced ?? false;

    return Stack(
      key: const ValueKey('enhancement-preview-surface'),
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: canShowImage
                  ? Image.file(
                      previewFile,
                      key: ValueKey('enhancement-preview-$_activePath'),
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    )
                  : const Icon(
                      Icons.image_not_supported_outlined,
                      key: ValueKey('enhancement-preview-missing'),
                      color: Colors.white54,
                      size: 56,
                    ),
            ),
          ),
        ),
        _TopBar(
          title: widget.title,
          selectedPreset: _selectedPreset,
          onCancel: widget.onCancel,
        ),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyedSubtree(
                key: const ValueKey('enhancement-preview-presets'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _EnhancementTile(
                      key: const ValueKey('enhancement-preview-original'),
                      icon: Icons.image_outlined,
                      label: 'Original',
                      selected:
                          _selectedPreset == ImageEnhancementPreset.original,
                      onTap: () =>
                          _selectPreset(ImageEnhancementPreset.original),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _EnhancementTile(
                      key: const ValueKey('enhancement-preview-auto_enhance'),
                      icon: Icons.auto_fix_high_outlined,
                      label: 'AI Enhance',
                      selected:
                          _selectedPreset == ImageEnhancementPreset.autoEnhance,
                      recommended: recommended,
                      busy: _isEnhancing,
                      onTap: () =>
                          _selectPreset(ImageEnhancementPreset.autoEnhance),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('enhancement-preview-retake'),
                      onPressed: widget.onRetake,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        backgroundColor: Colors.black.withValues(alpha: 0.28),
                      ),
                      child: Text(widget.retakeLabel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('enhancement-preview-use-photo'),
                      onPressed: _usePhoto,
                      child: const Text('Use Photo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.selectedPreset,
    required this.onCancel,
  });

  final String title;
  final ImageEnhancementPreset selectedPreset;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSpacing.sm,
      left: AppSpacing.sm,
      right: AppSpacing.sm,
      child: Row(
        children: [
          IconButton.filledTonal(
            key: const ValueKey('enhancement-preview-cancel'),
            tooltip: 'Cancel',
            onPressed: onCancel,
            icon: const Icon(Icons.close),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: selectedPreset.isEnhanced
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'AI',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _EnhancementTile extends StatelessWidget {
  const _EnhancementTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.recommended = false,
    this.busy = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool recommended;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white70;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 132,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? Colors.white : Colors.white24,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 22),
                  if (busy)
                    const Positioned(
                      right: -10,
                      top: -8,
                      child: SizedBox.square(
                        dimension: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (recommended) ...[
                const SizedBox(height: 3),
                Text(
                  'Recommended',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

ImageEnhancementPreset _simplifiedPreset(ImageEnhancementPreset preset) {
  return preset.isEnhanced
      ? ImageEnhancementPreset.autoEnhance
      : ImageEnhancementPreset.original;
}
