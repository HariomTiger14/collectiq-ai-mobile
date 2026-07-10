import 'dart:io';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_plan.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:flutter/material.dart';

enum CaptureRoleCardStatus { missing, captured, warning }

class CaptureWorkspace extends StatelessWidget {
  const CaptureWorkspace({
    required this.goal,
    required this.plan,
    required this.slots,
    required this.isBusy,
    required this.hasResult,
    required this.onPrimaryCapture,
    required this.onAnalyze,
    required this.onCamera,
    required this.onGallery,
    required this.onPreview,
    required this.onDelete,
    required this.onSample,
    required this.onReset,
    super.key,
    this.selectedItemTitle,
    this.selectedItemStatus,
  });

  final ScanGoal goal;
  final ScanCapturePlan plan;
  final Map<String, ScannerPhotoSlot> slots;
  final bool isBusy;
  final bool hasResult;
  final VoidCallback? onPrimaryCapture;
  final VoidCallback? onAnalyze;
  final Future<void> Function(String role) onCamera;
  final Future<void> Function(String role) onGallery;
  final void Function(ScannerPhotoSlot slot) onPreview;
  final void Function(String role) onDelete;
  final VoidCallback? onSample;
  final VoidCallback? onReset;
  final String? selectedItemTitle;
  final String? selectedItemStatus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final requiredCompleted = plan.requiredRoles
        .where((role) => slots.containsKey(role.id))
        .length;
    final optionalCount = slots.length - requiredCompleted;
    final nextRole = plan.nextRecommendedRole;
    final analyzeReady = plan.isMinimumReadyForAnalyze;
    final roles = [...plan.requiredRoles, ...plan.optionalRoles];

    return Container(
      key: const ValueKey('capture-workspace'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.document_scanner_outlined, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Capture Workspace',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${slots.length} ready',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _NextRecommendedBlock(role: nextRole, guidance: plan.userGuidance),
          const SizedBox(height: AppSpacing.md),
          _CaptureProgress(
            requiredCompleted: requiredCompleted,
            requiredTotal: plan.requiredRoles.length,
            optionalCount: optionalCount < 0 ? 0 : optionalCount,
            completionPercentage: plan.completionPercentage,
            analyzeReady: analyzeReady,
          ),
          if (slots.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _SelectedImageSummary(
              slot: slots.values.last,
              title: selectedItemTitle,
              status: selectedItemStatus,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ScanImageFilmstrip(
            images: slots.values.toList(growable: false),
            selectedPath: slots.values.lastOrNull?.path,
            canAddPhoto: nextRole != null,
            onTapImage: onPreview,
            onRetake: (slot) => onCamera(slot.role),
            onDelete: (slot) => onDelete(slot.role),
            onAddPhoto: isBusy ? null : onPrimaryCapture,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final role in roles) ...[
            CaptureRoleCard(
              role: role,
              requiredRole: plan.requiredRoles.contains(role),
              slot: slots[role.id],
              isBusy: isBusy,
              onCapture: () => onCamera(role.id),
              onGallery: () => onGallery(role.id),
              onPreview: () {
                final slot = slots[role.id];
                if (slot != null) {
                  onPreview(slot);
                }
              },
              onDelete: () => onDelete(role.id),
            ),
            if (role != roles.last) const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('scan-primary-Scan with Camera'),
              onPressed: isBusy ? null : onPrimaryCapture,
              icon: Icon(
                hasResult
                    ? Icons.refresh_outlined
                    : Icons.photo_camera_outlined,
              ),
              label: Text(
                hasResult
                    ? 'Add more guided photos'
                    : nextRole == null
                    ? 'Add Optional Photo'
                    : 'Capture ${nextRole.title}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              key: const ValueKey('scan-primary-Analyze Image'),
              onPressed: isBusy || !analyzeReady ? null : onAnalyze,
              icon: isBusy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(
                isBusy
                    ? 'Analyzing scan'
                    : analyzeReady
                    ? 'Analyze ${slots.length} photo${slots.length == 1 ? '' : 's'}'
                    : _disabledAnalyzeText(plan, slots),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('scan-secondary-Gallery'),
                onPressed: isBusy
                    ? null
                    : () => onGallery((nextRole ?? ScanCaptureRole.front).id),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('scan-secondary-Use Sample Scan'),
                onPressed: isBusy ? null : onSample,
                icon: const Icon(Icons.science_outlined),
                label: const Text('Use Sample Scan'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy || slots.isEmpty ? null : onReset,
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('New Scan'),
              ),
            ],
          ),
          _GoalHint(goal: goal),
        ],
      ),
    );
  }
}

class ScanImageFilmstrip extends StatelessWidget {
  const ScanImageFilmstrip({
    required this.images,
    required this.onTapImage,
    required this.onRetake,
    required this.onDelete,
    super.key,
    this.selectedPath,
    this.canAddPhoto = false,
    this.onAddPhoto,
  });

