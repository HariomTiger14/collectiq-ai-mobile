import 'dart:io';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/image_enhancement_preset.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_plan.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_capture_plan_service.dart';
import 'package:collectiq_ai/features/scanner/presentation/scan_flow_debug.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/scan_workspace_screen.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({this.onViewPortfolio, super.key});

  final VoidCallback? onViewPortfolio;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  late final ProviderSubscription<ScannerState> _scannerSubscription;

  @override
  void initState() {
    super.initState();
    debugPrint('[ScannerScreen] init');
    WidgetsBinding.instance.addObserver(this);
    _scannerSubscription = ref.listenManual<ScannerState>(
      scannerControllerProvider,
      (previous, next) {
        if (previous?.scanResult != null && next.scanResult == null) {
          debugPrint('[ScannerScreen] result cleared');
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(scannerControllerProvider.notifier)
          .recoverLostPickerData(reason: 'scan-screen-startup');
    });
  }

  @override
  void dispose() {
    debugPrint('[ScannerScreen] dispose');
    WidgetsBinding.instance.removeObserver(this);
    _scannerSubscription.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[ScannerScreen] lifecycle $state');
    final scannerController = ref.read(scannerControllerProvider.notifier);
    final scannerState = ref.read(scannerControllerProvider);
    logCollectIqScanFlow(
      state == AppLifecycleState.resumed
          ? 'app lifecycle resumed'
          : state == AppLifecycleState.paused
          ? 'app lifecycle paused'
          : 'app lifecycle $state',
      selectedImagePath: scannerState.selectedImagePath,
      isLoading: scannerState.isLoading,
      isPreparingImage: scannerState.isPreparingImage,
      isPickerActive: scannerController.isPickerActiveForDebug,
      isRecoveringLostData: scannerController.isRecoveringLostDataForDebug,
      currentTabIndex: ref.read(appShellTabControllerProvider),
    );
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }

    scannerController.recoverLostPickerData(reason: 'app-resumed');
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerControllerProvider);
    final scannerController = ref.read(scannerControllerProvider.notifier);
    final currentTabIndex = ref.read(appShellTabControllerProvider);
    final selectedImagePath = scannerState.selectedImagePath;
    final scanResult = scannerState.scanResult;
    final activeGoal =
        scannerState.scanSession?.scanGoal ?? ScanGoal.identifyValue;
    final activePlan =
        scannerState.scanSession?.capturePlan ??
        const ScanCapturePlanService().buildPlan(
          activeGoal,
          null,
          scannerState.scanSession?.capturedImages ?? const [],
        );
    final showPickerShell =
        selectedImagePath == null &&
        (scannerState.isLoading || scannerState.isPreparingImage);
    logCollectIqScanFlow(
      'scan screen build',
      selectedImagePath: selectedImagePath,
      isLoading: scannerState.isLoading,
      isPreparingImage: scannerState.isPreparingImage,
      isPickerActive: scannerController.isPickerActiveForDebug,
      isRecoveringLostData: scannerController.isRecoveringLostDataForDebug,
      currentTabIndex: currentTabIndex,
      details: {
        'showPickerShell': showPickerShell,
        'showPreview': selectedImagePath != null,
        'showResult': scanResult != null,
      },
    );

    if (scanResult == null) {
      final nextRole = _nextWorkspaceRole(activePlan, scannerState).id;
      final workspaceRole = _nextWorkspaceRole(activePlan, scannerState);
      final workspacePhotos = scannerState.captureImages.isNotEmpty
          ? scannerState.captureImages
          : selectedImagePath == null
          ? <ScannerPhotoSlot>[]
          : [
              ScannerPhotoSlot(
                role: nextRole,
                label: _workspaceRoleLabel(nextRole),
                path: selectedImagePath,
                source: 'camera',
                image: scannerState.selectedImage,
                originalPath: selectedImagePath,
                capturedAt: DateTime.now(),
              ),
            ];
      final activeSlot = _activeScanSlot(workspacePhotos, selectedImagePath);
      if (workspacePhotos.isNotEmpty) {
        return ScanWorkspaceScreen(
          photos: workspacePhotos,
          primaryImagePath: scannerState.primaryImagePath ?? selectedImagePath,
          detectedCategory: _workspaceDetectedCategory(scannerState),
          confidence: _workspaceConfidence(scannerState),
          nextBestRole: workspaceRole,
          isBusy: scannerState.isLoading || scannerState.isPreparingImage,
          errorMessage: scannerState.errorMessage,
          onClose: scannerController.resetScan,
          onSelectPhoto: scannerController.selectCapturedPhoto,
          onCaptureNext: () => scannerController.startCameraScan(
            context,
            imageRole: workspaceRole.id,
          ),
          onAddPhoto: () => scannerController.pickImageFromGallery(
            context: context,
            imageRole: workspaceRole.id,
          ),
          onAnalyze: scannerController.analyzeWithAi,
        );
      }
      return Scaffold(
        backgroundColor: Colors.black,
        body: _SnapchatScanSurface(
          captureImages: scannerState.captureImages,
          activeSlot: activeSlot,
          isBusy: scannerState.isLoading || scannerState.isPreparingImage,
          canAnalyze: scannerState.captureImages.isNotEmpty,
          errorMessage: scannerState.errorMessage,
          onClose: scannerController.resetScan,
          onCapture: () =>
              scannerController.startCameraScan(context, imageRole: nextRole),
          onGallery: () => scannerController.pickImageFromGallery(
            context: context,
            imageRole: nextRole,
          ),
          onAnalyze: scannerController.analyzeWithAi,
          onSelectPhoto: scannerController.selectCapturedPhoto,
          onSample: scannerController.useSampleScan,
          onEnhance: activeSlot == null
              ? null
              : () => scannerController.applyEnhancementToPhoto(
                  activeSlot,
                  ImageEnhancementPreset.autoEnhance,
                ),
        ),
      );
    }

    return _MinimalScanResultScreen(
      result: scanResult,
      activeSlot: _activeScanSlot(
        scannerState.captureImages,
        selectedImagePath,
      ),
      isSaved: scannerState.isSavedToPortfolio,
      isSaving: scannerState.isSavingToPortfolio,
      onSave: () async {
        final didSave = await scannerController.saveScanResultToPortfolio();
        if (!context.mounted || !didSave) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Saved to portfolio')));
      },
      onScanAnother: scannerController.resetScan,
      onViewPortfolio: widget.onViewPortfolio,
    );
  }
}

