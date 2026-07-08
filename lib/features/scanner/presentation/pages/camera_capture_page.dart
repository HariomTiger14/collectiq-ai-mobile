import 'package:camera/camera.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/image_enhancement_preset.dart';
import 'package:collectiq_ai/features/scanner/services/camera_service.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/image_enhancement_preview_page.dart';
import 'package:collectiq_ai/features/scanner/services/scan_image_processing_service.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraCaptureFlowResult {
  const CameraCaptureFlowResult._({
    this.image,
    this.originalImage,
    this.enhancementPreset = ImageEnhancementPreset.original,
    this.enhancementMetadata = const {},
    this.openGallery = false,
  });

  const CameraCaptureFlowResult.image(
    XFile image, {
    XFile? originalImage,
    ImageEnhancementPreset enhancementPreset = ImageEnhancementPreset.original,
    Map<String, Object?> enhancementMetadata = const {},
  }) : this._(
         image: image,
         originalImage: originalImage,
         enhancementPreset: enhancementPreset,
         enhancementMetadata: enhancementMetadata,
       );

  const CameraCaptureFlowResult.galleryFallback() : this._(openGallery: true);

  final XFile? image;
  final XFile? originalImage;
  final ImageEnhancementPreset enhancementPreset;
  final Map<String, Object?> enhancementMetadata;
  final bool openGallery;
}

/// Full-screen camera capture experience for scanner image acquisition.
class CameraCapturePage extends ConsumerStatefulWidget {
  /// Creates the camera capture page.
  const CameraCapturePage({required this.imageRole, super.key});

  final String imageRole;

  @override
  ConsumerState<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends ConsumerState<CameraCapturePage>
    with WidgetsBindingObserver {
  late final ScanImageProcessor _imageProcessor;
  CameraService? _cameraService;
  XFile? _capturedImage;
  ScanImageQualityReport? _qualityReport;
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isInspecting = false;
  bool _isFlashEnabled = false;
  bool _isPermissionPermanentlyDenied = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _imageProcessor = const ScanImageProcessor();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeCamera();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraService = _cameraService;
    if (cameraService == null) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      cameraService.disposeCamera();
      return;
    }
    if (state == AppLifecycleState.resumed && _capturedImage == null) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final cameraService = ref.read(cameraServiceProvider);
    _cameraService = cameraService;
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _isPermissionPermanentlyDenied = false;
    });

    try {
      final permission = await cameraService.requestPermissionStatus();
      if (!permission.isGranted) {
        _setPermissionError(permission);
        return;
      }

      await cameraService.initializeCamera();
      await cameraService.openCamera();

      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _errorMessage = null;
      });
    } catch (_) {
      _setError('Unable to open the camera on this device.');
    }
  }

  void _setPermissionError(PermissionStatus status) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isPermissionPermanentlyDenied = status.isPermanentlyDenied;
      _errorMessage = status.isPermanentlyDenied
          ? 'Camera permission is turned off. Enable it in Settings to capture scans.'
          : 'Camera permission is required to capture scans.';
      _isInitializing = false;
    });
  }

  void _setError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = message;
      _isInitializing = false;
      _isCapturing = false;
      _isInspecting = false;
    });
  }

  Future<void> _captureImage() async {
    final cameraService = _cameraService;
    if (cameraService == null || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });

    try {
      final image = await cameraService.captureImage();
      if (!mounted) {
        return;
      }
      setState(() {
        _capturedImage = image;
        _isCapturing = false;
        _isInspecting = true;
      });
      final report = await _imageProcessor.inspect(image.path);
      if (!mounted) {
        return;
      }
      setState(() {
        _qualityReport = report;
        _isInspecting = false;
      });
    } catch (_) {
      _setError('Unable to capture image. Please try again.');
    }
  }

  Future<void> _toggleFlash() async {
    final cameraService = _cameraService;
    if (cameraService == null || !cameraService.canToggleFlash) {
      return;
    }

    final nextMode = _isFlashEnabled ? FlashMode.off : FlashMode.torch;
    try {
      await cameraService.setFlashMode(nextMode);
      if (!mounted) {
        return;
      }
      setState(() {
        _isFlashEnabled = !_isFlashEnabled;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Flash is not available')));
    }
  }

  void _retake() {
    setState(() {
      _capturedImage = null;
      _qualityReport = null;
      _errorMessage = null;
      _isInspecting = false;
      _isCapturing = false;
    });
  }

  void _usePhoto(ImageEnhancementPreviewResult result) {
    final image = _capturedImage;
    if (image == null) {
      return;
    }
    Navigator.of(context).pop(
      CameraCaptureFlowResult.image(
        result.activeImage,
        originalImage: result.originalImage,
        enhancementPreset: result.preset,
        enhancementMetadata: result.metadata,
      ),
    );
  }

  void _openGalleryFallback() {
    Navigator.of(context).pop(const CameraCaptureFlowResult.galleryFallback());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService?.disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capturedImage = _capturedImage;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: capturedImage == null
            ? _CameraLiveView(
                cameraService: _cameraService,
                isInitializing: _isInitializing,
                isCapturing: _isCapturing,
                isFlashEnabled: _isFlashEnabled,
                errorMessage: _errorMessage,
                isPermissionPermanentlyDenied: _isPermissionPermanentlyDenied,
                roleTitle: _roleTitle(widget.imageRole),
                guidanceText: _guidanceText(widget.imageRole),
                onBack: () => Navigator.of(context).maybePop(),
                onCapture: _captureImage,
                onFlash: _toggleFlash,
                onGallery: _openGalleryFallback,
                onRetryPermission: _initializeCamera,
                onOpenSettings: _cameraService?.openSettings,
              )
            : ImageEnhancementPreviewSurface(
                image: capturedImage,
                initialPreset: ImageEnhancementPreset.original,
                title: _qualityTitle(_qualityReport),
                subtitle: _qualitySubtitle(_qualityReport, _isInspecting),
                onRetake: _retake,
                onCancel: () => Navigator.of(context).pop(),
                onUsePhoto: _usePhoto,
              ),
      ),
    );
  }

  String _qualityTitle(ScanImageQualityReport? report) {
    final warnings = report?.warnings ?? const <ScanImageQualityWarning>[];
    return warnings.isEmpty ? 'Review photo' : 'Quality warning';
  }

  String _qualitySubtitle(ScanImageQualityReport? report, bool isInspecting) {
    if (isInspecting) {
      return 'Checking image quality...';
    }
    final warnings = report?.warnings ?? const <ScanImageQualityWarning>[];
    if (warnings.isEmpty) {
      return 'Choose the clearest version for analysis.';
    }
    return warnings.map((warning) => warning.message).join(' ');
  }
}

