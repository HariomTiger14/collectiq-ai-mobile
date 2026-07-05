import 'package:camera/camera.dart';
import 'package:collectiq_ai/features/scanner/services/camera_service.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen camera capture experience for scanner image acquisition.
class CameraCapturePage extends ConsumerStatefulWidget {
  /// Creates the camera capture page.
  const CameraCapturePage({super.key});

  @override
  ConsumerState<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends ConsumerState<CameraCapturePage> {
  CameraService? _cameraService;
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isFlashEnabled = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _initializeCamera();
    });
  }

  Future<void> _initializeCamera() async {
    final cameraService = ref.read(cameraServiceProvider);
    _cameraService = cameraService;

    try {
      final hasPermission = await cameraService.requestPermissions();
      if (!hasPermission) {
        _setError('Camera permission is required to scan collectibles.');
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
      _setError('Unable to open the camera.');
    }
  }

  void _setError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = message;
      _isInitializing = false;
    });
  }

  Future<void> _captureImage() async {
    final cameraService = _cameraService;
    if (cameraService == null || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await cameraService.captureImage();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(image.path);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCapturing = false;
        _errorMessage = 'Unable to capture image.';
      });
    }
  }

  Future<void> _toggleFlash() async {
    final cameraService = _cameraService;
    if (cameraService == null) {
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

  @override
  void dispose() {
    _cameraService?.disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraService?.controller;
    final isReady = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _CameraPreviewBody(
                controller: isReady ? controller : null,
                isInitializing: _isInitializing,
                errorMessage: _errorMessage,
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton.filled(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
                tooltip: 'Close camera',
              ),
            ),
            if (isReady)
              Positioned(
                top: 12,
                right: 12,
                child: IconButton.filled(
                  onPressed: _toggleFlash,
                  icon: Icon(
                    _isFlashEnabled ? Icons.flash_on : Icons.flash_off,
                  ),
                  tooltip: 'Toggle flash',
                ),
              ),
            if (isReady)
              Positioned(
                left: 0,
                right: 0,
                bottom: 32,
                child: Center(
                  child: _CaptureButton(
                    isCapturing: _isCapturing,
                    onPressed: _captureImage,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CameraPreviewBody extends StatelessWidget {
  const _CameraPreviewBody({
    required this.controller,
    required this.isInitializing,
    required this.errorMessage,
  });

  final CameraController? controller;
  final bool isInitializing;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final activeController = controller;
    if (activeController != null) {
      return Center(child: CameraPreview(activeController));
    }

    if (isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          errorMessage ?? 'Camera is unavailable.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.white),
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