String _formatScanValue(double value, ValuationStatus status) {
  if (value <= 0) {
    return _valuationStatusMessage(status);
  }

  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '\$$withCommas';
}

ScannerPhotoSlot? _activeScanSlot(
  List<ScannerPhotoSlot> captureImages,
  String? selectedPath,
) {
  if (captureImages.isEmpty) {
    return null;
  }
  if (selectedPath == null || selectedPath.trim().isEmpty) {
    return captureImages.last;
  }
  for (final slot in captureImages.reversed) {
    if (slot.path == selectedPath) {
      return slot;
    }
  }
  return captureImages.last;
}

String _workspaceRoleLabel(String role) {
  return switch (role) {
    'base' => 'Base',
    'left' => 'Left side',
    'right' => 'Right side',
    'top' => 'Top',
    'detail' => 'Detail',
    'front' => 'Front',
    'back' => 'Back',
    _ => role.isEmpty ? 'Photo' : role,
  };
}

ScanCaptureRole _nextWorkspaceRole(
  ScanCapturePlan activePlan,
  ScannerState scannerState,
) {
  final capturedRoles = scannerState.captureImages
      .map((slot) => ScanCaptureRole.fromId(slot.role))
      .toSet();
  final recommended = activePlan.nextRecommendedRole;
  if (recommended != null && !capturedRoles.contains(recommended)) {
    return recommended;
  }
  const fallbackOrder = [
    ScanCaptureRole.back,
    ScanCaptureRole.baseUnderside,
    ScanCaptureRole.closeUp,
    ScanCaptureRole.angledReflective,
  ];
  return fallbackOrder.firstWhere(
    (role) => !capturedRoles.contains(role),
    orElse: () => ScanCaptureRole.closeUp,
  );
}

String _workspaceDetectedCategory(ScannerState state) {
  if (state.hasManualCaptureCategory) {
    return state.captureCategory.title;
  }
  final roles = state.captureImages.map((slot) => slot.role.toLowerCase());
  final sources = state.captureImages.map((slot) => slot.path.toLowerCase());
  if (sources.any((path) => path.contains('card')) ||
      roles.any((role) => role.contains('corner') || role.contains('glare'))) {
    return 'Trading card';
  }
  if (roles.any((role) => role.contains('edge') || role.contains('mint'))) {
    return 'Coin';
  }
  if (roles.any(
    (role) =>
        role.contains('base') ||
        role.contains('barcode') ||
        role.contains('side') ||
        role.contains('top'),
  )) {
    return 'Diecast / Toy car';
  }
  return 'Collectible';
}

