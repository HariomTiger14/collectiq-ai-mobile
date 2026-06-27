import 'package:collectiq_ai/features/scanner/services/camera_service.dart';
import 'package:collectiq_ai/features/scanner/services/gallery_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the scanner camera service.
final cameraServiceProvider = Provider<CameraService>((ref) {
  final service = CameraService();
  ref.onDispose(service.disposeCamera);
  return service;
});

/// Provides the scanner gallery service.
final galleryServiceProvider = Provider<GalleryService>((ref) {
  return GalleryService();
});
