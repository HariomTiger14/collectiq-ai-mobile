import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:collectiq_ai/core/cloud/cloud_portfolio_sync_coordinator.dart';
import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/config/feature_flags.dart';
import 'package:collectiq_ai/core/errors/scanner_exception.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/network/api_constants.dart';
import 'package:collectiq_ai/core/network/network_exceptions.dart';
import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_models.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_service.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/features/ai/services/ai_providers.dart';
import 'package:collectiq_ai/features/diagnostics/services/diagnostics_providers.dart';
import 'package:collectiq_ai/features/image_sync/presentation/controllers/image_sync_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/captured_scan_image.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/capture_event.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/confidence_model.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/image_enhancement_preset.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_plan.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_session.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scanner_constants.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_capture_plan_service.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_result_enrichment_service.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_quality_gate_service.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/image_enhancement_preview_page.dart';
import 'package:collectiq_ai/features/scanner/presentation/scan_flow_debug.dart';
import 'package:collectiq_ai/features/scanner/services/camera_service.dart';
import 'package:collectiq_ai/features/scanner/services/gallery_service.dart';
import 'package:collectiq_ai/features/scanner/services/image_enhancement_service.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_exception.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScannerPhotoSlot {
  const ScannerPhotoSlot({
    required this.role,
    required this.label,
    required this.path,
    required this.source,
    this.image,
    this.originalPath,
    this.enhancementPreset = ImageEnhancementPreset.original,
    this.enhancedImagePath,
    this.qualityMetadata = const {},
    this.capturedAt,
  });

  final String role;
  final String label;
  final String path;
  final String source;
  final XFile? image;
  final String? originalPath;
  final ImageEnhancementPreset enhancementPreset;
  final String? enhancedImagePath;
  final Map<String, Object?> qualityMetadata;
  final DateTime? capturedAt;

  bool get isEnhanced => enhancementPreset.isEnhanced;

  String get analyzerPath => path;

  ScannerPhotoSlot copyWith({
    String? path,
    XFile? image,
    String? originalPath,
    ImageEnhancementPreset? enhancementPreset,
    String? enhancedImagePath,
    Map<String, Object?>? qualityMetadata,
  }) {
    return ScannerPhotoSlot(
      role: role,
      label: label,
      path: path ?? this.path,
      source: source,
      image: image ?? this.image,
      originalPath: originalPath ?? this.originalPath,
      enhancementPreset: enhancementPreset ?? this.enhancementPreset,
      enhancedImagePath: enhancedImagePath ?? this.enhancedImagePath,
      qualityMetadata: qualityMetadata ?? this.qualityMetadata,
      capturedAt: capturedAt,
    );
  }
}

/// Immutable presentation state for the scanner workflow.
class ScannerState {
  /// Creates scanner state.
  const ScannerState({
    this.isCameraInitialized = false,
    this.isLoading = false,
    this.isPreparingImage = false,
    this.selectedImage,
    this.selectedImagePath,
    this.selectedItemTitle,
    this.selectedItemStatus,
    this.photoSlots = const {},
    this.captureImages = const [],
    this.captureCategory = CollectibleCategory.toyCar,
    this.hasManualCaptureCategory = false,
    this.activeCaptureRole,
    this.primaryImagePath,
    this.scanSession,
    this.scanResult,
    this.aiRecommendation,
    this.isSavedToPortfolio = false,
    this.isSavingToPortfolio = false,
    this.errorMessage,
  });

  /// Whether the camera has been initialized for use.
  final bool isCameraInitialized;

  /// Whether the scanner workflow is currently loading.
  final bool isLoading;

  /// Whether a returned picker image is being copied into app storage.
  final bool isPreparingImage;

  /// Image selected from camera or gallery.
  final XFile? selectedImage;

  /// Local file path for the selected scanner image.
  final String? selectedImagePath;

  /// Display title for the currently selected scan preview item.
  final String? selectedItemTitle;

  /// Display status for the currently selected scan preview item.
  final String? selectedItemStatus;

  final Map<String, ScannerPhotoSlot> photoSlots;

  final List<ScannerPhotoSlot> captureImages;

  final CollectibleCategory captureCategory;
  final bool hasManualCaptureCategory;

  final String? activeCaptureRole;

  final String? primaryImagePath;

  final ScanSession? scanSession;

  /// Latest scan result, once AI scanning is implemented.
  final ScanResult? scanResult;

  /// Recommendation generated by the temporary AI result flow.
  final String? aiRecommendation;

  /// Whether the current result has already been saved.
  final bool isSavedToPortfolio;

  /// Whether the current result is being saved.
  final bool isSavingToPortfolio;

  /// Latest user-safe scanner error message.
  final String? errorMessage;

