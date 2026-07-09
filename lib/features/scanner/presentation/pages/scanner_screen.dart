import 'dart:io';
import 'dart:async';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/image_enhancement_preset.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_plan.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_capture_plan_service.dart';
import 'package:collectiq_ai/features/scanner/presentation/scan_flow_debug.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/scan_result_screen.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/scan_workspace_screen.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/camera_overlay.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/capture_suggestions.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/enhance_button.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/exposure_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({this.onViewPortfolio, super.key});

  final VoidCallback? onViewPortfolio;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  late final ProviderSubscription<ScannerState> _scannerSubscription;
  bool _showCaptureLoopScan = false;
  String? _captureLoopRoleId;

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
        final previousCount = previous?.captureImages.length ?? 0;
        final nextCount = next.captureImages.length;
        if (_showCaptureLoopScan && nextCount > previousCount) {
          setState(() {
            _showCaptureLoopScan = false;
            _captureLoopRoleId = null;
          });
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
      if (_showCaptureLoopScan && workspacePhotos.isNotEmpty) {
        final captureRole = _captureLoopRoleId ?? workspaceRole.id;
        return Scaffold(
          backgroundColor: Colors.black,
          body: _SnapchatScanSurface(
            captureImages: workspacePhotos,
            activeSlot: activeSlot,
            isBusy: scannerState.isLoading || scannerState.isPreparingImage,
            canAnalyze: workspacePhotos.isNotEmpty,
            errorMessage: scannerState.errorMessage,
            recommendedRole: ScanCaptureRole.fromId(captureRole),
            onClose: () => setState(() {
              _showCaptureLoopScan = false;
              _captureLoopRoleId = null;
            }),
            onCapture: () => scannerController.startCameraScan(
              context,
              imageRole: captureRole,
            ),
            onGallery: () => scannerController.pickImageFromGallery(
              context: context,
              imageRole: captureRole,
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
          onCaptureNext: () => setState(() {
            _showCaptureLoopScan = true;
            _captureLoopRoleId = workspaceRole.id;
          }),
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
          recommendedRole: ScanCaptureRole.fromId(nextRole),
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

    return ScanResultScreen(
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

String _shortScanRole(String role) {
  final captureRole = ScanCaptureRole.fromId(role);
  return switch (captureRole) {
    ScanCaptureRole.front => 'Front',
    ScanCaptureRole.back => 'Back',
    ScanCaptureRole.baseUnderside => 'Base',
    ScanCaptureRole.closeUp => 'Close-up',
    ScanCaptureRole.barcode => 'Barcode',
    ScanCaptureRole.angledReflective => 'Angle',
    _ => captureRole.title.split('/').first.trim(),
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

class _SnapchatScanSurface extends StatefulWidget {
  const _SnapchatScanSurface({
    required this.captureImages,
    required this.activeSlot,
    required this.isBusy,
    required this.canAnalyze,
    required this.errorMessage,
    required this.recommendedRole,
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
  final ScanCaptureRole recommendedRole;
  final VoidCallback onClose;
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final VoidCallback onAnalyze;
  final ValueChanged<ScannerPhotoSlot> onSelectPhoto;
  final VoidCallback onSample;
  final VoidCallback? onEnhance;

  @override
  State<_SnapchatScanSurface> createState() => _SnapchatScanSurfaceState();
}

class _SnapchatScanSurfaceState extends State<_SnapchatScanSurface> {
  Offset? _focusPoint;
  Timer? _focusTimer;
  Timer? _exposureTimer;
  Timer? _flashTimer;
  Timer? _suggestionTimer;
  bool _showExposureSlider = false;
  bool _showFlash = false;
  bool _showGrid = false;
  bool _showSuggestion = false;
  double _exposure = 0.5;

  @override
  void didUpdateWidget(covariant _SnapchatScanSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.captureImages.length > oldWidget.captureImages.length) {
      _showCaptureSuggestion();
    }
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _exposureTimer?.cancel();
    _flashTimer?.cancel();
    _suggestionTimer?.cancel();
    super.dispose();
  }

  void _handlePreviewTap(TapUpDetails details) {
    HapticFeedback.selectionClick();
    setState(() {
      _focusPoint = details.localPosition;
      _showExposureSlider = true;
    });
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _focusPoint = null);
      }
    });
    _scheduleExposureHide();
  }

  void _scheduleExposureHide() {
    _exposureTimer?.cancel();
    _exposureTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showExposureSlider = false);
      }
    });
  }

  void _setExposure(double value) {
    setState(() {
      _exposure = value;
      _showExposureSlider = true;
    });
    _scheduleExposureHide();
  }

  void _capture() {
    HapticFeedback.lightImpact();
    setState(() => _showFlash = true);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() => _showFlash = false);
      }
    });
    _showCaptureSuggestion();
    widget.onCapture();
  }

  void _showCaptureSuggestion() {
    _suggestionTimer?.cancel();
    setState(() => _showSuggestion = true);
    _suggestionTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showSuggestion = false);
      }
    });
  }

  String get _detectLabel {
    if (widget.captureImages.length > 1) {
      return 'Match found';
    }
    if (widget.captureImages.isNotEmpty) {
      return 'Hot Wheels detected';
    }
    return 'Detecting...';
  }

  String get _suggestionLabel =>
      '${_shortScanRole(widget.recommendedRole.id)} recommended';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const ValueKey('scan-camera-preview-tap-target'),
              behavior: HitTestBehavior.opaque,
              onTapUp: _handlePreviewTap,
              child: _SnapCameraPreview(slot: widget.activeSlot),
            ),
          ),
          Positioned.fill(child: CameraGridOverlay(visible: _showGrid)),
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
                  onPressed: widget.onClose,
                ),
                const Spacer(),
                _GlassIconButton(
                  key: const ValueKey('scan-grid-toggle'),
                  icon: _showGrid ? Icons.grid_on : Icons.grid_off,
                  tooltip: 'Grid',
                  onPressed: () => setState(() => _showGrid = !_showGrid),
                ),
                const SizedBox(width: AppSpacing.sm),
                AutoDetectOverlay(label: _detectLabel),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.sm,
            top: 96,
            bottom: 132,
            child: _VerticalFilmstrip(
              captureImages: widget.captureImages,
              activePath: widget.activeSlot?.path,
              onSelectPhoto: widget.onSelectPhoto,
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: 70,
            child: Center(
              child: _RecommendedRolePill(role: widget.recommendedRole),
            ),
          ),
          if (_focusPoint != null) CameraFocusRing(position: _focusPoint!),
          Positioned(
            right: AppSpacing.md,
            top: 96,
            child: ScanExposureSlider(
              visible: _showExposureSlider,
              value: _exposure,
              onChanged: _setExposure,
            ),
          ),
          Positioned(
            right: AppSpacing.md,
            top: 0,
            bottom: 0,
            child: Center(
              child: EnhanceButton(
                active: widget.activeSlot?.isEnhanced == true,
                onPressed: widget.onEnhance,
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: 116,
            child: Center(
              child: CaptureSuggestionBubble(
                label: _suggestionLabel,
                visible: _showSuggestion,
              ),
            ),
          ),
          if (widget.errorMessage != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: 124,
              child: _ScanErrorToast(message: widget.errorMessage!),
            ),
          if (widget.isBusy)
            const Positioned.fill(
              key: ValueKey('scan-busy-overlay'),
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          Positioned.fill(child: CaptureFlashOverlay(visible: _showFlash)),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xl,
            child: _SnapCaptureBar(
              canAnalyze: widget.canAnalyze,
              onGallery: widget.onGallery,
              onCapture: _capture,
              onAnalyze: widget.onAnalyze,
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
                onPressed: widget.onSample,
                icon: const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedRolePill extends StatelessWidget {
  const _RecommendedRolePill({required this.role});

  final ScanCaptureRole role;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('scan-recommended-role'),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          'Recommended: ${role.title}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
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
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(48),
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
