import 'dart:io';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/captured_scan_image.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/image_enhancement_preset.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_plan.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_capture_plan_service.dart';
import 'package:collectiq_ai/features/scanner/domain/services/smart_scan_guidance_service.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/image_enhancement_preview_page.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum CaptureRoleCardStatus { missing, captured, warning }

class CaptureWorkspace extends StatelessWidget {
  const CaptureWorkspace({
    required this.goal,
    required this.category,
    required this.plan,
    required this.slots,
    required this.captureImages,
    required this.isBusy,
    required this.hasResult,
    this.selectedPath,
    this.activeRoleId,
    required this.onPrimaryCapture,
    required this.onAnalyze,
    required this.onCamera,
    required this.onGallery,
    required this.onSelectRole,
    required this.onPreview,
    required this.onUseAsPrimary,
    required this.onEnhance,
    required this.onDelete,
    required this.onSample,
    required this.onReset,
    super.key,
    this.selectedItemTitle,
    this.selectedItemStatus,
    this.categoryLabel,
    this.hasManualCategory = false,
    this.detectedCategory,
  });

  final ScanGoal goal;
  final CollectibleCategory category;
  final ScanCapturePlan plan;
  final Map<String, ScannerPhotoSlot> slots;
  final List<ScannerPhotoSlot> captureImages;
  final bool isBusy;
  final bool hasResult;
  final String? selectedPath;
  final String? activeRoleId;
  final VoidCallback? onPrimaryCapture;
  final VoidCallback? onAnalyze;
  final Future<void> Function(String role) onCamera;
  final Future<void> Function(String role) onGallery;
  final void Function(String role) onSelectRole;
  final void Function(ScannerPhotoSlot slot) onPreview;
  final void Function(ScannerPhotoSlot slot) onUseAsPrimary;
  final Future<void> Function(
    ScannerPhotoSlot slot,
    ImageEnhancementPreset preset,
  )
  onEnhance;
  final void Function(String imagePath) onDelete;
  final VoidCallback? onSample;
  final VoidCallback? onReset;
  final String? selectedItemTitle;
  final String? selectedItemStatus;
  final String? categoryLabel;
  final bool hasManualCategory;
  final String? detectedCategory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final roleCounts = _roleCounts(captureImages);
    final requiredCompleted = plan.requiredRoles
        .where((role) => (roleCounts[role.id] ?? 0) > 0)
        .length;
    final boundedRequiredCompleted = requiredCompleted
        .clamp(0, captureImages.length)
        .toInt();
    final optionalCount = captureImages.length - boundedRequiredCompleted;
    final nextRole = plan.nextRecommendedRole;
    final smartGuidance = const SmartScanGuidanceService().buildGuidance(
      category: category,
      images: _capturedImagesForGuidance(captureImages),
      goal: goal,
      selectedCategoryLabel: categoryLabel,
    );
    final recommendedRole = smartGuidance.recommendedNextRole ?? nextRole;
    final analyzeReady = smartGuidance.canAnalyze;
    final roles = [...plan.requiredRoles, ...plan.optionalRoles];
    final activeSlot = _activeSlot(captureImages, slots, selectedPath);
    final activeRole = activeSlot == null
        ? ScanCaptureRole.fromId(
            activeRoleId ?? recommendedRole?.id ?? ScanCaptureRole.front.id,
          )
        : ScanCaptureRole.fromId(activeSlot.role);
    final primaryLabel = analyzeReady
        ? 'Analyze ${captureImages.length} photo${captureImages.length == 1 ? '' : 's'}'
        : 'Capture Next Best Photo';
    final primaryIcon = analyzeReady
        ? Icons.auto_awesome_outlined
        : Icons.photo_camera_outlined;
    final primaryAction = analyzeReady ? onAnalyze : onPrimaryCapture;
    final primaryKey = analyzeReady
        ? const ValueKey('scan-primary-Analyze Image')
        : const ValueKey('scan-primary-Scan with Camera');

