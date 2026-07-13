import 'dart:io';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/analyze_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScanWorkspaceScreen extends StatefulWidget {
  const ScanWorkspaceScreen({
    required this.photos,
    required this.primaryImagePath,
    required this.nextBestRole,
    required this.isBusy,
    required this.errorMessage,
    required this.onClose,
    required this.onSelectPhoto,
    required this.onCaptureNext,
    required this.onAddPhoto,
    required this.onAnalyze,
    super.key,
  });

  final List<ScannerPhotoSlot> photos;
  final String? primaryImagePath;
  final ScanCaptureRole nextBestRole;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onClose;
  final ValueChanged<ScannerPhotoSlot> onSelectPhoto;
  final VoidCallback onCaptureNext;
  final VoidCallback onAddPhoto;
  final VoidCallback onAnalyze;

  @override
  State<ScanWorkspaceScreen> createState() => _ScanWorkspaceScreenState();
}

class _ScanWorkspaceScreenState extends State<ScanWorkspaceScreen> {
  bool _showAnalyzeAnimation = false;

  @override
  void didUpdateWidget(covariant ScanWorkspaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBusy && !widget.isBusy && _showAnalyzeAnimation) {
      setState(() => _showAnalyzeAnimation = false);
    }
  }

  void _handleAnalyze() {
    if (widget.isBusy || widget.photos.isEmpty) {
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _showAnalyzeAnimation = true);
    widget.onAnalyze();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activePhoto = _activePhoto;
    final isAnalyzing = _showAnalyzeAnimation || widget.isBusy;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Scan Workspace'),
        leading: IconButton(
          key: const ValueKey('workspace-close'),
          onPressed: widget.onClose,
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedOpacity(
              key: const ValueKey('workspace-analyze-dimmed-content'),
              opacity: isAnalyzing ? 0.4 : 1,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WorkspaceHero(photo: activePhoto),
                    const SizedBox(height: AppSpacing.md),
                    WorkspaceFilmstrip(
                      photos: widget.photos,
                      selectedPath: activePhoto?.path,
                      onSelectPhoto: widget.onSelectPhoto,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    WorkspaceMetadata(
                      photoCount: widget.photos.length,
                      nextBestRole: widget.nextBestRole,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    WorkspaceActions(
                      nextBestRole: widget.nextBestRole,
                      canAnalyze: widget.photos.isNotEmpty && !isAnalyzing,
                      isBusy: isAnalyzing,
                      onCaptureNext: widget.onCaptureNext,
                      onAddPhoto: widget.onAddPhoto,
                      onAnalyze: _handleAnalyze,
                    ),
                    if (widget.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _WorkspaceError(message: widget.errorMessage!),
                    ],
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              reverseDuration: const Duration(milliseconds: 150),
              child: isAnalyzing && activePhoto != null
                  ? AnalyzeAnimationOverlay(
                      key: const ValueKey('analyze-animation-overlay'),
                      imagePath: activePhoto.path,
                    )
                  : const SizedBox.shrink(),
            ),
            if (isAnalyzing)
              const Positioned(
                bottom: AppSpacing.xl,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                child: Center(
                  child: Text(
                    'Analyzing collectible',
                    key: ValueKey('analyze-animation-label'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  ScannerPhotoSlot? get _activePhoto {
    if (widget.photos.isEmpty) {
      return null;
    }
    final primaryPath = widget.primaryImagePath?.trim();
    if (primaryPath != null && primaryPath.isNotEmpty) {
      for (final photo in widget.photos) {
        if (photo.path == primaryPath) {
          return photo;
        }
      }
    }
    return widget.photos.last;
  }
}

class WorkspaceFilmstrip extends StatelessWidget {
  const WorkspaceFilmstrip({
    required this.photos,
    required this.selectedPath,
    required this.onSelectPhoto,
    super.key,
  });

  final List<ScannerPhotoSlot> photos;
  final String? selectedPath;
  final ValueChanged<ScannerPhotoSlot> onSelectPhoto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (photos.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: const SizedBox(
          height: 104,
          child: Center(child: Text('No photos yet')),
        ),
      );
    }
    return SizedBox(
      key: const ValueKey('workspace-filmstrip'),
      height: 124,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final photo = photos[index];
          return TweenAnimationBuilder<double>(
            key: ValueKey('workspace-thumbnail-entry-${photo.path}'),
            tween: Tween<double>(begin: 1, end: 0),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: 1 - value,
                child: Transform.translate(
                  offset: Offset(28 * value, 0),
                  child: child,
                ),
              );
            },
            child: _WorkspaceThumbnail(
              photo: photo,
              selected: photo.path == selectedPath,
              onTap: () => onSelectPhoto(photo),
            ),
          );
        },
      ),
    );
  }
}

class WorkspaceMetadata extends StatelessWidget {
  const WorkspaceMetadata({
    required this.photoCount,
    required this.nextBestRole,
    super.key,
  });

  final int photoCount;
  final ScanCaptureRole nextBestRole;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const ValueKey('workspace-metadata'),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _RecommendedAngleBadge(role: nextBestRole),
            ),
            const SizedBox(height: AppSpacing.md),
            _MetadataRow(
              label: 'Photos',
              value: photoCount == 1 ? '1 photo' : '$photoCount photos',
              icon: Icons.photo_library_outlined,
              valueKey: 'workspace-metadata-photo-count-value',
            ),
          ],
        ),
      ),
    );
  }
}

