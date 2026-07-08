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
    this.title = 'Review photo',
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
    String title = 'Review photo',
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
  late final ScrollController _presetScrollController;
  late final Map<ImageEnhancementPreset, GlobalKey> _presetKeys;
  late ImageEnhancementPreset _selectedPreset;
  late String _activePath;
  Map<String, Object?> _metadata = const {};
  ImageQualityAssessment? _assessment;
  bool _isEnhancing = false;
  bool _isAssessing = true;
  bool _showOriginal = false;

  @override
  void initState() {
    super.initState();
    _presetScrollController = ScrollController();
    _presetKeys = {
      for (final preset in ImageEnhancementPreset.values) preset: GlobalKey(),
    };
    _selectedPreset = widget.initialPreset;
    _activePath = widget.image.path;
    _metadata = _metadataForPreset(_selectedPreset);
    _assessImage();
    if (_selectedPreset.isEnhanced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _selectPreset(_selectedPreset);
        }
      });
    }
  }

  @override
  void dispose() {
    _presetScrollController.dispose();
    super.dispose();
  }

  Future<void> _assessImage() async {
    final assessment = await widget.assessmentService.assess(widget.image.path);
    if (!mounted) {
      return;
    }
    setState(() {
      _assessment = assessment;
      _isAssessing = false;
      _metadata = _metadataWithAssessment(_metadata, assessment);
    });
    if (assessment.recommendationConfidence >= 0.72 &&
        assessment.recommendedPreset != _selectedPreset) {
      await _selectPreset(assessment.recommendedPreset, centerChip: true);
    } else {
      _centerSelectedChip();
    }
  }

  Map<String, Object?> _metadataForPreset(ImageEnhancementPreset preset) {
    return {
      'originalImagePath': widget.image.path,
      'activeImagePath': preset.isEnhanced ? _activePath : widget.image.path,
      'enhancementPreset': preset.id,
      'enhancementLabel': preset.label,
      'enhanced': preset.isEnhanced,
      'enhancedFileCreated': false,
      if (_assessment != null) ..._assessment!.toMetadataJson(),
    };
  }

  Map<String, Object?> _metadataWithAssessment(
    Map<String, Object?> metadata,
    ImageQualityAssessment assessment,
  ) {
    return {...metadata, ...assessment.toMetadataJson()};
  }

  Future<void> _selectPresetInternal(
    ImageEnhancementPreset preset, {
    required bool centerChip,
  }) async {
    setState(() {
      _selectedPreset = preset;
      _isEnhancing = preset.isEnhanced;
      if (!preset.isEnhanced) {
        _activePath = widget.image.path;
        _metadata = _metadataForPreset(preset);
      }
    });
    if (centerChip) {
      _centerSelectedChip();
    }

    if (!preset.isEnhanced) {
      return;
    }

    final result = await widget.enhancementService.enhance(
      originalPath: widget.image.path,
      preset: preset,
    );
    if (!mounted || _selectedPreset != preset) {
      return;
    }
    setState(() {
      _activePath = result.activePath;
      _metadata = {
        ...result.toMetadataJson(),
        if (_assessment != null) ..._assessment!.toMetadataJson(),
      };
      _isEnhancing = false;
    });
  }

  Future<void> _selectPreset(
    ImageEnhancementPreset preset, {
    bool centerChip = true,
  }) {
    return _selectPresetInternal(preset, centerChip: centerChip);
  }

  void _centerSelectedChip() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _presetKeys[_selectedPreset]?.currentContext;
      if (!mounted || context == null) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  void _usePhoto() {
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
    final previewPath = _showOriginal ? widget.image.path : _activePath;
    final previewFile = File(previewPath);
    final canShowImage = previewFile.existsSync();
    final assessment = _assessment;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: Center(
            child: canShowImage
                ? Image.file(
                    previewFile,
                    key: ValueKey('enhancement-preview-$previewPath'),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  )
                : const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white54,
                    size: 56,
                  ),
          ),
        ),
        if (_isEnhancing)
          const Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: LinearProgressIndicator(),
          ),
        Positioned.fill(
          child: GestureDetector(
            key: const ValueKey('enhancement-preview-compare-zone'),
            behavior: HitTestBehavior.translucent,
            onLongPressStart: (_) => setState(() => _showOriginal = true),
            onLongPressEnd: (_) => setState(() => _showOriginal = false),
          ),
        ),
        Positioned(
          top: AppSpacing.md,
          left: AppSpacing.md,
          child: IconButton.filledTonal(
            key: const ValueKey('enhancement-preview-cancel'),
            tooltip: 'Cancel',
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close),
          ),
        ),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showOriginal ? 'Original preview' : widget.subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _RecommendationBadge(
                    assessment: assessment,
                    isLoading: _isAssessing,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ReadinessSummary(
                    assessment: assessment,
                    isLoading: _isAssessing,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      key: const ValueKey('enhancement-preview-presets'),
                      controller: _presetScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: ImageEnhancementPreset.values.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final preset = ImageEnhancementPreset.values[index];
                        return KeyedSubtree(
                          key: _presetKeys[preset],
                          child: ChoiceChip(
                            key: ValueKey('enhancement-preview-${preset.id}'),
                            avatar: preset == assessment?.recommendedPreset
                                ? const Icon(Icons.auto_awesome, size: 14)
                                : null,
                            selected: preset == _selectedPreset,
                            label: Text(
                              preset == assessment?.recommendedPreset
                                  ? '${preset.shortLabel} AI'
                                  : preset.shortLabel,
                            ),
                            onSelected: (_) => _selectPreset(preset),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const ValueKey('enhancement-preview-compare'),
                      onPressed: () =>
                          setState(() => _showOriginal = !_showOriginal),
                      icon: Icon(
                        _showOriginal
                            ? Icons.auto_fix_high_outlined
                            : Icons.compare_outlined,
                        size: 16,
                      ),
                      label: Text(
                        _showOriginal ? 'Show enhanced' : 'Hold to compare',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('enhancement-preview-retake'),
                          onPressed: widget.onRetake,
                          child: Text(widget.retakeLabel),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey('enhancement-preview-use-photo'),
                          onPressed: _usePhoto,
                          child: Text(
                            (assessment?.readinessScore ?? 100) < 60
                                ? 'Use Anyway'
                                : 'Use Photo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendationBadge extends StatelessWidget {
  const _RecommendationBadge({
    required this.assessment,
    required this.isLoading,
  });

  final ImageQualityAssessment? assessment;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final value = assessment;
    return Container(
      key: const ValueKey('enhancement-ai-recommendation'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              isLoading || value == null
                  ? 'Checking image quality...'
                  : 'AI recommends: ${value.recommendedPreset.label}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (!isLoading && value != null)
            Text(
              '${value.readinessScore}/100',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReadinessSummary extends StatelessWidget {
  const _ReadinessSummary({required this.assessment, required this.isLoading});

  final ImageQualityAssessment? assessment;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final value = assessment;
    final checks = value == null
        ? const <_ReadinessCheck>[]
        : <_ReadinessCheck>[
            _ReadinessCheck(
              label: value.lighting >= 0.58
                  ? 'Lighting good'
                  : 'Lighting needs help',
              warning: value.lighting < 0.58,
            ),
            _ReadinessCheck(
              label: value.sharpness >= 0.45
                  ? 'Sharpness okay'
                  : 'Slight blur detected',
              warning: value.sharpness < 0.45,
            ),
            _ReadinessCheck(
              label: value.textClarity >= 0.52
                  ? 'Text readable'
                  : 'Package text may be hard to read',
              warning: value.textClarity < 0.52,
            ),
            if (value.glareRisk > 0.34)
              const _ReadinessCheck(
                label: 'Glare may affect text',
                warning: true,
              ),
          ];

    return Container(
      key: const ValueKey('enhancement-readiness-summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white12),
      ),
      child: isLoading || value == null
          ? Row(
              children: [
                const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Preparing preview...',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: Colors.white70),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AI Readiness',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${value.readinessScore}/100 - ${value.stateLabel}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: 6,
                  children: [
                    for (final check in checks.take(4))
                      _ReadinessPill(check: check),
                  ],
                ),
              ],
            ),
    );
  }
}

class _ReadinessCheck {
  const _ReadinessCheck({required this.label, required this.warning});

  final String label;
  final bool warning;
}

class _ReadinessPill extends StatelessWidget {
  const _ReadinessPill({required this.check});

  final _ReadinessCheck check;

  @override
  Widget build(BuildContext context) {
    final color = check.warning ? Colors.amberAccent : Colors.lightGreenAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            check.warning ? Icons.warning_amber_rounded : Icons.check_circle,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            check.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