  final List<ScannerPhotoSlot> images;
  final String? selectedPath;
  final bool canAddPhoto;
  final VoidCallback? onAddPhoto;
  final void Function(ScannerPhotoSlot slot) onTapImage;
  final void Function(ScannerPhotoSlot slot) onRetake;
  final void Function(ScannerPhotoSlot slot) onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('scan-image-filmstrip'),
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length + (canAddPhoto ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index >= images.length) {
            return _AddPhotoTile(onTap: onAddPhoto);
          }
          final slot = images[index];
          return _FilmstripTile(
            slot: slot,
            selected: slot.path == selectedPath,
            onTap: () => onTapImage(slot),
            onRetake: () => onRetake(slot),
            onDelete: () => onDelete(slot),
          );
        },
      ),
    );
  }
}

class CaptureRoleCard extends StatelessWidget {
  const CaptureRoleCard({
    required this.role,
    required this.requiredRole,
    required this.isBusy,
    required this.onCapture,
    required this.onGallery,
    required this.onPreview,
    required this.onDelete,
    super.key,
    this.slot,
  });

  final ScanCaptureRole role;
  final bool requiredRole;
  final ScannerPhotoSlot? slot;
  final bool isBusy;
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final VoidCallback onPreview;
  final VoidCallback onDelete;

  CaptureRoleCardStatus get status {
    if (slot == null) {
      return CaptureRoleCardStatus.missing;
    }
    return _hasWarning(slot!.qualityMetadata)
        ? CaptureRoleCardStatus.warning
        : CaptureRoleCardStatus.captured;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasPhoto = slot != null;
    final warning = status == CaptureRoleCardStatus.warning;

    return Container(
      key: ValueKey('capture-role-card-${role.id}'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: warning ? colorScheme.tertiary : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: hasPhoto ? onPreview : null,
            child: SizedBox.square(
              dimension: 42,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: hasPhoto
                    ? ScanThumbnail(imagePath: slot!.path)
                    : ColoredBox(
                        color: colorScheme.primary.withValues(alpha: 0.10),
                        child: Icon(role.icon, color: colorScheme.primary),
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        role.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _RoleBadge(
                      label: requiredRole ? 'Required' : 'Optional',
                      emphasized: requiredRole,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _statusLabel(status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: warning
                        ? colorScheme.tertiary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role.guidance,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: hasPhoto
                ? 'Retake ${role.title}'
                : 'Capture ${role.title}',
            onPressed: isBusy ? null : onCapture,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              hasPhoto ? Icons.refresh_outlined : Icons.photo_camera_outlined,
              size: 18,
            ),
          ),
          IconButton(
            tooltip: 'Choose ${role.title} from gallery',
            onPressed: isBusy ? null : onGallery,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
          ),
          if (hasPhoto)
            IconButton(
              tooltip: 'Delete ${role.title}',
              onPressed: isBusy ? null : onDelete,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, size: 18),
            ),
        ],
      ),
    );
  }
}

class ScanThumbnail extends StatelessWidget {
  const ScanThumbnail({required this.imagePath, super.key});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (imagePath.startsWith('sample://')) {
      return ColoredBox(
        color: colorScheme.primaryContainer,
        child: Icon(Icons.style_outlined, color: colorScheme.primary),
      );
    }
    if (imagePath.startsWith('assets/')) {
      return Image.asset(imagePath, fit: BoxFit.cover);
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(imagePath, fit: BoxFit.cover);
    }
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.broken_image_outlined, color: colorScheme.primary),
      ),
    );
  }
}

class _NextRecommendedBlock extends StatelessWidget {
  const _NextRecommendedBlock({required this.role, required this.guidance});