double _workspaceConfidence(ScannerState state) {
  final photos = state.captureImages;
  if (photos.isEmpty) {
    return 0;
  }
  final roleCount = photos.map((slot) => slot.role).toSet().length;
  final enhancedCount = photos.where((slot) => slot.isEnhanced).length;
  final confidence =
      0.55 +
      ((photos.length - 1) * 0.1) +
      (roleCount > 1 ? 0.08 : 0) +
      (enhancedCount > 0 ? 0.06 : 0);
  return confidence.clamp(0.55, 0.92).toDouble();
}

class _MinimalScanResultScreen extends StatelessWidget {
  const _MinimalScanResultScreen({
    required this.result,
    required this.activeSlot,
    required this.isSaved,
    required this.isSaving,
    required this.onSave,
    required this.onScanAnother,
    required this.onViewPortfolio,
  });

  final ScanResult result;
  final ScannerPhotoSlot? activeSlot;
  final bool isSaved;
  final bool isSaving;
  final Future<void> Function() onSave;
  final VoidCallback onScanAnother;
  final VoidCallback? onViewPortfolio;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final imagePath = result.thumbnail.isNotEmpty
        ? result.thumbnail
        : activeSlot?.path ?? '';
    final isEnhanced = activeSlot?.isEnhanced == true;
    return Scaffold(
      key: ValueKey('scan-result-${result.id}'),
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Analysis Complete'),
        actions: [
          IconButton(
            key: const ValueKey('result-scan-another'),
            onPressed: onScanAnother,
            icon: const Icon(Icons.close),
            tooltip: 'Scan another',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ResultImage(path: imagePath),
                      if (isEnhanced)
                        const Positioned(
                          left: AppSpacing.sm,
                          top: AppSpacing.sm,
                          child: _AiEnhancedBadge(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                result.title,
                key: const ValueKey('result-item-name'),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _ResultChip(
                    icon: Icons.category_outlined,
                    label: result.category,
                  ),
                  _ResultChip(
                    icon: Icons.verified_outlined,
                    label: '${(result.confidence * 100).round()}% confidence',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Estimated value',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatScanValue(result.estimatedValue, result.valuationStatus),
                key: const ValueKey('result-estimated-value'),
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                key: const ValueKey('result-primary-add-to-portfolio'),
                onPressed: isSaved || isSaving ? null : onSave,
                icon: Icon(
                  isSaving
                      ? Icons.hourglass_top_outlined
                      : isSaved
                      ? Icons.check_circle_outline
                      : Icons.bookmark_add_outlined,
                ),
                label: Text(
                  isSaving
                      ? 'Saving...'
                      : isSaved
                      ? 'Saved to Portfolio'
                      : 'Add to Portfolio',
                ),
              ),
              if (isSaved && onViewPortfolio != null) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: onViewPortfolio,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('View Portfolio'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultImage extends StatelessWidget {
  const _ResultImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('sample://')) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.style_outlined,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 56,
        ),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return const ColoredBox(
      color: Color(0xFFE5E7EB),
      child: Icon(Icons.broken_image_outlined, size: 42),
    );
  }
}

class _AiEnhancedBadge extends StatelessWidget {
  const _AiEnhancedBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('scan-result-analyzed-with-enhancement'),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        child: Text(
          'AI Enhanced',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _SnapchatScanSurface extends StatelessWidget {
  const _SnapchatScanSurface({
    required this.captureImages,
    required this.activeSlot,
    required this.isBusy,
    required this.canAnalyze,
    required this.errorMessage,
    required this.onClose,
    required this.onCapture,
    required this.onGallery,
    required this.onAnalyze,
    required this.onSelectPhoto,
    required this.onSample,
    required this.onEnhance,
  });

  final List<ScannerPhotoSlot> captureImages;
  final ScannerPhotoSlot? activeSlot;
  final bool isBusy;
  final bool canAnalyze;
  final String? errorMessage;
  final VoidCallback onClose;
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final VoidCallback onAnalyze;
  final ValueChanged<ScannerPhotoSlot> onSelectPhoto;
  final VoidCallback onSample;
  final VoidCallback? onEnhance;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Positioned.fill(child: _SnapCameraPreview(slot: activeSlot)),
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Row(
              children: [
                _GlassIconButton(
                  key: const ValueKey('scan-close'),
                  icon: Icons.close,
                  tooltip: 'Close',
                  onPressed: onClose,
                ),
                const Spacer(),
                _GlassIconButton(
                  key: const ValueKey('scan-flash-toggle'),
                  icon: Icons.flash_off,
                  tooltip: 'Flash',
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.sm,
            top: 96,
            bottom: 132,
            child: _VerticalFilmstrip(
              captureImages: captureImages,
              activePath: activeSlot?.path,
              onSelectPhoto: onSelectPhoto,
            ),
          ),
          Positioned(
            right: AppSpacing.md,
            top: 0,
            bottom: 0,
            child: Center(
              child: _GlassIconButton(
                key: const ValueKey('scan-live-enhance'),
                icon: Icons.auto_fix_high,
                tooltip: 'AI Enhance',
                onPressed: onEnhance,
                large: true,
              ),
            ),
          ),
          if (errorMessage != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: 124,
              child: _ScanErrorToast(message: errorMessage!),
            ),
          if (isBusy)
            const Positioned.fill(
              key: ValueKey('scan-busy-overlay'),
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xl,
            child: _SnapCaptureBar(
              canAnalyze: canAnalyze,
              onGallery: onGallery,
              onCapture: onCapture,
              onAnalyze: onAnalyze,
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: SizedBox.square(
              dimension: 1,
              child: IconButton(
                key: const ValueKey('scan-secondary-Use Sample Scan'),
                padding: EdgeInsets.zero,
                onPressed: onSample,
                icon: const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapCameraPreview extends StatelessWidget {
  const _SnapCameraPreview({required this.slot});

  final ScannerPhotoSlot? slot;

  @override
  Widget build(BuildContext context) {
    final path = slot?.path.trim();
    final file = path == null || path.isEmpty ? null : File(path);
    if (file != null && file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111111), Color(0xFF050505)],
        ),
      ),
      child: Center(
        child: Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(
            Icons.photo_camera_outlined,
            color: Colors.white54,
            size: 42,
          ),
        ),
      ),
    );
  }
}

class _VerticalFilmstrip extends StatelessWidget {
  const _VerticalFilmstrip({
    required this.captureImages,
    required this.activePath,
    required this.onSelectPhoto,
  });

  final List<ScannerPhotoSlot> captureImages;
  final String? activePath;
  final ValueChanged<ScannerPhotoSlot> onSelectPhoto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('scan-left-filmstrip'),
      width: 66,
      child: ListView.separated(
        itemCount: captureImages.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final slot = captureImages[index];
          return _FilmstripThumb(
            slot: slot,
            selected: slot.path == activePath,
            onTap: () => onSelectPhoto(slot),
          );
        },
      ),
    );
  }
}

class _FilmstripThumb extends StatelessWidget {
  const _FilmstripThumb({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final ScannerPhotoSlot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final file = File(slot.path);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 62,
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: file.existsSync()
            ? Image.file(file, fit: BoxFit.cover)
            : const Icon(Icons.image_outlined, color: Colors.white54),
      ),
    );
  }
}

class _SnapCaptureBar extends StatelessWidget {
  const _SnapCaptureBar({
    required this.canAnalyze,
    required this.onGallery,
    required this.onCapture,
    required this.onAnalyze,
  });

  final bool canAnalyze;
  final VoidCallback onGallery;
  final VoidCallback onCapture;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GlassIconButton(
          key: const ValueKey('scan-secondary-Gallery'),
          icon: Icons.photo_library_outlined,
          tooltip: 'Gallery',
          onPressed: onGallery,
        ),
        Expanded(
          child: Center(
            child: GestureDetector(
              key: const ValueKey('scan-primary-Scan with Camera'),
              onTap: onCapture,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (canAnalyze)
          Tooltip(
            message: 'Analyze Image',
            child: FilledButton(
              key: const ValueKey('scan-primary-Analyze Image'),
              onPressed: onAnalyze,
              style: FilledButton.styleFrom(
                fixedSize: const Size.square(48),
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
                backgroundColor: Colors.black.withValues(alpha: 0.42),
                foregroundColor: Colors.white,
              ),
              child: const Icon(Icons.auto_awesome),
            ),
          )
        else
          _GlassIconButton(
            key: const ValueKey('scan-flip-camera'),
            icon: Icons.cameraswitch_outlined,
            tooltip: 'Flip Camera',
            onPressed: () {},
          ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.large = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 58.0 : 48.0;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        style: IconButton.styleFrom(
          fixedSize: Size.square(size),
          backgroundColor: Colors.black.withValues(alpha: 0.42),
          disabledBackgroundColor: Colors.black.withValues(alpha: 0.22),
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

class _ScanErrorToast extends StatelessWidget {
  const _ScanErrorToast({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _valuationStatusMessage(ValuationStatus status) {
  return switch (status) {
    ValuationStatus.providerNotConfigured =>
      'Market value unavailable — pricing source not connected yet',
    ValuationStatus.noMarketMatch => 'No reliable market match found yet',
    ValuationStatus.lookupFailed => 'Value lookup failed — try again',
    ValuationStatus.aiEstimated => 'AI-estimated value unavailable',
    ValuationStatus.marketEstimated => 'Value unavailable',
    ValuationStatus.unavailable => 'Value unavailable',
  };
}
