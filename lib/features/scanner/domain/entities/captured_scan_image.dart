import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';

class CapturedScanImage {
  const CapturedScanImage({
    required this.path,
    required this.role,
    required this.source,
    this.originalPath,
    this.enhancementPreset = 'original',
    this.qualityMetadata = const {},
  });

  final String path;
  final ScanCaptureRole role;
  final String source;
  final String? originalPath;
  final String enhancementPreset;
  final Map<String, Object?> qualityMetadata;
}