  /// Creates a copy of the current scanner state.
  ScannerState copyWith({
    bool? isCameraInitialized,
    bool? isLoading,
    bool? isPreparingImage,
    XFile? selectedImage,
    String? selectedImagePath,
    String? selectedItemTitle,
    String? selectedItemStatus,
    Map<String, ScannerPhotoSlot>? photoSlots,
    List<ScannerPhotoSlot>? captureImages,
    CollectibleCategory? captureCategory,
    bool? hasManualCaptureCategory,
    String? activeCaptureRole,
    String? primaryImagePath,
    ScanSession? scanSession,
    ScanResult? scanResult,
    String? aiRecommendation,
    bool? isSavedToPortfolio,
    bool? isSavingToPortfolio,
    String? errorMessage,
    bool clearSelectedImage = false,
    bool clearSelectedImagePath = false,
    bool clearSelectedItemTitle = false,
    bool clearSelectedItemStatus = false,
    bool clearPhotoSlots = false,
    bool clearCaptureImages = false,
    bool clearActiveCaptureRole = false,
    bool clearPrimaryImagePath = false,
    bool clearScanSession = false,
    bool clearScanResult = false,
    bool clearAiRecommendation = false,
    bool clearErrorMessage = false,
  }) {
    return ScannerState(
      isCameraInitialized: isCameraInitialized ?? this.isCameraInitialized,
      isLoading: isLoading ?? this.isLoading,
      isPreparingImage: isPreparingImage ?? this.isPreparingImage,
      selectedImage: clearSelectedImage
          ? null
          : selectedImage ?? this.selectedImage,
      selectedImagePath: clearSelectedImagePath
          ? null
          : selectedImagePath ?? this.selectedImagePath,
      selectedItemTitle: clearSelectedItemTitle
          ? null
          : selectedItemTitle ?? this.selectedItemTitle,
      selectedItemStatus: clearSelectedItemStatus
          ? null
          : selectedItemStatus ?? this.selectedItemStatus,
      photoSlots: clearPhotoSlots ? const {} : photoSlots ?? this.photoSlots,
      captureImages: clearCaptureImages
          ? const []
          : captureImages ?? this.captureImages,
      captureCategory: captureCategory ?? this.captureCategory,
      hasManualCaptureCategory:
          hasManualCaptureCategory ?? this.hasManualCaptureCategory,
      activeCaptureRole: clearActiveCaptureRole
          ? null
          : activeCaptureRole ?? this.activeCaptureRole,
      primaryImagePath: clearPrimaryImagePath
          ? null
          : primaryImagePath ?? this.primaryImagePath,
      scanSession: clearScanSession ? null : scanSession ?? this.scanSession,
      scanResult: clearScanResult ? null : scanResult ?? this.scanResult,
      aiRecommendation: clearAiRecommendation
          ? null
          : aiRecommendation ?? this.aiRecommendation,
      isSavedToPortfolio: isSavedToPortfolio ?? this.isSavedToPortfolio,
      isSavingToPortfolio: isSavingToPortfolio ?? this.isSavingToPortfolio,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

/// Controller that coordinates scanner presentation state and workflow events.
class ScannerController extends Notifier<ScannerState> {
  /// Camera service dependency.
  late final CameraService _cameraService;

  /// Gallery service dependency.
  late final GalleryService _galleryService;

  /// Analyzer service dependency.
  late final AnalyzerService _analyzerService;

  /// Scan enrichment service dependency.
  late final ScanResultEnrichmentService _enrichmentService;

  late final ImageEnhancementService _imageEnhancementService;
  late final ScanCapturePlanService _capturePlanService;
  late final ScanQualityGateService _qualityGateService;
  late final AppTelemetryService _telemetry;
  bool _isDisposed = false;
  bool _isPickerActive = false;
  bool _isRecoveringLostData = false;

  bool get isPickerActiveForDebug => _isPickerActive;

  bool get isRecoveringLostDataForDebug => _isRecoveringLostData;

  @override
  ScannerState build() {
    _isDisposed = false;
    _cameraService = ref.watch(cameraServiceProvider);
    _galleryService = ref.watch(galleryServiceProvider);
    _analyzerService = ref.watch(analyzerServiceProvider);
    _enrichmentService = ref.watch(scanResultEnrichmentServiceProvider);
    _imageEnhancementService = ref.watch(imageEnhancementServiceProvider);
    _capturePlanService = ref.watch(scanCapturePlanServiceProvider);
    _qualityGateService = ref.watch(scanQualityGateServiceProvider);
    _telemetry = ref.watch(appTelemetryServiceProvider);
    ref.onDispose(() {
      _isDisposed = true;
    });
    logCollectIqScanFlow('scanner controller build');
    return const ScannerState();
  }

  void _setState(ScannerState nextState, {String event = 'state emitted'}) {
    if (_isDisposed) {
      return;
    }

    state = nextState;
    _logFlow(event);
  }

  void _keepScanSelected(String reason) {
    if (_isDisposed) {
      return;
    }

    ref
        .read(appShellTabControllerProvider.notifier)
        .keepScanSelected(reason: reason);
    _logFlow('scan tab preserved', details: {'reason': reason});
  }

  void _logFlow(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> details = const {},
  }) {
    logCollectIqScanFlow(
      event,
      selectedImagePath: state.selectedImagePath,
      isLoading: state.isLoading,
      isPreparingImage: state.isPreparingImage,
      isPickerActive: _isPickerActive,
      isRecoveringLostData: _isRecoveringLostData,
      currentTabIndex: ref.read(appShellTabControllerProvider),
      error: error,
      stackTrace: stackTrace,
      details: details,
    );
  }

  /// Initializes camera state for the scanner screen.
  Future<void> initializeCamera() async {
    state = state.copyWith(
      isLoading: true,
      clearScanResult: true,
      clearAiRecommendation: true,
      clearErrorMessage: true,
    );
    await _cameraService.initializeCamera();
    state = state.copyWith(isCameraInitialized: true, isLoading: false);
  }

  /// Requests camera permissions for future capture flows.
  Future<bool> requestCameraPermissions() {
    return _cameraService.requestPermissions();
  }

  void selectGoal(ScanGoal goal) {
    final session = _ensureSession(scanGoal: goal).addEvent(
      CaptureEvent(
        type: CaptureEventType.goalSelected,
        timestamp: DateTime.now(),
        metadata: {'scanGoal': goal.id},
      ),
    );
    final capturedImages = _capturedImagesFromSlots(state.photoSlots);
    final plan = _capturePlanService.buildPlan(
      goal,
      state.captureCategory,
      capturedImages,
    );
    _setState(
      state.copyWith(
        scanSession: session.copyWith(
          scanGoal: goal,
          capturePlan: plan,
          capturedImages: capturedImages,
          confidenceTarget: goal.confidenceTarget,
          clearConfidenceAchieved: true,
        ),
        clearScanResult: true,
        clearAiRecommendation: true,
        isSavedToPortfolio: false,
      ),
      event: 'scan goal selected',
    );
  }

  void selectCaptureCategory(CollectibleCategory category) {
    final capturedImages = _capturedImagesFromCaptureImages();
    final goal = state.scanSession?.scanGoal ?? ScanGoal.identifyValue;
    final plan = _capturePlanService.buildPlan(goal, category, capturedImages);
    final session = _ensureSession().copyWith(
      capturePlan: plan,
      capturedImages: capturedImages,
      category: category.id,
      clearConfidenceAchieved: true,
      clearEndTime: true,
    );
    _setState(
      state.copyWith(
        captureCategory: category,
        hasManualCaptureCategory: true,
        scanSession: session,
        clearScanResult: true,
        clearAiRecommendation: true,
        isSavedToPortfolio: false,
      ),
      event: 'capture category selected',
    );
  }

  void selectCaptureRole(String imageRole) {
    final normalizedRole = _normalizeImageRole(imageRole);
    final slot = _latestSlotForRole(normalizedRole);
    _setState(
      state.copyWith(
        activeCaptureRole: normalizedRole,
        selectedImage: slot?.image,
        selectedImagePath: slot?.path,
        selectedItemTitle: slot == null
            ? _slotLabel(normalizedRole)
            : slot.label,
        selectedItemStatus: slot == null
            ? 'Ready to capture'
            : 'Ready for AI analysis',
        clearSelectedImage: slot == null,
        clearSelectedImagePath: slot == null,
      ),
      event: 'capture role selected',
    );
  }

  void selectCapturedImage(String imageRole) {
    final slot = state.photoSlots[_normalizeImageRole(imageRole)];
    if (slot == null) {
      return;
    }
    _setState(
      state.copyWith(
        selectedImage: slot.image,
        selectedImagePath: slot.path,
        selectedItemTitle: '${slot.label} photo',
        selectedItemStatus: 'Ready for AI analysis',
      ),
      event: 'active capture selected',
    );
  }

  void selectCapturedPhoto(ScannerPhotoSlot slot) {
    _setState(
      state.copyWith(
        activeCaptureRole: slot.role,
        selectedImage: slot.image,
        selectedImagePath: slot.path,
        selectedItemTitle: slot.label,
        selectedItemStatus: 'Ready for AI analysis',
      ),
      event: 'active captured photo selected',
    );
  }

  void useCapturedPhotoAsPrimary(ScannerPhotoSlot slot) {
    _setState(
      state.copyWith(
        primaryImagePath: slot.path,
        activeCaptureRole: slot.role,
        selectedImage: slot.image,
        selectedImagePath: slot.path,
        selectedItemTitle: slot.label,
        selectedItemStatus: 'Primary portfolio image',
      ),
      event: 'capture primary photo selected',
    );
  }

  Future<void> applyEnhancementToPhoto(
    ScannerPhotoSlot slot,
    ImageEnhancementPreset preset,
  ) async {
    final originalPath = (slot.originalPath ?? slot.path).trim();
    if (originalPath.isEmpty) {
      return;
    }

    final result = await _imageEnhancementService.enhance(
      originalPath: originalPath,
      preset: preset,
    );
    final enhancedSlot = ScannerPhotoSlot(
      role: slot.role,
      label: slot.label,
      path: result.activePath,
      source: slot.source,
      image: _imageFileForEnhancementResult(slot, result),
      originalPath: result.originalPath,
      enhancedImagePath: result.preset.isEnhanced ? result.activePath : null,
      enhancementPreset: result.preset,
      qualityMetadata: {...slot.qualityMetadata, ...result.toMetadataJson()},
      capturedAt: slot.capturedAt,
    );
    final nextImages = [
      for (final existing in state.captureImages)
        existing.path == slot.path ? enhancedSlot : existing,
    ];
    final nextPrimaryPath = state.primaryImagePath == slot.path
        ? enhancedSlot.path
        : state.primaryImagePath;
    final nextSession = _ensureSession().copyWith(
      capturedImages: [
        for (final image in nextImages) _capturedImageFromSlot(image),
      ],
      clearConfidenceAchieved: true,
      clearEndTime: true,
    );

    _setState(
      state.copyWith(
        selectedImage: enhancedSlot.image,
        selectedImagePath: enhancedSlot.path,
        selectedItemTitle: enhancedSlot.label,
        selectedItemStatus: enhancedSlot.isEnhanced
            ? '${enhancedSlot.enhancementPreset.label} applied'
            : 'Ready for AI analysis',
        photoSlots: _latestSlotsFromImages(nextImages),
        captureImages: nextImages,
        activeCaptureRole: enhancedSlot.role,
        primaryImagePath: nextPrimaryPath,
        scanSession: nextSession,
        clearScanResult: true,
        clearAiRecommendation: true,
        isSavedToPortfolio: false,
      ),
      event: 'image enhancement applied',
    );
  }

  /// Opens the selected camera.
  Future<void> openCamera() {
    return _cameraService.openCamera();
  }

  /// Captures an image and stores it as the selected scanner image.
  Future<void> captureImage() async {
    _setState(state.copyWith(isLoading: true, clearErrorMessage: true));
    try {
      final image = await _cameraService.captureImage();
      if (image.path.trim().isEmpty) {
        throw const ScannerException(
          message: 'Captured image path is missing.',
          code: 'scanner.camera.empty_path',
        );
      }
      _setState(
        state.copyWith(
          selectedImage: image,
          selectedImagePath: image.path,
          selectedItemTitle: 'Captured image',
          selectedItemStatus: 'Ready for AI analysis',
          clearScanResult: true,
          clearAiRecommendation: true,
          isSavedToPortfolio: false,
        ),
      );
    } on ScannerException catch (error) {
      debugPrint('[Scanner] camera capture scanner error: ${error.code}');
      _setState(
        state.copyWith(
          errorMessage: error.message,
          clearSelectedImage: true,
          clearSelectedImagePath: true,
          clearSelectedItemTitle: true,
          clearSelectedItemStatus: true,
          clearScanResult: true,
          clearAiRecommendation: true,
          isSavedToPortfolio: false,
        ),
      );
    } on Object catch (error) {
      debugPrint('[Scanner] camera capture failed: $error');
      _setState(state.copyWith(errorMessage: 'Unable to capture image.'));
    } finally {
      _setState(state.copyWith(isLoading: false));
    }
  }

  /// Opens the camera capture page and stores the captured image path.
  Future<void> startCameraScan(
    BuildContext context, {
    String imageRole = 'front',
  }) async {
    _logFlow('camera button tapped');
    _setState(
      state.copyWith(
        scanSession: _sessionWithEventForRole(
          CaptureEventType.roleRequested,
          imageRole,
        ),
      ),
      event: 'capture role requested',
    );
    _trackTelemetry(
      TelemetryEventNames.scanStarted,
      properties: const {'source': 'camera'},
    );
    if (_isPickerActive) {
      debugPrint('[Scanner] camera picker request ignored; picker active');
      _logFlow('camera picker ignored active');
      return;
    }

    debugPrint(
      '[Scanner] camera picker opening from tab '
      '${ref.read(appShellTabControllerProvider)}',
    );
    _keepScanSelected('camera-picker-open');
    _isPickerActive = true;
    _logFlow('picker active true', details: {'source': 'camera'});
    _setState(
      state.copyWith(isLoading: true, clearErrorMessage: true),
      event: 'camera loading shell emitted',
    );
    try {
      final captureResult = await _cameraService.captureWithInAppCamera(
        context,
        imageRole: imageRole,
      );
      if (_isDisposed) {
        return;
      }
      if (captureResult?.openGallery ?? false) {
        _isPickerActive = false;
        _setState(
          state.copyWith(isPreparingImage: false, isLoading: false),
          event: 'camera gallery fallback requested',
        );
        await pickImageFromGallery(imageRole: imageRole);
        return;
      }
      final capturedImage = captureResult?.image;
      final originalCaptureImage =
          captureResult?.originalImage ?? capturedImage;
      debugPrint(
        '[Scanner] camera picker returned on tab '
        '${ref.read(appShellTabControllerProvider)}',
      );
      _logFlow(
        'picker returned',
        details: {'source': 'camera', 'path': capturedImage?.path},
      );
      _keepScanSelected('camera-picker-return');
      if (capturedImage == null ||
          capturedImage.path.isEmpty ||
          originalCaptureImage == null ||
          originalCaptureImage.path.isEmpty) {
        _setState(
          state.copyWith(isPreparingImage: false, clearErrorMessage: true),
          event: 'camera capture cancelled',
        );
        return;
      }

      debugPrint('[Scanner] camera image copy started');
      final copyStopwatch = Stopwatch()..start();
      _setState(
        state.copyWith(
          isPreparingImage: true,
          isLoading: false,
          selectedItemTitle: 'Preparing image',
          selectedItemStatus: 'Preparing your PackLox scan',
          clearErrorMessage: true,
        ),
        event: 'image copy started',
      );
      final originalImage = await _cameraService.persistCapturedImage(
        originalCaptureImage,
      );
      final image = capturedImage.path == originalCaptureImage.path
          ? originalImage
          : await _cameraService.persistCapturedImage(capturedImage);
      copyStopwatch.stop();
      debugPrint('[Scanner] camera image copy completed: ${image.path}');
      _logFlow(
        'image copy completed',
        details: {
          'source': 'camera',
          'path': image.path,
          'elapsedMs': copyStopwatch.elapsedMilliseconds,
        },
      );
      await _acceptPreparedImage(
        imageRole: imageRole,
        source: 'camera',
        activeImage: image,
        originalImage: originalImage,
        enhancementPreset:
            captureResult?.enhancementPreset ?? ImageEnhancementPreset.original,
        enhancementMetadata: captureResult?.enhancementMetadata ?? const {},
      );
      _trackTelemetry(
        TelemetryEventNames.imageSelected,
        properties: const {'source': 'camera'},
      );
    } on ScannerException catch (error) {
      debugPrint('[Scanner] camera picker scanner error: ${error.code}');
      _logFlow('camera picker scanner error', error: error);
      _recordTelemetryError(
        error,
        reason: 'scan_error',
        properties: {'source': 'camera', 'code': error.code},
      );
      _setState(
        state.copyWith(
          errorMessage: error.message,
          isPreparingImage: false,
          clearSelectedImage: true,
          clearSelectedImagePath: true,
          clearSelectedItemTitle: true,
          clearSelectedItemStatus: true,
          clearScanResult: true,
          clearAiRecommendation: true,
          isSavedToPortfolio: false,
        ),
        event: 'preparing image state false',
      );
    } on Object catch (error, stackTrace) {
      debugPrint('[Scanner] camera picker failed: $error');
      debugPrint('$stackTrace');
      _logFlow('camera picker failed', error: error, stackTrace: stackTrace);
      _recordTelemetryError(
        error,
        stackTrace: stackTrace,
        reason: 'scan_error',
        properties: const {'source': 'camera'},
      );
      _setState(
        state.copyWith(
          isPreparingImage: false,
          errorMessage: 'Unable to open the camera.',
        ),
        event: 'preparing image state false',
      );
    } finally {
      _isPickerActive = false;
      _logFlow('picker active false', details: {'source': 'camera'});
      _setState(
        state.copyWith(isLoading: false),
        event: 'camera loading shell cleared',
      );
    }
  }

  /// Creates a sample selected scan for development and UI testing.
  void useSampleScan() {
    final quality = const ScanQualityEvaluation(
      passed: true,
      severity: QualityGateSeverity.pass,
      issues: [],
      userMessage: 'Image accepted.',
      technicalMetrics: {'source': 'sample'},
    );
    final sampleSlot = const ScannerPhotoSlot(
      role: 'front',
      label: 'Front / Obverse',
      path: 'sample://sports-card',
      source: 'sample',
      qualityMetadata: {'source': 'sample'},
    );
    state = state.copyWith(
      isLoading: false,
      isPreparingImage: false,
      selectedImagePath: 'sample://sports-card',
      selectedItemTitle: 'Sample Sports Card',
      selectedItemStatus: 'Ready for AI analysis',
      photoSlots: {'front': sampleSlot},
      captureImages: [sampleSlot],
      activeCaptureRole: ScanCaptureRole.front.id,
      scanSession: _updatedSessionWithImage(
        imageRole: 'front',
        path: 'sample://sports-card',
        source: 'sample',
        quality: quality,
      ),
      clearSelectedImage: true,
      clearScanResult: true,
      clearAiRecommendation: true,
      clearErrorMessage: true,
      isSavedToPortfolio: false,
    );
  }

  /// Opens the gallery and stores a validated selected image.
  Future<void> pickImageFromGallery({
    BuildContext? context,
    String imageRole = 'front',
  }) async {
    _logFlow('gallery button tapped');
    _setState(
      state.copyWith(
        scanSession: _sessionWithEventForRole(
          CaptureEventType.roleRequested,
          imageRole,
        ),
      ),
      event: 'capture role requested',
    );
    _trackTelemetry(
      TelemetryEventNames.scanStarted,
      properties: const {'source': 'gallery'},
    );
    if (_isPickerActive) {
      debugPrint('[Scanner] gallery picker request ignored; picker active');
      _logFlow('gallery picker ignored active');
      return;
    }

    debugPrint(
      '[Scanner] gallery picker opening from tab '
      '${ref.read(appShellTabControllerProvider)}',
    );
    _keepScanSelected('gallery-picker-open');
    _isPickerActive = true;
    _logFlow('picker active true', details: {'source': 'gallery'});
    _setState(
      state.copyWith(isLoading: true, clearErrorMessage: true),
      event: 'gallery loading shell emitted',
    );
    try {
      final image = await _galleryService.pickImage();
      if (_isDisposed) {
        return;
      }
      debugPrint(
        '[Scanner] gallery picker returned on tab '
        '${ref.read(appShellTabControllerProvider)}',
      );
      _logFlow(
        'picker returned',
        details: {'source': 'gallery', 'path': image?.path},
      );
      _keepScanSelected('gallery-picker-return');
      if (image == null) {
        _setState(
          state.copyWith(isPreparingImage: false, clearErrorMessage: true),
          event: 'gallery selection cancelled',
        );
        return;
      }

      await _galleryService.validateImage(image);
      if (context != null && !context.mounted) {
        return;
      }
      final previewResult = context == null
          ? null
          : await ImageEnhancementPreviewPage.show(
              context,
              image: image,
              title: 'Review import',
              subtitle: 'Choose the clearest version for analysis.',
            );
      if (_isDisposed) {
        return;
      }
      if (context != null && previewResult == null) {
        _setState(
          state.copyWith(isPreparingImage: false, clearErrorMessage: true),
          event: 'gallery enhancement cancelled',
        );
        return;
      }
      final originalGalleryImage = previewResult?.originalImage ?? image;
      final activeGalleryImage = previewResult?.activeImage ?? image;
      final selectedPreset =
          previewResult?.preset ?? ImageEnhancementPreset.original;
      debugPrint('[Scanner] gallery image copy started');
      final copyStopwatch = Stopwatch()..start();
      _setState(
        state.copyWith(
          isPreparingImage: true,
          isLoading: false,
          selectedItemTitle: 'Preparing image',
          selectedItemStatus: 'Preparing your PackLox scan',
          clearErrorMessage: true,
        ),
        event: 'image copy started',
      );
      final persistedOriginalImage = await _galleryService.persistSelectedImage(
        originalGalleryImage,
      );
      final persistedImage =
          activeGalleryImage.path == originalGalleryImage.path
          ? persistedOriginalImage
          : await _galleryService.persistSelectedImage(activeGalleryImage);
      copyStopwatch.stop();
      debugPrint(
        '[Scanner] gallery image copy completed: ${persistedImage.path}',
      );
      _logFlow(
        'image copy completed',
        details: {
          'source': 'gallery',
          'path': persistedImage.path,
          'elapsedMs': copyStopwatch.elapsedMilliseconds,
        },
      );
      debugPrint('[Scanner] gallery picker returned path: ${image.path}');
      debugPrint(
        '[Scanner] copied persistent gallery path: ${persistedImage.path}',
      );
      debugPrint(
        '[Scanner] Supabase sync triggered after gallery selection: false',
      );
      await _acceptPreparedImage(
        imageRole: imageRole,
        source: 'gallery',
        activeImage: persistedImage,
        originalImage: persistedOriginalImage,
        enhancementPreset: selectedPreset,
        enhancementMetadata: previewResult?.metadata ?? const {},
      );
      _trackTelemetry(
        TelemetryEventNames.imageSelected,
        properties: const {'source': 'gallery'},
      );
      unawaited(
        _logPersistentGalleryDiagnostics(_displayPathFor(persistedImage)),
      );
    } on ScannerException catch (error) {
      debugPrint('[Scanner] gallery picker scanner error: ${error.code}');
      _logFlow('gallery picker scanner error', error: error);
      _recordTelemetryError(
        error,
        reason: 'scan_error',
        properties: {'source': 'gallery', 'code': error.code},
      );
      _setState(
        state.copyWith(
          errorMessage: error.message,
          isPreparingImage: false,
          clearSelectedImage: true,
          clearSelectedImagePath: true,
          clearSelectedItemTitle: true,
          clearSelectedItemStatus: true,
          clearScanResult: true,
          clearAiRecommendation: true,
        ),
        event: 'preparing image state false',
      );
    } on Object catch (error, stackTrace) {
      debugPrint('[Scanner] gallery picker failed: $error');
      debugPrint('$stackTrace');
      _logFlow('gallery picker failed', error: error, stackTrace: stackTrace);
      _recordTelemetryError(
        error,
        stackTrace: stackTrace,
        reason: 'scan_error',
        properties: const {'source': 'gallery'},
      );
      _setState(
        state.copyWith(
          isPreparingImage: false,
          errorMessage: 'Something went wrong. Please try again.',
        ),
        event: 'preparing image state false',
      );
    } finally {
      _isPickerActive = false;
      _logFlow('picker active false', details: {'source': 'gallery'});
      _setState(
        state.copyWith(isLoading: false),
        event: 'gallery loading shell cleared',
      );
    }
  }

  Future<void> _acceptPreparedImage({
    required String imageRole,
    required String source,
    required XFile activeImage,
    required XFile originalImage,
    required ImageEnhancementPreset enhancementPreset,
    required Map<String, Object?> enhancementMetadata,
  }) async {
    final selectedImagePath = _displayPathFor(activeImage);
    final originalImagePath = _displayPathFor(originalImage);
    await _ensureLocalImageExists(selectedImagePath, source: source);
    final quality = await _evaluateImageQuality(selectedImagePath);
    if (!quality.passed) {
      throw ScannerException(
        message: quality.userMessage,
        code: 'scanner.$source.quality_blocked',
      );
    }
    debugPrint(
      '[Scanner] selectedImagePath after $source capture: $selectedImagePath',
    );
    debugPrint(
      '[Scanner] Supabase sync triggered after $source selection: false',
    );
    final qualityMetadata = {
      ...quality.toMetadataJson(),
      ..._persistedEnhancementMetadata(
        enhancementMetadata,
        originalPath: originalImagePath,
        activePath: selectedImagePath,
        preset: enhancementPreset,
      ),
    };
    final capturedSlot = _photoSlotFor(
      imageRole: imageRole,
      path: selectedImagePath,
      source: source,
      image: activeImage,
      originalPath: originalImagePath,
      enhancementPreset: enhancementPreset,
      enhancedImagePath: enhancementPreset.isEnhanced
          ? selectedImagePath
          : null,
      qualityMetadata: qualityMetadata,
    );
    final captureImages = _appendCaptureImage(capturedSlot);
    _setState(
      state.copyWith(
        selectedImage: activeImage,
        selectedImagePath: selectedImagePath,
        selectedItemTitle: _selectedTitleForRole(
          imageRole: imageRole,
          source: source,
        ),
        selectedItemStatus: enhancementPreset.isEnhanced
            ? '${enhancementPreset.label} applied'
            : 'Ready for AI analysis',
        photoSlots: _latestSlotsFromImages(captureImages),
        captureImages: captureImages,
        activeCaptureRole: capturedSlot.role,
        scanSession: _updatedSessionWithImage(
          imageRole: imageRole,
          path: selectedImagePath,
          source: source,
          quality: quality,
          originalPath: originalImagePath,
          enhancementPreset: enhancementPreset,
          qualityMetadata: qualityMetadata,
        ),
        isPreparingImage: false,
        clearScanResult: true,
        clearAiRecommendation: true,
        isSavedToPortfolio: false,
      ),
      event: 'selected image state emitted',
    );
  }

  Map<String, Object?> _persistedEnhancementMetadata(
    Map<String, Object?> metadata, {
    required String originalPath,
    required String activePath,
    required ImageEnhancementPreset preset,
  }) {
    return {
      ...metadata,
      'originalImagePath': originalPath,
      'activeImagePath': activePath,
      'enhancementPreset': preset.id,
      'enhancementLabel': preset.label,
      'enhanced': preset.isEnhanced,
    };
  }

  /// Recovers an Android picker result if MainActivity was killed mid-capture.
  Future<void> recoverLostPickerData({String reason = 'startup'}) async {
    if (_isDisposed || _isPickerActive || _isRecoveringLostData) {
      debugPrint(
        '[Scanner] lost picker recovery skipped '
        'reason=$reason disposed=$_isDisposed '
        'pickerActive=$_isPickerActive recovering=$_isRecoveringLostData',
      );
      _logFlow(
        'lost data recovery skipped',
        details: {'reason': reason, 'disposed': _isDisposed},
      );
      return;
    }

    _isRecoveringLostData = true;
    debugPrint('[Scanner] lost picker recovery start: $reason');
    _logFlow('lost data recovery started', details: {'reason': reason});
    try {
      final recoveredImage = await _cameraService.retrieveLostImage();
      if (_isDisposed || recoveredImage == null) {
        _logFlow(
          'lost data recovery completed',
          details: {'reason': reason, 'recovered': false},
        );
        return;
      }

      debugPrint(
        '[Scanner] lost picker image returned path: ${recoveredImage.path}',
      );
      _keepScanSelected('lost-picker-recovery');
      await _galleryService.validateImage(recoveredImage);
      final persistedImage = await _galleryService.persistSelectedImage(
        recoveredImage,
      );
      final selectedImagePath = _displayPathFor(persistedImage);
      await _ensureLocalImageExists(selectedImagePath, source: 'recovered');
      final quality = await _evaluateImageQuality(selectedImagePath);
      debugPrint('[Scanner] lost picker persistent path: $selectedImagePath');
      final capturedSlot = _photoSlotFor(
        imageRole: 'front',
        path: selectedImagePath,
        source: 'recovered',
        image: persistedImage,
        qualityMetadata: quality.toMetadataJson(),
      );
      final captureImages = _appendCaptureImage(capturedSlot);
      _setState(
        state.copyWith(
          isLoading: false,
          isPreparingImage: false,
          selectedImage: persistedImage,
          selectedImagePath: selectedImagePath,
          selectedItemTitle: 'Recovered image',
          selectedItemStatus: 'Ready for AI analysis',
          photoSlots: _latestSlotsFromImages(captureImages),
          captureImages: captureImages,
          activeCaptureRole: capturedSlot.role,
          scanSession: _updatedSessionWithImage(
            imageRole: 'front',
            path: selectedImagePath,
            source: 'recovered',
            quality: quality,
          ),
          clearScanResult: true,
          clearAiRecommendation: true,
          clearErrorMessage: true,
          isSavedToPortfolio: false,
        ),
        event: 'selected image state emitted',
      );
      _logFlow(
        'lost data recovery completed',
        details: {'reason': reason, 'recovered': true},
      );
    } on ScannerException catch (error) {
      debugPrint('[Scanner] lost picker scanner error: ${error.code}');
      _logFlow('lost data recovery scanner error', error: error);
      _setState(
        state.copyWith(
          isLoading: false,
          isPreparingImage: false,
          errorMessage: error.message,
          clearSelectedImage: true,
          clearSelectedImagePath: true,
          clearSelectedItemTitle: true,
          clearSelectedItemStatus: true,
          clearScanResult: true,
          clearAiRecommendation: true,
          isSavedToPortfolio: false,
        ),
        event: 'preparing image state false',
      );
    } on UnimplementedError {
      debugPrint('[Scanner] lost picker recovery unsupported on platform');
      _logFlow('lost data recovery completed', details: {'unsupported': true});
    } on Object catch (error, stackTrace) {
      debugPrint('[Scanner] lost picker recovery failed: $error');
      debugPrint('$stackTrace');
      _logFlow(
        'lost data recovery failed',
        error: error,
        stackTrace: stackTrace,
      );
      _setState(
        state.copyWith(
          isLoading: false,
          isPreparingImage: false,
          errorMessage: 'Unable to recover the selected image.',
        ),
        event: 'preparing image state false',
      );
    } finally {
      _isRecoveringLostData = false;
      _logFlow('lost data recovery completed', details: {'reason': reason});
    }
  }

  /// Runs AI analysis for the selected scan preview.
  Future<void> analyzeWithAi() async {
    debugPrint('[Scanner] analyze start');
    if (state.isLoading || state.isPreparingImage) {
      _logFlow('analyze ignored while busy');
      return;
    }
    final scanToResultStopwatch = Stopwatch()..start();
    _logFlow('analyze tapped');
    _trackTelemetry(
      TelemetryEventNames.analyzeStarted,
      properties: {'source': _imageSourceFor(state.selectedImagePath ?? '')},
    );
    final selectedImagePath = state.selectedImagePath;
    if (selectedImagePath == null) {
      return;
    }
    final plan = _ensureSession().capturePlan;
    if (!plan.isMinimumReadyForAnalyze) {
      _setState(
        state.copyWith(
          errorMessage: _analyzeDisabledReason(plan),
          clearScanResult: true,
          clearAiRecommendation: true,
          isSavedToPortfolio: false,
        ),
        event: 'analyze blocked missing required roles',
      );
      return;
    }
    ref.read(scanPipelineStatusProvider.notifier).markReady();

    try {
      await ref
          .read(subscriptionControllerProvider.notifier)
          .ensureCanAnalyze();
    } on SubscriptionException catch (error) {
      ref.read(scanPipelineStatusProvider.notifier).markError();
      _trackTelemetry(
        TelemetryEventNames.analyzeFailed,
        properties: const {'reason': 'usage_limit'},
      );
      _recordTelemetryError(error, reason: 'scan_error');
      _setState(
        state.copyWith(
          errorMessage: error.message,
          clearScanResult: true,
          clearAiRecommendation: true,
          isSavedToPortfolio: false,
        ),
      );
      return;
    }

    final validationError = await _validateSelectedImagePath(selectedImagePath);
    if (validationError != null) {
      _trackTelemetry(
        TelemetryEventNames.analyzeFailed,
        properties: const {'reason': 'invalid_image'},
      );
      _setState(
        state.copyWith(
          errorMessage: validationError,
          clearScanResult: true,
          clearAiRecommendation: true,
          isSavedToPortfolio: false,
        ),
      );
      return;
    }

    _setState(
      state.copyWith(
        isLoading: true,
        isPreparingImage: false,
        clearErrorMessage: true,
        isSavedToPortfolio: false,
      ),
    );
    try {
      _logAnalyzerRuntimeConfig();
      final scannerTraceId = 'scan-${DateTime.now().microsecondsSinceEpoch}';
      debugPrint('[AnalyzerTrace] scanner-trace-id=$scannerTraceId');
      final aiStopwatch = Stopwatch()..start();
      final analyzerResponse = await _analyzerService.analyze(
        AnalyzerRequest(
          imagePath: selectedImagePath,
          image: state.selectedImage,
          images: [
            for (final slot in state.captureImages)
              if (!slot.path.startsWith('sample://'))
                AnalyzerImageInput(
                  path: slot.analyzerPath,
                  role: slot.role,
                  image: slot.image,
                  source: slot.source,
                ),
          ],
          metadata: {
            'selectedItemTitle': state.selectedItemTitle,
            'selectedItemStatus': state.selectedItemStatus,
            'imageCount': state.captureImages.length,
            'imageRoles': state.captureImages
                .map((slot) => slot.role)
                .join(','),
            'captureCategory': state.captureCategory.id,
            'captureCategorySelected': state.hasManualCaptureCategory,
            'activeImagePath': selectedImagePath,
            'activeEnhancementPreset': _activeSlotForPath(
              selectedImagePath,
            )?.enhancementPreset.id,
            'enhancedImageCount': state.captureImages
                .where((slot) => slot.isEnhanced)
                .length,
            'scannerTraceId': scannerTraceId,
            ..._analyzeMetadata(),
          },
        ),
      );
      final analysis = analyzerResponse.toAiAnalysisResult();
      final localPhotoRoles = [
        for (final slot in state.captureImages)
          if (!slot.path.startsWith('sample://')) slot.role,
      ];
      aiStopwatch.stop();
      debugPrint(
        '[Scanner] AI analysis latencyMs=${aiStopwatch.elapsedMilliseconds}',
      );
      debugPrint(
        '[AnalyzerTrace] response-mapped '
        'analysisPath=${analyzerResponse.rawProviderPayload['analysisPath'] ?? 'unknown'} '
        'provider=${analyzerResponse.rawProviderPayload['provider'] ?? 'unknown'} '
        'selectedProvider=${analyzerResponse.rawProviderPayload['selectedProvider'] ?? 'unknown'} '
        'requestedProvider=${analyzerResponse.rawProviderPayload['requestedProvider'] ?? 'unknown'} '
        'backendResponseSource=${analyzerResponse.rawProviderPayload['backendResponseSource'] ?? 'unknown'} '
        'title="${analyzerResponse.title}" '
        'category=${analyzerResponse.category} '
        'manufacturer=${analyzerResponse.manufacturer ?? 'unknown'} '
        'normalizedLookupQuery="${_pricingLookupQuery(analyzerResponse.scanResult)}" '
        'pricingAttempted=${analyzerResponse.scanResult.valuationStatus != ValuationStatus.providerNotConfigured} '
        'pricingProvider=${analyzerResponse.scanResult.pricing.pricingSource} '
        'pricingStatus=${analyzerResponse.scanResult.valuationStatus.wireValue} '
        'marketEstimatedValue=${analyzerResponse.scanResult.estimatedMarketValue ?? 0} '
        'aiEstimatedValue=${analyzerResponse.scanResult.aiEstimatedValue ?? 0} '
        'finalValue=${analyzerResponse.scanResult.estimatedValue} '
        'renderedValue="${_renderedValueForTrace(analyzerResponse.scanResult)}"',
      );
      final enrichmentStopwatch = Stopwatch()..start();
      final enrichedAnalysis = await _enrichmentService.enrich(
        analysis: analysis,
        metadata: ScanResultEnrichmentMetadata(
          imagePath: selectedImagePath,
          imageSource: _imageSourceFor(selectedImagePath),
        ),
      );
      enrichmentStopwatch.stop();
      debugPrint(
        '[Scanner] pricing enrichment latencyMs='
        '${enrichmentStopwatch.elapsedMilliseconds}',
      );
      final enrichedScanResult = enrichedAnalysis.scanResult;
      final galleryImages = _galleryImagesFromSlots();
      final scanResultWithPhotoMetadata = enrichedScanResult.copyWith(
        photosUsed: enrichedScanResult.photosUsed ?? galleryImages.length,
        photoRoles: enrichedScanResult.photoRoles.isNotEmpty
            ? enrichedScanResult.photoRoles
            : localPhotoRoles,
        galleryImages: galleryImages,
      );
      _setState(
        state.copyWith(
          scanResult: scanResultWithPhotoMetadata,
          aiRecommendation: enrichedAnalysis.recommendation,
          scanSession: _sessionWithAnalyzeCompleted(
            confidenceAchieved: scanResultWithPhotoMetadata.confidence,
          ),
          isSavedToPortfolio: false,
        ),
      );
      await ref
          .read(subscriptionControllerProvider.notifier)
          .recordSuccessfulAnalysis();
      ref.read(scanPipelineStatusProvider.notifier).markCompleted();
      scanToResultStopwatch.stop();
      _trackTelemetry(
        TelemetryEventNames.analyzeSuccess,
        properties: {
          'source': _imageSourceFor(selectedImagePath),
          'latency_ms': scanToResultStopwatch.elapsedMilliseconds,
        },
      );
      debugPrint(
        '[Scanner] scan-to-result latencyMs='
        '${scanToResultStopwatch.elapsedMilliseconds}',
      );
    } on AnalyzerException catch (error) {
      debugPrint(
        '[AnalyzerTrace] request-failed type=${error.type.name} '
        'status=${error.statusCode ?? 0} message="${error.message}"',
      );
      ref.read(scanPipelineStatusProvider.notifier).markError();
      _trackTelemetry(
        TelemetryEventNames.analyzeFailed,
        properties: {'reason': 'analyzer', 'type': error.type.name},
      );
      _recordTelemetryError(error, reason: 'scan_error');
      _setState(
        state.copyWith(
          errorMessage: error.message,
          clearScanResult: true,
          clearAiRecommendation: true,
          isSavedToPortfolio: false,
        ),
      );
    } on NetworkException catch (error) {
      ref.read(scanPipelineStatusProvider.notifier).markError();
      _trackTelemetry(
        TelemetryEventNames.analyzeFailed,
        properties: {
          'reason': 'backend_unavailable',
          'status': error.statusCode,
        },
      );
      _recordTelemetryError(
        error,
        reason: 'backend_unavailable',
        properties: {'status': error.statusCode},
      );
      _setState(
        state.copyWith(
          errorMessage: _messageForNetworkError(error),
          clearScanResult: true,
          clearAiRecommendation: true,
          isSavedToPortfolio: false,
        ),
      );
    } on Object catch (error, stackTrace) {
      ref.read(scanPipelineStatusProvider.notifier).markError();
      debugPrint('[Scanner] analysis failed: $error');
      debugPrint('$stackTrace');
      _trackTelemetry(
        TelemetryEventNames.analyzeFailed,
        properties: const {'reason': 'unexpected'},
      );
      _recordTelemetryError(
        error,
        stackTrace: stackTrace,
        reason: 'scan_error',
      );
      _setState(
        state.copyWith(
          errorMessage: 'Something went wrong. Please try again.',
          clearScanResult: true,
          clearAiRecommendation: true,
          isSavedToPortfolio: false,
        ),
      );
    } finally {
      if (scanToResultStopwatch.isRunning) {
        scanToResultStopwatch.stop();
        debugPrint(
          '[Scanner] scan-to-result ended latencyMs='
          '${scanToResultStopwatch.elapsedMilliseconds}',
        );
      }
      _setState(state.copyWith(isLoading: false));
    }
  }

  void _logAnalyzerRuntimeConfig() {
    final environmentConfig = EnvironmentConfig.fromEnvironment();
    final flags = FeatureFlags.fromEnvironment();
    final supabaseConfig = SupabaseConfig.fromEnvironment();
    final aiConfig = AiAnalysisProviderConfig.fromEnvironment();
    final analyzerConfig = AnalyzerConfig.fromEnvironment();
    debugPrint(
      '[AnalyzerTrace] runtime-config '
      'APP_ENV=${environmentConfig.environment.name} '
      'USE_CLOUD_AUTH=${flags.useCloudAuth} '
      'USE_CLOUD_PORTFOLIO_SYNC=${flags.useCloudPortfolioSync} '
      'USE_CLOUD_IMAGE_STORAGE=${flags.useCloudImageStorage} '
      'SUPABASE_ENABLED=${supabaseConfig.isEnabled} '
      'SUPABASE_URL_CONFIGURED=${supabaseConfig.hasUrl} '
      'SUPABASE_ANON_KEY_CONFIGURED=${supabaseConfig.hasAnonKey} '
      'SUPABASE_ANON_KEY_LENGTH=${supabaseConfig.anonKeyLength} '
      'AI_ANALYSIS_PROVIDER=${aiConfig.type.configValue} '
      'ANALYZER_PROVIDER=${analyzerConfig.providerType.configValue} '
      'MOCK_MODE_ENABLED=${!aiConfig.hasBackendAnalysisEndpoint} '
      'AI_BACKEND_ANALYSIS_ENDPOINT_URL=${_safeEndpoint(aiConfig.backendAnalysisEndpointUrl)} '
      'API_BASE_URL=${_safeEndpoint(environmentConfig.baseUrl)}',
    );
  }

  String _safeEndpoint(String endpoint) {
    final trimmed = endpoint.trim();
    if (trimmed.isEmpty) {
      return '<empty>';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return '<invalid>';
    }
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
    ).toString();
  }

  String _pricingLookupQuery(ScanResult result) {
    return [
          result.title,
          result.brand,
          result.series,
          result.year,
          result.category,
          result.condition,
        ]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) {
          return value.isNotEmpty;
        })
        .join(' ');
  }

  String _renderedValueForTrace(ScanResult result) {
    if (result.estimatedValue > 0) {
      return result.estimatedValue.toStringAsFixed(0);
    }
    return switch (result.valuationStatus) {
      ValuationStatus.providerNotConfigured =>
        'Market value unavailable — pricing source not connected yet',
      ValuationStatus.noMarketMatch => 'No reliable market match found yet',
      ValuationStatus.lookupFailed => 'Value lookup failed — try again',
      ValuationStatus.aiEstimated => 'AI-estimated value unavailable',
      ValuationStatus.marketEstimated => 'Value unavailable',
      ValuationStatus.unavailable => 'Value unavailable',
    };
  }

  /// Saves the latest scan result to the in-memory portfolio.
  Future<bool> saveScanResultToPortfolio() async {
    final result = state.scanResult;
    if (result == null ||
        state.isSavedToPortfolio ||
        state.isSavingToPortfolio) {
      return false;
    }

    debugPrint('[Scanner] Save to Portfolio tapped for result id=${result.id}');
    _logFlow('save tapped', details: {'scanResultId': result.id});
    state = state.copyWith(isSavingToPortfolio: true);
    final item = CollectibleItem(
      id: result.id,
      title: result.title,
      category: result.category,
      estimatedValue: result.estimatedValue,
      confidence: result.confidence,
      condition: result.condition,
      recommendation:
          state.aiRecommendation ?? 'Consider grading before selling.',
      imagePath: _primaryImagePathFor(result),
      galleryImages: result.galleryImages.isNotEmpty
          ? result.galleryImages
          : _galleryImagesFromSlots(),
      createdAt: DateTime.now(),
      pricing: result.pricing,
      marketSummary: result.marketSummary,
      primaryMatch: result.primaryMatch,
      alternativeMatches: [
        for (final match in result.alternativeMatches)
          CollectibleAlternativeMatch(
            title: match.title,
            category: match.category,
            confidence: match.confidence,
            reason: match.reason,
          ),
      ],
      confidenceExplanation: result.confidenceExplanation,
      detectionQuality: result.detectionQuality,
      aiReasoning: result.aiReasoning,
      year: result.year,
      brand: result.brand,
      setName: result.setName,
      series: result.series,
      cardNumber: result.cardNumber,
      playerOrCharacter: result.playerOrCharacter,
      rarity: result.rarity,
      estimatedGrade: result.estimatedGrade,
      language: result.language,
      edition: result.edition,
      country: result.country,
      mint: result.mint,
      material: result.material,
      notes: result.notes,
      valuationStatus: result.valuationStatus,
      valuationSource: result.valuationSource,
      aiEstimatedValue: result.aiEstimatedValue,
    );

    debugPrint(
      '[Scanner] CollectibleItem.imagePath before save: '
      '${item.imagePath}',
    );
    debugPrint(
      '[Scanner] CollectibleItem.galleryImages before save: '
      '${item.galleryImages.length}',
    );
    debugPrint(
      '[Scanner] CollectibleItem before save '
      'id=${item.id} '
      'title="${item.title}" '
      'imageSource=${_imageSourceFor(item.imagePath)} '
      'scanDate=${result.scanDate.toIso8601String()} '
      'createdAt=${item.createdAt.toIso8601String()} '
      'savedAt=${item.createdAt.toIso8601String()} '
      'updatedAt=not-tracked',
    );
    debugPrint(
      '[Scanner] image file exists before save: '
      '${await _localFileExists(item.imagePath)}',
    );
    try {
      await ref.read(portfolioControllerProvider.notifier).saveItem(item);
      _logFlow('portfolio updated', details: {'itemId': item.id});
      _trackCloudAnalytics(
        'portfolio_item_saved',
        properties: {
          'category': item.category,
          'source': _imageSourceFor(item.imagePath),
        },
      );
      _trackTelemetry(
        TelemetryEventNames.saveToPortfolio,
        properties: {
          'category': item.category,
          'source': _imageSourceFor(item.imagePath),
        },
      );
      await ref
          .read(imageSyncControllerProvider.notifier)
          .enqueueImage(collectibleId: item.id, localPath: item.imagePath);
      unawaited(_syncSavedItemIfEnabled(itemId: item.id));
      state = state.copyWith(
        isSavedToPortfolio: true,
        isSavingToPortfolio: false,
      );
      return true;
    } catch (_) {
      state = state.copyWith(isSavingToPortfolio: false);
      rethrow;
    }
  }

  /// Applies local-only review edits to the current scan result before saving.
  void applyResultReviewEdits({
    required String title,
    required String category,
    required String condition,
    required double estimatedValue,
    String? notes,
  }) {
    final result = state.scanResult;
    if (result == null || state.isSavedToPortfolio) {
      return;
    }

    state = state.copyWith(
      scanResult: result.copyWith(
        title: title.trim().isEmpty ? result.title : title.trim(),
        category: category.trim().isEmpty ? result.category : category.trim(),
        condition: condition.trim().isEmpty
            ? result.condition
            : condition.trim(),
        estimatedValue: estimatedValue < 0
            ? result.estimatedValue
            : estimatedValue,
        notes: notes?.trim(),
      ),
    );
  }

  /// Clears the active scan so the user can start over.
  void resetScan() {
    state = state.copyWith(
      isLoading: false,
      isPreparingImage: false,
      clearSelectedImage: true,
      clearSelectedImagePath: true,
      clearSelectedItemTitle: true,
      clearSelectedItemStatus: true,
      clearPhotoSlots: true,
      clearCaptureImages: true,
      clearActiveCaptureRole: true,
      clearPrimaryImagePath: true,
      hasManualCaptureCategory: false,
      clearScanSession: true,
      clearScanResult: true,
      clearAiRecommendation: true,
      clearErrorMessage: true,
      isSavedToPortfolio: false,
    );
    ref.read(scanPipelineStatusProvider.notifier).markReady();
  }

  /// Removes the captured image for a role and refreshes session readiness.
  void deleteRoleImage(String imageRole) {
    final normalizedRole = _normalizeImageRole(imageRole);
    final slot = _latestSlotForRole(normalizedRole);
    if (slot == null) {
      selectCaptureRole(normalizedRole);
      return;
    }
    deleteCapturedImage(slot.path);
  }

  void deleteCapturedImage(String imagePath) {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.isEmpty) {
      return;
    }
    final nextImages = [
      for (final slot in state.captureImages)
        if (slot.path != normalizedPath) slot,
    ];
    final nextSlots = _latestSlotsFromImages(nextImages);
    final capturedImages = [
      for (final slot in nextImages) _capturedImageFromSlot(slot),
    ];
    final session = _ensureSession()
        .copyWith(
          capturedImages: capturedImages,
          capturePlan: _capturePlanService.buildPlan(
            state.scanSession?.scanGoal ?? ScanGoal.identifyValue,
            state.captureCategory,
            capturedImages,
          ),
          clearConfidenceAchieved: true,
          clearEndTime: true,
        )
        .addEvent(
          CaptureEvent(
            type: CaptureEventType.roleRequested,
            timestamp: DateTime.now(),
            role: state.activeCaptureRole,
            metadata: const {'action': 'delete'},
          ),
        );
    final nextSelectedSlot =
        nextImages.lastOrNull ?? nextSlots[ScanCaptureRole.front.id];
    final deletedPrimary = state.primaryImagePath == normalizedPath;
    final nextPrimaryPath = deletedPrimary
        ? nextSelectedSlot?.path
        : state.primaryImagePath;

    _setState(
      state.copyWith(
        photoSlots: nextSlots,
        captureImages: nextImages,
        scanSession: session,
        selectedImage: nextSelectedSlot?.image,
        selectedImagePath: nextSelectedSlot?.path,
        activeCaptureRole: nextSelectedSlot?.role ?? state.activeCaptureRole,
        primaryImagePath: nextPrimaryPath,
        clearPrimaryImagePath: nextPrimaryPath == null,
        selectedItemTitle: nextSelectedSlot == null
            ? null
            : '${nextSelectedSlot.label} photo',
        selectedItemStatus: nextSelectedSlot == null
            ? null
            : 'Ready for AI analysis',
        clearSelectedImage: nextSelectedSlot == null,
        clearSelectedImagePath: nextSelectedSlot == null,
        clearSelectedItemTitle: nextSelectedSlot == null,
        clearSelectedItemStatus: nextSelectedSlot == null,
        clearScanResult: true,
        clearAiRecommendation: true,
        clearErrorMessage: true,
        isSavedToPortfolio: false,
      ),
      event: 'role image deleted',
    );
  }

  /// Clears completed saved work when the user leaves the scan tab.
  void resetAfterSaved() {
    if (!state.isSavedToPortfolio) {
      return;
    }

    resetScan();
  }

  /// Clears stale scanner state before a deliberate new scan.
  void resetWhenStartingNewScan() {
    resetScan();
  }

  /// Switches between available cameras.
  Future<void> switchCameras() {
    return _cameraService.switchCameras();
  }

  /// Sets camera flash mode.
  Future<void> setFlashMode(FlashMode mode) {
    return _cameraService.setFlashMode(mode);
  }

  /// Disposes active camera resources.
  Future<void> disposeCamera() {
    return _cameraService.disposeCamera();
  }

  String _displayPathFor(XFile image) {
    if (image.path.isNotEmpty) {
      return image.path;
    }

    return image.name.isEmpty ? 'selected-image' : image.name;
  }

  ScannerPhotoSlot _photoSlotFor({
    required String imageRole,
    required String path,
    required String source,
    XFile? image,
    String? originalPath,
    ImageEnhancementPreset enhancementPreset = ImageEnhancementPreset.original,
    String? enhancedImagePath,
    Map<String, Object?> qualityMetadata = const {},
  }) {
    final normalizedRole = _normalizeImageRole(imageRole);
    return ScannerPhotoSlot(
      role: normalizedRole,
      label: _slotLabel(normalizedRole),
      path: path,
      source: source,
      image: image,
      originalPath: originalPath ?? path,
      enhancementPreset: enhancementPreset,
      enhancedImagePath: enhancedImagePath,
      qualityMetadata: qualityMetadata,
      capturedAt: DateTime.now(),
    );
  }

  List<ScannerPhotoSlot> _appendCaptureImage(ScannerPhotoSlot slot) {
    return [...state.captureImages, slot];
  }

  CapturedScanImage _capturedImageFromSlot(ScannerPhotoSlot slot) {
    return CapturedScanImage(
      path: slot.analyzerPath,
      role: ScanCaptureRole.fromId(slot.role),
      source: slot.source,
      originalPath: slot.originalPath ?? slot.path,
      enhancementPreset: slot.enhancementPreset.id,
      qualityMetadata: {
        ...slot.qualityMetadata,
        'originalImagePath': slot.originalPath ?? slot.path,
        'activeImagePath': slot.path,
        'enhancementPreset': slot.enhancementPreset.id,
        'enhancementLabel': slot.enhancementPreset.label,
        'enhanced': slot.isEnhanced,
      },
    );
  }

  Map<String, ScannerPhotoSlot> _latestSlotsFromImages(
    List<ScannerPhotoSlot> images,
  ) {
    return {for (final image in images) image.role: image};
  }

  ScannerPhotoSlot? _latestSlotForRole(String imageRole) {
    final normalizedRole = _normalizeImageRole(imageRole);
    for (final slot in state.captureImages.reversed) {
      if (slot.role == normalizedRole) {
        return slot;
      }
    }
    return state.photoSlots[normalizedRole];
  }

  ScannerPhotoSlot? _activeSlotForPath(String imagePath) {
    final normalizedPath = imagePath.trim();
    for (final slot in state.captureImages) {
      if (slot.path == normalizedPath) {
        return slot;
      }
    }
    return null;
  }

  XFile? _imageFileForEnhancementResult(
    ScannerPhotoSlot slot,
    ImageEnhancementResult result,
  ) {
    if (result.createdEnhancedFile) {
      return XFile(result.activePath);
    }
    if (!result.preset.isEnhanced && _isLocalImagePath(result.originalPath)) {
      return XFile(result.originalPath);
    }
    return slot.image;
  }

  bool _isLocalImagePath(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty) {
      return false;
    }
    return !normalized.startsWith('sample://') &&
        !normalized.startsWith('assets/') &&
        !normalized.startsWith('http://') &&
        !normalized.startsWith('https://');
  }

  ScanSession _ensureSession({ScanGoal? scanGoal}) {
    final goal =
        scanGoal ?? state.scanSession?.scanGoal ?? ScanGoal.identifyValue;
    final capturedImages = _capturedImagesFromCaptureImages();
    final plan = _capturePlanService.buildPlan(
      goal,
      state.captureCategory,
      capturedImages,
    );
    final existing = state.scanSession;
    if (existing != null) {
      return existing.copyWith(
        scanGoal: goal,
        capturePlan: plan,
        capturedImages: capturedImages,
        confidenceTarget: goal.confidenceTarget,
      );
    }
    return ScanSession.start(
      sessionId: 'scan-${DateTime.now().microsecondsSinceEpoch}',
      scanGoal: goal,
      capturePlan: plan,
    ).copyWith(capturedImages: capturedImages);
  }

  ScanSession _updatedSessionWithImage({
    required String imageRole,
    required String path,
    required String source,
    required ScanQualityEvaluation quality,
    String? originalPath,
    ImageEnhancementPreset enhancementPreset = ImageEnhancementPreset.original,
    Map<String, Object?>? qualityMetadata,
  }) {
    final session = _ensureSession();
    final effectiveOriginalPath = originalPath ?? path;
    final effectiveMetadata =
        qualityMetadata ??
        {
          ...quality.toMetadataJson(),
          'originalImagePath': effectiveOriginalPath,
          'activeImagePath': path,
          'enhancementPreset': enhancementPreset.id,
          'enhancementLabel': enhancementPreset.label,
          'enhanced': enhancementPreset.isEnhanced,
        };
    final capturedImages = [
      for (final image in session.capturedImages) image,
      CapturedScanImage(
        path: path,
        role: ScanCaptureRole.fromId(imageRole),
        source: source,
        originalPath: effectiveOriginalPath,
        enhancementPreset: enhancementPreset.id,
        qualityMetadata: effectiveMetadata,
      ),
    ];
    final plan = _capturePlanService.buildPlan(
      session.scanGoal,
      state.captureCategory,
      capturedImages,
    );
    return session
        .copyWith(
          capturePlan: plan,
          capturedImages: capturedImages,
          clearConfidenceAchieved: true,
          clearEndTime: true,
        )
        .addEvent(
          CaptureEvent(
            type: CaptureEventType.roleCaptured,
            timestamp: DateTime.now(),
            role: ScanCaptureRole.fromId(imageRole).id,
            metadata: {'source': source},
          ),
        )
        .addEvent(
          CaptureEvent(
            type: switch (quality.severity) {
              QualityGateSeverity.pass => CaptureEventType.qualityGatePassed,
              QualityGateSeverity.warning =>
                CaptureEventType.qualityGateWarning,
              QualityGateSeverity.blocker =>
                CaptureEventType.qualityGateBlocked,
            },
            timestamp: DateTime.now(),
            role: ScanCaptureRole.fromId(imageRole).id,
            metadata: quality.toMetadataJson(),
          ),
        );
  }

  ScanSession _sessionWithEventForRole(
    CaptureEventType type,
    String imageRole,
  ) {
    return _ensureSession().addEvent(
      CaptureEvent(
        type: type,
        timestamp: DateTime.now(),
        role: ScanCaptureRole.fromId(imageRole).id,
      ),
    );
  }

  ScanSession _sessionWithAnalyzeCompleted({
    required double confidenceAchieved,
  }) {
    final session = _ensureSession();
    return session
        .copyWith(
          confidenceAchieved: confidenceAchieved,
          endTime: DateTime.now(),
        )
        .addEvent(
          CaptureEvent(
            type: CaptureEventType.analyzeCompleted,
            timestamp: DateTime.now(),
            metadata: {'confidenceAchieved': confidenceAchieved},
          ),
        )
        .addEvent(
          CaptureEvent(
            type: CaptureEventType.sessionCompleted,
            timestamp: DateTime.now(),
          ),
        );
  }

  List<CapturedScanImage> _capturedImagesFromSlots(
    Map<String, ScannerPhotoSlot> slots,
  ) {
    return [
      for (final slot in slots.values)
        CapturedScanImage(
          path: slot.path,
          role: ScanCaptureRole.fromId(slot.role),
          source: slot.source,
          qualityMetadata: slot.qualityMetadata,
        ),
    ];
  }

  List<CapturedScanImage> _capturedImagesFromCaptureImages() {
    if (state.captureImages.isEmpty) {
      return _capturedImagesFromSlots(state.photoSlots);
    }
    return [
      for (final slot in state.captureImages) _capturedImageFromSlot(slot),
    ];
  }

  List<CollectibleImage> _galleryImagesFromSlots() {
    final slots = _orderedSlotsForPrimary();
    final primaryPath = slots.firstOrNull?.path ?? state.selectedImagePath;
    final seen = <String>{};
    return [
      for (final slot in slots)
        if (seen.add(slot.path))
          CollectibleImage(
            path: slot.path,
            role: slot.role,
            source: slot.source,
            originalPath: slot.originalPath,
            enhancementPreset: slot.enhancementPreset.id,
            isPrimary: slot.path == primaryPath,
          ),
    ];
  }

  List<ScannerPhotoSlot> _orderedSlotsForPrimary() {
    final slots = state.captureImages.isNotEmpty
        ? state.captureImages
        : state.photoSlots.values.toList(growable: false);
    final primaryPath = state.primaryImagePath;
    int priority(ScannerPhotoSlot slot) {
      if (primaryPath != null && slot.path == primaryPath) {
        return -1;
      }
      if (slot.role == ScanCaptureRole.front.id) {
        return 0;
      }
      if (slot.role == ScanCaptureRole.back.id) {
        return 1;
      }
      if (slot.path == state.selectedImagePath) {
        return 2;
      }
      return 3;
    }

    return [...slots]..sort((a, b) => priority(a).compareTo(priority(b)));
  }

  String _primaryImagePathFor(ScanResult result) {
    for (final image in result.galleryImages) {
      if (image.isPrimary && image.path.trim().isNotEmpty) {
        return image.path;
      }
    }
    final firstGalleryPath = result.galleryImages.firstOrNull?.path.trim();
    if (firstGalleryPath != null && firstGalleryPath.isNotEmpty) {
      return firstGalleryPath;
    }
    final frontSlot = state.photoSlots[ScanCaptureRole.front.id];
    if (frontSlot != null && frontSlot.path.trim().isNotEmpty) {
      return frontSlot.path;
    }
    return result.thumbnail;
  }

  Future<ScanQualityEvaluation> _evaluateImageQuality(String imagePath) {
    return _qualityGateService.evaluateFile(imagePath);
  }

  Map<String, Object?> _analyzeMetadata() {
    final session = _ensureSession().addEvent(
      CaptureEvent(
        type: CaptureEventType.analyzeTriggered,
        timestamp: DateTime.now(),
      ),
    );
    _setState(state.copyWith(scanSession: session), event: 'analyze event');
    final confidence = ConfidenceModel(
      confidenceTarget: session.confidenceTarget,
      confidenceAchieved: session.confidenceAchieved,
    );
    return {
      'scanGoal': session.scanGoal.id,
      'confidenceTarget': session.confidenceTarget,
      'confidenceAchieved': session.confidenceAchieved,
      'confidenceDeltaFromTarget': confidence.deltaFromTarget,
      'scannerUxVersion': scannerUxVersion,
      'sessionId': session.sessionId,
      'qualityMetadata': {
        for (final image in session.capturedImages)
          image.role.id: image.qualityMetadata,
      },
      'captureCategory': state.captureCategory.id,
    };
  }

  String _normalizeImageRole(String value) {
    return ScanCaptureRole.fromId(value).id;
  }

  String _slotLabel(String role) {
    return ScanCaptureRole.fromId(role).title;
  }

  String _analyzeDisabledReason(ScanCapturePlan plan) {
    final missingRequired = plan.requiredRoles
        .where((role) => !state.photoSlots.containsKey(role.id))
        .toList();
    if (missingRequired.length == 1) {
      return 'Add ${missingRequired.single.title.toLowerCase()} photo to continue.';
    }
    return 'Add ${missingRequired.length} more required photos.';
  }

  String _selectedTitleForRole({
    required String imageRole,
    required String source,
  }) {
    final normalizedRole = _normalizeImageRole(imageRole);
    if (normalizedRole == 'front') {
      return source == 'camera' ? 'Captured image' : 'Gallery image';
    }
    return '${_slotLabel(normalizedRole)} photo';
  }

  Future<String?> _validateSelectedImagePath(String imagePath) async {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.isEmpty || normalizedPath == 'selected-image') {
      return 'Selected image path is missing. Please choose another image.';
    }
    if (normalizedPath.startsWith('sample://')) {
      return null;
    }
    if (normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://') ||
        normalizedPath.startsWith('assets/')) {
      return null;
    }
    if (!await _safeLocalFileExists(normalizedPath)) {
      return 'Selected image could not be found. Please choose another image.';
    }

    return null;
  }

  Future<void> _ensureLocalImageExists(
    String imagePath, {
    required String source,
  }) async {
    final error = await _validateSelectedImagePath(imagePath);
    if (error != null) {
      throw ScannerException(
        message: error,
        code: 'scanner.$source.missing_file',
      );
    }
  }

  Future<bool> _localFileExists(String imagePath) async {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.isEmpty ||
        normalizedPath.startsWith('sample://') ||
        normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://') ||
        normalizedPath.startsWith('assets/')) {
      return false;
    }

    return File(normalizedPath).existsSync();
  }

  Future<bool> _safeLocalFileExists(String imagePath) async {
    try {
      return _localFileExists(imagePath);
    } on Exception catch (error) {
      debugPrint('[Scanner] unable to check image file exists: $error');
      return false;
    }
  }

  Future<int> _localFileSize(String imagePath) async {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.isEmpty ||
        normalizedPath.startsWith('sample://') ||
        normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://') ||
        normalizedPath.startsWith('assets/')) {
      return 0;
    }

    final file = File(normalizedPath);
    if (!file.existsSync()) {
      return 0;
    }

    return file.lengthSync();
  }

  Future<int> _safeLocalFileSize(String imagePath) async {
    try {
      return _localFileSize(imagePath);
    } on Exception catch (error) {
      debugPrint('[Scanner] unable to check image file size: $error');
      return 0;
    }
  }

  Future<void> _logPersistentGalleryDiagnostics(String imagePath) async {
    final fileExists = await _safeLocalFileExists(imagePath);
    debugPrint('[Scanner] persistent gallery file exists: $fileExists');
    final fileSize = await _safeLocalFileSize(imagePath);
    debugPrint('[Scanner] persistent gallery file size: $fileSize');
  }

  String _messageForNetworkError(NetworkException error) {
    return switch (error.statusCode) {
      413 => 'Image is too large. Please choose an image under 10MB.',
      415 => 'Please select a PNG, JPG, or JPEG image.',
      _ => 'AI backend is not reachable. Check your internet/backend setup.',
    };
  }

  String _imageSourceFor(String imagePath) {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.startsWith('sample://')) {
      return 'sample';
    }
    if (normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://')) {
      return 'network';
    }
    if (normalizedPath.startsWith('assets/')) {
      return 'asset';
    }
    if (normalizedPath.isEmpty) {
      return 'missing';
    }

    return 'local';
  }

  void _trackTelemetry(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) {
    unawaited(_telemetry.trackEvent(eventName, properties: properties));
  }

  Future<void> _syncSavedItemIfEnabled({required String itemId}) async {
    final registry = ref.read(cloudServiceRegistryProvider);
    if (!_cloudPortfolioSyncEnabled(registry)) {
      return;
    }

    _trackCloudAnalytics('portfolio_sync_started');
    try {
      final repository = ref.read(portfolioRepositoryProvider);
      await CloudPortfolioSyncCoordinator(
        registry: registry,
        portfolioRepository: repository,
      ).syncPendingItems();
      final savedItem = (await repository.getItems())
          .where((item) => item.id == itemId)
          .firstOrNull;
      await ref.read(portfolioControllerProvider.notifier).loadItems();
      if (savedItem?.syncStatus == CloudItemSyncStatus.failed) {
        _trackCloudAnalytics(
          'portfolio_sync_failed',
          properties: {'error': savedItem?.syncError ?? 'item_sync_failed'},
        );
      } else {
        _trackCloudAnalytics('portfolio_sync_success');
      }
    } on Object catch (error) {
      _trackCloudAnalytics(
        'portfolio_sync_failed',
        properties: {'error': error.runtimeType.toString()},
      );
    }
  }

  bool _cloudPortfolioSyncEnabled(CloudServiceRegistry registry) {
    final flags = registry.config.featureFlags;
    return registry.config.allowsCloudServices &&
        flags.useCloudPortfolioSync &&
        flags.useCloudImageStorage;
  }

  void _trackCloudAnalytics(
    String name, {
    Map<String, Object?> properties = const {},
  }) {
    unawaited(
      ref
          .read(cloudServiceRegistryProvider)
          .analyticsService
          .trackEvent(name, properties: properties),
    );
  }

  void _recordTelemetryError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, Object?> properties = const {},
  }) {
    unawaited(
      _telemetry.recordNonFatalError(
        error,
        stackTrace: stackTrace,
        reason: reason,
        properties: properties,
      ),
    );
  }
}

/// Provides scanner presentation state and workflow coordination.
final scannerControllerProvider =
    NotifierProvider<ScannerController, ScannerState>(ScannerController.new);