    return Container(
      key: const ValueKey('capture-workspace'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
              Icon(Icons.auto_awesome_outlined, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Scan Workspace',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _photoCountLabel(captureImages.length, analyzeReady),
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _CompactCaptureGuidance(
            imageCount: captureImages.length,
            guidance: smartGuidance,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: primaryKey,
              onPressed: isBusy ? null : primaryAction,
              icon: isBusy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(primaryIcon),
              label: Text(
                isBusy
                    ? analyzeReady
                          ? 'Analyzing scan'
                          : 'Working'
                    : primaryLabel,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (activeSlot != null) ...[
            _ActiveCapturePreview(
              slot: activeSlot,
              activeRole: activeRole,
              roleCount: roleCounts[activeRole.id] ?? 0,
              onOpenReview: () => _openPhotoReview(
                context,
                initialSlot: activeSlot,
                photos: captureImages,
                onSelect: onPreview,
                onRetake: (slot) => onCamera(slot.role),
                onDelete: (slot) => onDelete(slot.path),
                onUseAsPrimary: onUseAsPrimary,
                onEnhance: onEnhance,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          ScanImageFilmstrip(
            roles: roles,
            recommendedRoleId: recommendedRole?.id,
            slots: slots,
            captureImages: captureImages,
            roleCounts: roleCounts,
            selectedPath: selectedPath ?? activeSlot?.path,
            selectedRoleId: activeSlot == null ? activeRole.id : null,
            canAddPhoto: recommendedRole != null,
            isBusy: isBusy,
            onTapImage: (slot) => _openPhotoReview(
              context,
              initialSlot: slot,
              photos: captureImages,
              onSelect: onPreview,
              onRetake: (slot) => onCamera(slot.role),
              onDelete: (slot) => onDelete(slot.path),
              onUseAsPrimary: onUseAsPrimary,
              onEnhance: onEnhance,
            ),
            onSelectRole: onSelectRole,
            onCaptureRole: onCamera,
            onRetake: (slot) => onCamera(slot.role),
            onDelete: (slot) => onDelete(slot.path),
            onAddPhoto: isBusy ? null : onPrimaryCapture,
          ),
          const SizedBox(height: AppSpacing.sm),
          _CaptureProgress(
            requiredCompleted: requiredCompleted,
            requiredTotal: plan.requiredRoles.length,
            optionalCount: optionalCount < 0 ? 0 : optionalCount,
            analyzeReady: analyzeReady,
            recommendedRole: recommendedRole,
          ),
          if (captureImages.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _SelectedImageSummary(
              slot: activeSlot ?? captureImages.last,
              title: selectedItemTitle,
              status: selectedItemStatus,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('scan-secondary-Gallery'),
                  onPressed: isBusy ? null : () => onGallery(activeRole.id),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (analyzeReady && nextRole != null)
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('scan-secondary-Add more photos'),
                    onPressed: isBusy ? null : onPrimaryCapture,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text(
                      'Add photo to selected group',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              else if (slots.isNotEmpty || hasResult)
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('scan-secondary-New Scan'),
                    onPressed: isBusy ? null : onReset,
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('New Scan'),
                  ),
                )
              else
                Expanded(
                  child: TextButton.icon(
                    key: const ValueKey('scan-secondary-Use Sample Scan'),
                    onPressed: isBusy ? null : onSample,
                    icon: const Icon(Icons.science_outlined, size: 18),
                    label: const Text('Sample'),
                  ),
                ),
            ],
          ),
          if (slots.isNotEmpty || hasResult || analyzeReady) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('scan-secondary-Use Sample Scan'),
                onPressed: isBusy ? null : onSample,
                icon: const Icon(Icons.science_outlined, size: 16),
                label: const Text('Use Sample Scan'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Material(
              color: Colors.transparent,
              child: ExpansionTile(
                key: const ValueKey('capture-guide-expansion'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                initiallyExpanded: false,
                title: Text(
                  'Capture guide',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                children: [
                  _RoleChecklist(
                    roles: roles,
                    requiredRoles: plan.requiredRoles,
                    slots: slots,
                    roleCounts: roleCounts,
                    isBusy: isBusy,
                    onCapture: onCamera,
                    onGallery: onGallery,
                    onSelectRole: onSelectRole,
                    onPreview: onPreview,
                    onDelete: (role) {
                      final slot = _latestSlotForRole(captureImages, role);
                      if (slot != null) {
                        onDelete(slot.path);
                      }
                    },
                  ),
                  _GoalHint(goal: goal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScanImageFilmstrip extends StatefulWidget {
  const ScanImageFilmstrip({
    required this.roles,
    required this.slots,
    required this.captureImages,
    required this.roleCounts,
    required this.onTapImage,
    required this.onSelectRole,
    required this.onCaptureRole,
    required this.onRetake,
    required this.onDelete,
    super.key,
    this.requiredRoles = const [],
    this.recommendedRoleId,
    this.selectedPath,
    this.selectedRoleId,
    this.canAddPhoto = false,
    this.isBusy = false,
    this.onAddPhoto,
  });

  final List<ScanCaptureRole> roles;
  final List<ScanCaptureRole> requiredRoles;
  final String? recommendedRoleId;
  final Map<String, ScannerPhotoSlot> slots;
  final List<ScannerPhotoSlot> captureImages;
  final Map<String, int> roleCounts;
  final String? selectedPath;
  final String? selectedRoleId;
  final bool canAddPhoto;
  final bool isBusy;
  final VoidCallback? onAddPhoto;
  final void Function(ScannerPhotoSlot slot) onTapImage;
  final void Function(String role) onSelectRole;
  final Future<void> Function(String role) onCaptureRole;
  final void Function(ScannerPhotoSlot slot) onRetake;
  final void Function(ScannerPhotoSlot slot) onDelete;

  @override
  State<ScanImageFilmstrip> createState() => _ScanImageFilmstripState();
}

class _ScanImageFilmstripState extends State<ScanImageFilmstrip> {
  String? _selectedRoleId;

  @override
  Widget build(BuildContext context) {
    final visibleRoles = _selectedRoleId == null
        ? widget.roles
        : widget.roles.where((role) => role.id == _selectedRoleId).toList();
    final items = <Object>[
      for (final role in visibleRoles) ...[
        ...widget.captureImages.where((slot) => slot.role == role.id),
        if ((widget.roleCounts[role.id] ?? 0) == 0) role,
      ],
    ];
    return Column(
      key: const ValueKey('scan-image-filmstrip'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PhotoSetFilterChips(
          roles: widget.roles,
          roleCounts: widget.roleCounts,
          selectedRoleId: _selectedRoleId,
          recommendedRoleId: widget.recommendedRoleId,
          onSelected: (roleId) {
            setState(() => _selectedRoleId = roleId);
            if (roleId != null) {
              widget.onSelectRole(roleId);
            }
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length + (widget.canAddPhoto ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return _AddPhotoTile(onTap: widget.onAddPhoto);
              }
              final item = items[index];
              if (item is ScannerPhotoSlot) {
                final role = ScanCaptureRole.fromId(item.role);
                return _FilmstripPhotoTile(
                  key: ValueKey('filmstrip-photo-${item.role}-${item.path}'),
                  role: role,
                  slot: item,
                  countForRole: widget.roleCounts[item.role] ?? 1,
                  selected: item.path == widget.selectedPath,
                  onTap: () => widget.onTapImage(item),
                  onRetake: () => widget.onRetake(item),
                  onDelete: () => widget.onDelete(item),
                );
              }
              final role = item as ScanCaptureRole;
              return _FilmstripEmptyRoleTile(
                role: role,
                recommended: widget.recommendedRoleId == role.id,
                selected:
                    widget.selectedPath == null &&
                    widget.selectedRoleId == role.id &&
                    widget.slots[role.id] == null,
                onTap: widget.isBusy
                    ? null
                    : () {
                        setState(() => _selectedRoleId = role.id);
                        widget.onSelectRole(role.id);
                      },
                onCapture: widget.isBusy
                    ? null
                    : () => widget.onCaptureRole(role.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActiveCapturePreview extends StatelessWidget {
  const _ActiveCapturePreview({
    required this.slot,
    required this.activeRole,
    required this.roleCount,
    this.onOpenReview,
  });

  final ScannerPhotoSlot? slot;
  final ScanCaptureRole activeRole;
  final int roleCount;
  final VoidCallback? onOpenReview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final capturedSlot = slot;
    return InkWell(
      key: const ValueKey('scan-active-capture-preview'),
      onTap: onOpenReview,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  capturedSlot == null
                      ? _EmptyActivePreview(role: activeRole)
                      : ScanThumbnail(imagePath: capturedSlot.path),
                  if (capturedSlot?.isEnhanced ?? false)
                    const Positioned(
                      top: 10,
                      left: 10,
                      child: _EnhancedBadge(),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    capturedSlot == null
                        ? Icons.photo_camera_outlined
                        : Icons.fullscreen_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      capturedSlot == null
                          ? 'Start with a clear front photo'
                          : '${capturedSlot.label} · $roleCount photo${roleCount == 1 ? '' : 's'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (capturedSlot == null)
                    Text(
                      'camera',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    Text(
                      capturedSlot.isEnhanced
                          ? capturedSlot.enhancementPreset.label
                          : 'review',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoSetFilterChips extends StatelessWidget {
  const _PhotoSetFilterChips({
    required this.roles,
    required this.roleCounts,
    required this.selectedRoleId,
    required this.recommendedRoleId,
    required this.onSelected,
  });

  final List<ScanCaptureRole> roles;
  final Map<String, int> roleCounts;
  final String? selectedRoleId;
  final String? recommendedRoleId;
  final void Function(String? roleId) onSelected;

  @override
  Widget build(BuildContext context) {
    final total = roleCounts.values.fold<int>(0, (sum, count) => sum + count);
    return SizedBox(
      key: const ValueKey('photo-set-filter-chips'),
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: roles.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _PhotoSetChip(
              key: const ValueKey('photo-set-chip-all'),
              label: 'All $total',
              selected: selectedRoleId == null,
              onTap: () => onSelected(null),
            );
          }
          final role = roles[index - 1];
          final count = roleCounts[role.id] ?? 0;
          return _PhotoSetChip(
            key: ValueKey('photo-set-chip-${role.id}'),
            label: '${_shortRoleLabel(role)} $count',
            selected: selectedRoleId == role.id,
            recommended: recommendedRoleId == role.id,
            onTap: () => onSelected(role.id),
          );
        },
      ),
    );
  }
}

class _PhotoSetChip extends StatelessWidget {
  const _PhotoSetChip({
    required this.label,
    required this.selected,
    this.recommended = false,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ActionChip(
      label: Text(label, overflow: TextOverflow.ellipsis),
      onPressed: onTap,
      avatar: selected ? const Icon(Icons.check, size: 16) : null,
      side: BorderSide(
        color: selected || recommended
            ? colorScheme.primary
            : colorScheme.outlineVariant,
      ),
      backgroundColor: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.62)
          : recommended
          ? colorScheme.primary.withValues(alpha: 0.08)
          : colorScheme.surface,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected || recommended
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

Future<void> _openPhotoReview(
  BuildContext context, {
  required ScannerPhotoSlot initialSlot,
  required List<ScannerPhotoSlot> photos,
  required void Function(ScannerPhotoSlot slot) onSelect,
  required void Function(ScannerPhotoSlot slot) onRetake,
  required void Function(ScannerPhotoSlot slot) onDelete,
  required void Function(ScannerPhotoSlot slot) onUseAsPrimary,
  required Future<void> Function(
    ScannerPhotoSlot slot,
    ImageEnhancementPreset preset,
  )
  onEnhance,
}) {
  if (photos.isEmpty) {
    return Future<void>.value();
  }
  final initialIndex = photos.indexWhere(
    (slot) => slot.path == initialSlot.path,
  );
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    barrierColor: Colors.black,
    builder: (_) => _PhotoReviewCarousel(
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
      photos: photos,
      onSelect: onSelect,
      onRetake: onRetake,
      onDelete: onDelete,
      onUseAsPrimary: onUseAsPrimary,
      onEnhance: onEnhance,
    ),
  );
}

class _PhotoReviewCarousel extends StatefulWidget {
  const _PhotoReviewCarousel({
    required this.initialIndex,
    required this.photos,
    required this.onSelect,
    required this.onRetake,
    required this.onDelete,
    required this.onUseAsPrimary,
    required this.onEnhance,
  });

  final int initialIndex;
  final List<ScannerPhotoSlot> photos;
  final void Function(ScannerPhotoSlot slot) onSelect;
  final void Function(ScannerPhotoSlot slot) onRetake;
  final void Function(ScannerPhotoSlot slot) onDelete;
  final void Function(ScannerPhotoSlot slot) onUseAsPrimary;
  final Future<void> Function(
    ScannerPhotoSlot slot,
    ImageEnhancementPreset preset,
  )
  onEnhance;

  @override
  State<_PhotoReviewCarousel> createState() => _PhotoReviewCarouselState();
}

class _PhotoReviewCarouselState extends State<_PhotoReviewCarousel> {
  late final PageController _pageController;
  late List<ScannerPhotoSlot> _photos;
  late int _index;

  @override
  void initState() {
    super.initState();
    _photos = widget.photos.toList(growable: true);
    _index = widget.initialIndex.clamp(0, _photos.length - 1).toInt();
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _deleteCurrent() {
    final removed = _photos[_index];
    widget.onDelete(removed);
    if (_photos.length == 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _photos.removeAt(_index);
      if (_index >= _photos.length) {
        _index = _photos.length - 1;
      }
    });
    widget.onSelect(_photos[_index]);
    _pageController.jumpToPage(_index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = _photos[_index];
    return Material(
      key: const ValueKey('photo-review-carousel'),
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Photo ${_index + 1} of ${_photos.length}',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${active.label} · ${_capturedTimeLabel(active.capturedAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('photo-review-close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                key: const ValueKey('photo-review-page-view'),
                controller: _pageController,
                itemCount: _photos.length,
                onPageChanged: (index) {
                  setState(() => _index = index);
                  widget.onSelect(_photos[index]);
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: ColoredBox(
                        color: colorScheme.surface.withValues(alpha: 0.08),
                        child: _ReviewPhotoImage(path: _photos[index].path),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('photo-review-enhance'),
                    onPressed: () async {
                      final originalPath = active.originalPath ?? active.path;
                      final result = await ImageEnhancementPreviewPage.show(
                        context,
                        image: XFile(originalPath),
                        initialPreset: active.enhancementPreset,
                        title: 'Edit enhancement',
                        subtitle: 'Choose the clearest version for analysis.',
                      );
                      if (result != null) {
                        await widget.onEnhance(active, result.preset);
                      }
                    },
                    icon: const Icon(Icons.auto_fix_high_outlined),
                    label: const Text('Enhance/Edit'),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('photo-review-retake'),
                    onPressed: () => widget.onRetake(active),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Retake'),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('photo-review-primary'),
                    onPressed: () => widget.onUseAsPrimary(active),
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Use as Primary'),
                  ),
                  FilledButton.tonalIcon(
                    key: const ValueKey('photo-review-delete'),
                    onPressed: _deleteCurrent,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewPhotoImage extends StatelessWidget {
  const _ReviewPhotoImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('sample://')) {
      return const Center(
        child: Icon(Icons.image_outlined, color: Colors.white70, size: 72),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.contain);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: BoxFit.contain);
    }
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.white70,
          size: 72,
        ),
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
    this.compact = false,
  });

  final ScanCaptureRole role;
  final bool requiredRole;
  final ScannerPhotoSlot? slot;
  final bool isBusy;
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final VoidCallback onPreview;
  final VoidCallback onDelete;
  final bool compact;

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
                if (!compact) ...[
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

class _EmptyActivePreview extends StatelessWidget {
  const _EmptyActivePreview({required this.role});

  final ScanCaptureRole role;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              color: colorScheme.primary,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              role == ScanCaptureRole.front
                  ? 'Start with a clear front photo'
                  : 'Capture ${role.title}',
              textAlign: TextAlign.center,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactCaptureGuidance extends StatelessWidget {
  const _CompactCaptureGuidance({
    required this.imageCount,
    required this.guidance,
  });

  final int imageCount;
  final SmartScanGuidance guidance;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('scan-workspace-compact-guidance'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            guidance.canAnalyze
                ? Icons.check_circle_outline
                : Icons.photo_camera,
            color: guidance.canAnalyze
                ? colorScheme.primary
                : colorScheme.secondary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guidance.headline,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  guidance.guidance,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
                if (guidance.softWarning != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    guidance.softWarning!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$imageCount photo${imageCount == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChecklist extends StatelessWidget {
  const _RoleChecklist({
    required this.roles,
    required this.requiredRoles,
    required this.slots,
    required this.roleCounts,
    required this.isBusy,
    required this.onCapture,
    required this.onGallery,
    required this.onSelectRole,
    required this.onPreview,
    required this.onDelete,
  });

  final List<ScanCaptureRole> roles;
  final List<ScanCaptureRole> requiredRoles;
  final Map<String, ScannerPhotoSlot> slots;
  final Map<String, int> roleCounts;
  final bool isBusy;
  final Future<void> Function(String role) onCapture;
  final Future<void> Function(String role) onGallery;
  final void Function(String role) onSelectRole;
  final void Function(ScannerPhotoSlot slot) onPreview;
  final void Function(String role) onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        key: const ValueKey('photo-checklist'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        initiallyExpanded: false,
        title: Text(
          'Photo checklist',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${roleCounts.values.fold<int>(0, (sum, count) => sum + count)} photos captured',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          for (final role in roles)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: CaptureRoleCard(
                role: role,
                requiredRole: requiredRoles.contains(role),
                slot: slots[role.id],
                isBusy: isBusy,
                compact: true,
                onCapture: () => onCapture(role.id),
                onGallery: () => onGallery(role.id),
                onPreview: () {
                  final slot = slots[role.id];
                  if (slot != null) {
                    onPreview(slot);
                  } else {
                    onSelectRole(role.id);
                  }
                },
                onDelete: () => onDelete(role.id),
              ),
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

class _EnhancedBadge extends StatelessWidget {
  const _EnhancedBadge({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return PremiumBadge(
      label: 'Enhanced',
      icon: Icons.auto_fix_high_outlined,
      compact: compact,
      maxWidth: 88,
    );
  }
}

class _CaptureProgress extends StatelessWidget {
  const _CaptureProgress({
    required this.requiredCompleted,
    required this.requiredTotal,
    required this.optionalCount,
    required this.analyzeReady,
    required this.recommendedRole,
  });

  final int requiredCompleted;
  final int requiredTotal;
  final int optionalCount;
  final bool analyzeReady;
  final ScanCaptureRole? recommendedRole;

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
                analyzeReady ? 'Ready when you are' : 'Recommended next photo',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (recommendedRole != null)
              _RoleBadge(
                label: _shortRoleLabel(recommendedRole!),
                emphasized: true,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          analyzeReady
              ? 'Analyze is available. More photos are optional and can improve confidence.'
              : 'Start with a front/package photo to unlock analysis.',
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

class _FilmstripPhotoTile extends StatelessWidget {
  const _FilmstripPhotoTile({
    required this.role,
    required this.slot,
    required this.countForRole,
    required this.selected,
    required this.onTap,
    required this.onRetake,
    required this.onDelete,
    super.key,
  });

  final ScanCaptureRole role;
  final ScannerPhotoSlot slot;
  final int countForRole;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRetake;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final warning = _hasWarning(slot.qualityMetadata);
    return SizedBox(
      width: 124,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: DecoratedBox(
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
            boxShadow: selected ? AppElevation.level1 : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: ScanThumbnail(imagePath: slot.path),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _TinyCountPill(label: '$countForRole'),
                      ),
                      if (slot.isEnhanced)
                        const Positioned(
                          left: 6,
                          bottom: 6,
                          child: _EnhancedBadge(compact: true),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  role.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        slot.isEnhanced
                            ? slot.enhancementPreset.label
                            : warning
                            ? 'Review'
                            : 'Captured',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: warning
                              ? colorScheme.tertiary
                              : colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox.square(
                      dimension: 26,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'Add another ${role.title}',
                        onPressed: onRetake,
                        icon: const Icon(Icons.add_a_photo_outlined, size: 15),
                      ),
                    ),
                    SizedBox.square(
                      dimension: 26,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'Delete photo',
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
      ),
    );
  }
}

class _FilmstripEmptyRoleTile extends StatelessWidget {
  const _FilmstripEmptyRoleTile({
    required this.role,
    required this.recommended,
    required this.selected,
    required this.onTap,
    required this.onCapture,
  });

  final ScanCaptureRole role;
  final bool recommended;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onCapture;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      key: ValueKey('filmstrip-${role.id}'),
      width: 116,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.64),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected || recommended
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: selected || recommended ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Icon(
                      role.icon,
                      color: colorScheme.primary,
                      size: AppIconSizes.lg,
                    ),
                  ),
                ),
                Text(
                  role.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        recommended ? 'Recommended' : 'Optional',
                        style: textTheme.labelSmall?.copyWith(
                          color: recommended
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: recommended
                              ? FontWeight.w900
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox.square(
                      dimension: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'Capture ${role.title}',
                        onPressed: onCapture,
                        icon: const Icon(Icons.photo_camera_outlined, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
    return PremiumBadge.category(
      label: label,
      icon: emphasized ? Icons.check_circle_outline : null,
      compact: true,
      maxWidth: 92,
    );
  }
}

class _TinyCountPill extends StatelessWidget {
  const _TinyCountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
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

String _statusLabel(CaptureRoleCardStatus status) {
  return switch (status) {
    CaptureRoleCardStatus.missing => 'Missing',
    CaptureRoleCardStatus.captured => 'Captured',
    CaptureRoleCardStatus.warning => 'Warning',
  };
}

String _shortRoleLabel(ScanCaptureRole role) {
  return switch (role) {
    ScanCaptureRole.front => 'Front',
    ScanCaptureRole.back => 'Back',
    ScanCaptureRole.leftSide => 'Left',
    ScanCaptureRole.rightSide => 'Right',
    ScanCaptureRole.closeUp => 'Close-up',
    ScanCaptureRole.edge => 'Edge',
    ScanCaptureRole.side => 'Side',
    ScanCaptureRole.top => 'Top',
    ScanCaptureRole.bottom => 'Bottom',
    ScanCaptureRole.baseUnderside => 'Base',
    ScanCaptureRole.barcode => 'Barcode',
    ScanCaptureRole.cornerCondition => 'Corner',
    ScanCaptureRole.surfaceGlare => 'Glare',
    ScanCaptureRole.dateMint => 'Date',
    ScanCaptureRole.serialOrMark => 'Serial',
    ScanCaptureRole.damageDetail => 'Damage',
    ScanCaptureRole.angledReflective => 'Angle',
  };
}

bool _hasWarning(Map<String, Object?> qualityMetadata) {
  return qualityMetadata['severity'] == 'WARNING';
}

ScannerPhotoSlot? _activeSlot(
  List<ScannerPhotoSlot> captureImages,
  Map<String, ScannerPhotoSlot> slots,
  String? selectedPath,
) {
  if (slots.isEmpty && captureImages.isEmpty) {
    return null;
  }
  final normalizedPath = selectedPath?.trim();
  if (normalizedPath != null && normalizedPath.isNotEmpty) {
    for (final slot in captureImages) {
      if (slot.path == normalizedPath) {
        return slot;
      }
    }
  }
  return captureImages.lastOrNull ??
      slots[ScanCaptureRole.front.id] ??
      slots.values.lastOrNull;
}

ScannerPhotoSlot? _latestSlotForRole(
  List<ScannerPhotoSlot> slots,
  String role,
) {
  for (final slot in slots.reversed) {
    if (slot.role == role) {
      return slot;
    }
  }
  return null;
}

Map<String, int> _roleCounts(List<ScannerPhotoSlot> slots) {
  final counts = <String, int>{};
  for (final slot in slots) {
    counts[slot.role] = (counts[slot.role] ?? 0) + 1;
  }
  return counts;
}

List<CapturedScanImage> _capturedImagesForGuidance(
  List<ScannerPhotoSlot> slots,
) {
  return [
    for (final slot in slots)
      CapturedScanImage(
        path: slot.path,
        role: ScanCaptureRole.fromId(slot.role),
        source: slot.source,
        originalPath: slot.originalPath,
        enhancementPreset: slot.enhancementPreset.id,
        qualityMetadata: slot.qualityMetadata,
      ),
  ];
}

String _capturedTimeLabel(DateTime? capturedAt) {
  if (capturedAt == null) {
    return 'Just captured';
  }
  final local = capturedAt.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _photoCountLabel(int count, bool analyzeReady) {
  if (count == 1) {
    return analyzeReady ? '1 photo ready' : '1 photo captured';
  }
  return analyzeReady ? '$count photos ready' : '$count photos captured';
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
