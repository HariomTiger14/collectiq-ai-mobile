import 'dart:io';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/image_enhancement_preset.dart';
import 'package:collectiq_ai/features/scanner/services/image_enhancement_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageEnhancementPreviewResult {
  const ImageEnhancementPreviewResult({
    required this.originalImage,
    required this.activeImage,
    required this.preset,
    required this.metadata,
  });

  final XFile originalImage;
  final XFile activeImage;
  final ImageEnhancementPreset preset;
  final Map<String, Object?> metadata;

  bool get isEnhanced => preset.isEnhanced;
}

class ImageEnhancementPreviewPage extends StatelessWidget {
  const ImageEnhancementPreviewPage({
    required this.image,
    this.initialPreset = ImageEnhancementPreset.original,
    this.title = 'Review photo',
    this.subtitle = 'Choose the clearest version for analysis.',
    super.key,
  });

  final XFile image;
  final ImageEnhancementPreset initialPreset;
  final String title;
  final String subtitle;

  static Future<ImageEnhancementPreviewResult?> show(
    BuildContext context, {
    required XFile image,
    ImageEnhancementPreset initialPreset = ImageEnhancementPreset.original,
    String title = 'Review photo',
    String subtitle = 'Choose the clearest version for analysis.',
  }) {
    return Navigator.of(context).push<ImageEnhancementPreviewResult?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImageEnhancementPreviewPage(
          image: image,
          initialPreset: initialPreset,
          title: title,
          subtitle: subtitle,
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

  @override
  State<ImageEnhancementPreviewSurface> createState() =>
      _ImageEnhancementPreviewSurfaceState();
}

class _ImageEnhancementPreviewSurfaceState
    extends State<ImageEnhancementPreviewSurface> {
  final ImageEnhancementService _enhancementService =
      const ImageEnhancementService();
  late ImageEnhancementPreset _selectedPreset;
  late String _activePath;
  Map<String, Object?> _metadata = const {};
  bool _isEnhancing = false;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.initialPreset;
    _activePath = widget.image.path;
    _metadata = {
      'originalImagePath': widget.image.path,
      'activeImagePath': widget.image.path,
      'enhancementPreset': _selectedPreset.id,
      'enhancementLabel': _selectedPreset.label,
      'enhanced': _selectedPreset.isEnhanced,
      'enhancedFileCreated': false,
    };
    if (_selectedPreset.isEnhanced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _selectPreset(_selectedPreset);
        }
      });
    }
  }

  Future<void> _selectPreset(ImageEnhancementPreset preset) async {
    setState(() {
      _selectedPreset = preset;
      _isEnhancing = preset.isEnhanced;
      if (!preset.isEnhanced) {
        _activePath = widget.image.path;
        _metadata = {
          'originalImagePath': widget.image.path,
          'activeImagePath': widget.image.path,
          'enhancementPreset': preset.id,
          'enhancementLabel': preset.label,
          'enhanced': false,
          'enhancedFileCreated': false,
        };
      }
    });

    if (!preset.isEnhanced) {
      return;
    }

    final result = await _enhancementService.enhance(
      originalPath: widget.image.path,
      preset: preset,
    );
    if (!mounted || _selectedPreset != preset) {
      return;
    }
    setState(() {
      _activePath = result.activePath;
      _metadata = result.toMetadataJson();
      _isEnhancing = false;
    });
  }

  void _usePhoto() {
    widget.onUsePhoto(
      ImageEnhancementPreviewResult(
        originalImage: widget.image,
        activeImage: XFile(_activePath),
        preset: _selectedPreset,
        metadata: _metadata,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFile = File(_activePath);
    final canShowImage = activeFile.existsSync();
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: Center(
            child: canShowImage
                ? Image.file(
                    activeFile,
                    key: ValueKey('enhancement-preview-$_activePath'),
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
                    widget.subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      key: const ValueKey('enhancement-preview-presets'),
                      scrollDirection: Axis.horizontal,
                      itemCount: ImageEnhancementPreset.values.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final preset = ImageEnhancementPreset.values[index];
                        return ChoiceChip(
                          key: ValueKey('enhancement-preview-${preset.id}'),
                          selected: preset == _selectedPreset,
                          label: Text(preset.label),
                          onSelected: (_) => _selectPreset(preset),
                        );
                      },
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
                          child: const Text('Use Photo'),
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