class WorkspaceActions extends StatelessWidget {
  const WorkspaceActions({
    required this.nextBestRole,
    required this.canAnalyze,
    required this.isBusy,
    required this.onCaptureNext,
    required this.onAddPhoto,
    required this.onAnalyze,
    super.key,
  });

  final ScanCaptureRole nextBestRole;
  final bool canAnalyze;
  final bool isBusy;
  final VoidCallback onCaptureNext;
  final VoidCallback onAddPhoto;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('workspace-actions'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Capture Guide',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          nextBestRole.guidance,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const ValueKey('workspace-capture-next'),
          onPressed: isBusy ? null : onCaptureNext,
          icon: Icon(nextBestRole.icon),
          label: const Text('Capture Next Best Photo'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const ValueKey('workspace-add-photo'),
          onPressed: isBusy ? null : onAddPhoto,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add photo'),
        ),
        const SizedBox(height: 20),
        KeyedSubtree(
          key: const ValueKey('workspace-analyze'),
          child: FilledButton.icon(
            key: const ValueKey('scan-primary-Analyze Image'),
            onPressed: canAnalyze ? onAnalyze : null,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Analyze'),
          ),
        ),
      ],
    );
  }
}

class _WorkspaceHero extends StatelessWidget {
  const _WorkspaceHero({required this.photo});

  final ScannerPhotoSlot? photo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final photo = this.photo;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
          child: photo == null
              ? const Icon(Icons.photo_camera_outlined, size: 44)
              : _PhotoImage(path: photo.path, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _WorkspaceThumbnail extends StatelessWidget {
  const _WorkspaceThumbnail({
    required this.photo,
    required this.selected,
    required this.onTap,
  });

  final ScannerPhotoSlot photo;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final glowColor = colorScheme.primary.withValues(alpha: 0.28);
    return AnimatedScale(
      key: selected
          ? const ValueKey('workspace-primary-photo-highlight')
          : null,
      scale: selected ? 1.05 : 1,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: SizedBox(
        width: 96,
        child: InkWell(
          key: ValueKey('workspace-photo-${photo.path}'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? glowColor
                      : Colors.black.withValues(alpha: 0.10),
                  blurRadius: selected ? 22 : 14,
                  spreadRadius: selected ? 1 : 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.md - 1),
                    ),
                    child: _PhotoImage(path: photo.path, fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 6,
                  ),
                  child: Text(
                    _shortRole(photo.role),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendedAngleBadge extends StatelessWidget {
  const _RecommendedAngleBadge({required this.role});

  final ScanCaptureRole role;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: DecoratedBox(
        key: ValueKey('workspace-recommended-badge-${role.id}'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.14),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            '${_shortRole(role.id)} recommended',
            key: const ValueKey('workspace-recommended-badge-label'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.valueKey,
  });

  final String label;
  final String value;
  final IconData icon;
  final String valueKey;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          reverseDuration: const Duration(milliseconds: 100),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            value,
            key: ValueKey('$valueKey-$value'),
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _WorkspaceError extends StatelessWidget {
  const _WorkspaceError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          message,
          style: TextStyle(
            color: colorScheme.onErrorContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PhotoImage extends StatelessWidget {
  const _PhotoImage({required this.path, required this.fit});

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('sample://')) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.style_outlined,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 40,
        ),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: fit);
    }
    return const ColoredBox(
      color: Color(0xFFE5E7EB),
      child: Icon(Icons.broken_image_outlined),
    );
  }
}

String _shortRole(String role) {
  final captureRole = ScanCaptureRole.fromId(role);
  return switch (captureRole) {
    ScanCaptureRole.front => 'Front',
    ScanCaptureRole.back => 'Back',
    ScanCaptureRole.baseUnderside => 'Base',
    ScanCaptureRole.closeUp => 'Detail',
    ScanCaptureRole.barcode => 'Barcode',
    _ => captureRole.title.split('/').first.trim(),
  };
}
