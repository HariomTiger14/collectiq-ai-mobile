import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';

class ScanCapturePlan {
  const ScanCapturePlan({
    required this.requiredRoles,
    required this.optionalRoles,
    required this.completionPercentage,
    required this.isMinimumReadyForAnalyze,
    required this.userGuidance,
    this.nextRecommendedRole,
  });

  final List<ScanCaptureRole> requiredRoles;
  final List<ScanCaptureRole> optionalRoles;
  final ScanCaptureRole? nextRecommendedRole;
  final double completionPercentage;
  final bool isMinimumReadyForAnalyze;
  final String userGuidance;
}