  final ScanCaptureRole? role;
  final String guidance;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      key: const ValueKey('next-recommended-capture'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_outlined, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next recommended:',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role == null ? guidance : guidance,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureProgress extends StatelessWidget {
  const _CaptureProgress({
    required this.requiredCompleted,
    required this.requiredTotal,
    required this.optionalCount,
    required this.completionPercentage,
    required this.analyzeReady,
  });

  final int requiredCompleted;
  final int requiredTotal;
  final int optionalCount;
  final double completionPercentage;
  final bool analyzeReady;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$requiredCompleted of $requiredTotal required photos captured',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${(completionPercentage * 100).round()}%',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: completionPercentage,
          minHeight: 7,
          borderRadius: BorderRadius.circular(999),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          analyzeReady
              ? 'Ready for analysis'
              : 'Add ${requiredTotal - requiredCompleted} more required photo${requiredTotal - requiredCompleted == 1 ? '' : 's'}',
          style: textTheme.bodySmall?.copyWith(
            color: analyzeReady
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (optionalCount > 0)
          Text(
            '$optionalCount optional photo${optionalCount == 1 ? '' : 's'} added',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _SelectedImageSummary extends StatelessWidget {
  const _SelectedImageSummary({
    required this.slot,
    required this.title,
    required this.status,
  });

  final ScannerPhotoSlot slot;
  final String? title;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(Icons.check_circle_outline, size: 18, color: colorScheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            title ?? _selectedTitle(slot),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            status ?? 'Ready for AI analysis',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilmstripTile extends StatelessWidget {
  const _FilmstripTile({
    required this.slot,
    required this.selected,
    required this.onTap,
    required this.onRetake,
    required this.onDelete,
  });

  final ScannerPhotoSlot slot;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRetake;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final warning = _hasWarning(slot.qualityMetadata);
    return SizedBox(
      key: ValueKey('filmstrip-${slot.role}'),
      width: 104,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : warning
                  ? colorScheme.tertiary
                  : colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: ScanThumbnail(imagePath: slot.path),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                slot.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              Row(
                children: [
                  Icon(
                    warning
                        ? Icons.warning_amber_outlined
                        : Icons.check_circle_outline,
                    size: 14,
                    color: warning ? colorScheme.tertiary : colorScheme.primary,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      warning ? 'Warning' : 'Accepted',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: warning
                            ? colorScheme.tertiary
                            : colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox.square(
                    dimension: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Retake ${slot.label}',
                      onPressed: onRetake,
                      icon: const Icon(Icons.refresh_outlined, size: 15),
                    ),
                  ),
                  SizedBox.square(
                    dimension: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Delete ${slot.label}',
                      onPressed: onDelete,
                      icon: const Icon(Icons.close, size: 15),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('filmstrip-add-photo'),
      width: 104,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: const Icon(Icons.add_photo_alternate_outlined),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.emphasized});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: emphasized
            ? colorScheme.primary.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: emphasized
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GoalHint extends StatelessWidget {
  const _GoalHint({required this.goal});

  final ScanGoal goal;

  @override
  Widget build(BuildContext context) {
    if (goal != ScanGoal.prepareForSale) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        'Listing asset generation is coming soon.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

String _disabledAnalyzeText(
  ScanCapturePlan plan,
  Map<String, ScannerPhotoSlot> slots,
) {
  final missingRequired = plan.requiredRoles
      .where((role) => !slots.containsKey(role.id))
      .toList();
  if (missingRequired.length == 1) {
    return 'Add ${missingRequired.single.title.toLowerCase()} photo to continue';
  }
  return 'Add ${missingRequired.length} more required photos';
}

String _statusLabel(CaptureRoleCardStatus status) {
  return switch (status) {
    CaptureRoleCardStatus.missing => 'Missing',
    CaptureRoleCardStatus.captured => 'Captured',
    CaptureRoleCardStatus.warning => 'Warning',
  };
}

bool _hasWarning(Map<String, Object?> qualityMetadata) {
  return qualityMetadata['severity'] == 'WARNING';
}

String _selectedTitle(ScannerPhotoSlot slot) {
  if (slot.source == 'sample') {
    return 'Sample Sports Card';
  }
  if (slot.source == 'gallery' && slot.role == ScanCaptureRole.front.id) {
    return 'Gallery image';
  }
  if (slot.source == 'camera' && slot.role == ScanCaptureRole.front.id) {
    return 'Captured image';
  }
  return '${slot.label} photo';
}