class _CameraLiveView extends StatelessWidget {
  const _CameraLiveView({
    required this.cameraService,
    required this.isInitializing,
    required this.isCapturing,
    required this.isFlashEnabled,
    required this.errorMessage,
    required this.isPermissionPermanentlyDenied,
    required this.roleTitle,
    required this.guidanceText,
    required this.onBack,
    required this.onCapture,
    required this.onFlash,
    required this.onGallery,
    required this.onRetryPermission,
    required this.onOpenSettings,
  });

  final CameraService? cameraService;
  final bool isInitializing;
  final bool isCapturing;
  final bool isFlashEnabled;
  final String? errorMessage;
  final bool isPermissionPermanentlyDenied;
  final String roleTitle;
  final String guidanceText;
  final VoidCallback onBack;
  final VoidCallback onCapture;
  final VoidCallback onFlash;
  final VoidCallback onGallery;
  final VoidCallback onRetryPermission;
  final Future<bool> Function()? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final controller = cameraService?.controller;
    final isReady = controller != null && controller.value.isInitialized;

    return Stack(
      children: [
        Positioned.fill(
          child: _CameraPreviewBody(
            controller: isReady ? controller : null,
            isInitializing: isInitializing,
            errorMessage: errorMessage,
            isPermissionPermanentlyDenied: isPermissionPermanentlyDenied,
            onRetryPermission: onRetryPermission,
            onOpenSettings: onOpenSettings,
          ),
        ),
        if (isReady) const Positioned.fill(child: _GuideOverlayFrame()),
        Positioned(
          top: 12,
          left: 12,
          child: IconButton.filled(
            onPressed: onBack,
            icon: const Icon(Icons.close),
            tooltip: 'Close camera',
          ),
        ),
        if (isReady && (cameraService?.canToggleFlash ?? false))
          Positioned(
            top: 12,
            right: 12,
            child: IconButton.filled(
              onPressed: onFlash,
              icon: Icon(isFlashEnabled ? Icons.flash_on : Icons.flash_off),
              tooltip: 'Toggle flash',
            ),
          ),
        Positioned(
          left: 24,
          right: 24,
          top: 72,
          child: _CameraGuidanceCard(title: roleTitle, body: guidanceText),
        ),
        if (isReady)
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  tooltip: 'Choose from gallery',
                ),
                Expanded(
                  child: Center(
                    child: _CaptureButton(
                      isCapturing: isCapturing,
                      onPressed: onCapture,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
      ],
    );
  }
}

class _CameraPreviewBody extends StatelessWidget {
  const _CameraPreviewBody({
    required this.controller,
    required this.isInitializing,
    required this.errorMessage,
    required this.isPermissionPermanentlyDenied,
    required this.onRetryPermission,
    required this.onOpenSettings,
  });

  final CameraController? controller;
  final bool isInitializing;
  final String? errorMessage;
  final bool isPermissionPermanentlyDenied;
  final VoidCallback onRetryPermission;
  final Future<bool> Function()? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final activeController = controller;
    if (activeController != null) {
      return Center(
        child: CameraPreview(activeController, child: const SizedBox.expand()),
      );
    }

    if (isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_camera_outlined,
              color: Colors.white,
              size: 42,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Camera is unavailable.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: isPermissionPermanentlyDenied
                  ? () => onOpenSettings?.call()
                  : onRetryPermission,
              child: Text(
                isPermissionPermanentlyDenied ? 'Open Settings' : 'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideOverlayFrame extends StatelessWidget {
  const _GuideOverlayFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.82,
          heightFactor: 0.48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraGuidanceCard extends StatelessWidget {
  const _CameraGuidanceCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.isCapturing, required this.onPressed});

  final bool isCapturing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCapturing ? null : onPressed,
      child: Container(
        width: 76,
        height: 76,
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
            child: isCapturing
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

String _roleTitle(String role) {
  return switch (_normalizeRole(role)) {
    'back' => 'Capture back / reverse',
    'closeup' => 'Capture close-up',
    _ => 'Capture front / obverse',
  };
}

String _guidanceText(String role) {
  return switch (_normalizeRole(role)) {
    'back' => 'Flip the item and capture the reverse side.',
    'closeup' => 'Move closer to the year, mark, damage, label, or serial.',
    _ => 'Place the item clearly inside the guide.',
  };
}

String _normalizeRole(String role) {
  final normalized = role.trim().toLowerCase();
  return switch (normalized) {
    'reverse' || 'back' => 'back',
    'close-up' || 'closeup' || 'detail' || 'serial' || 'damage' => 'closeup',
    _ => 'front',
  };
}
