import 'package:collectiq_ai/features/scanner/domain/entities/captured_scan_image.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_plan.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';

enum CollectibleCategory { unknown }

class ScanCapturePlanService {
  const ScanCapturePlanService();

  ScanCapturePlan buildPlan(
    ScanGoal goal,
    CollectibleCategory? category,
    List<CapturedScanImage> images,
  ) {
    final requiredRoles = _requiredRoles(goal);
    final optionalRoles = _optionalRoles(goal);
    final capturedRoles = images.map((image) => image.role).toSet();
    final nextRequired = requiredRoles
        .where((role) => !capturedRoles.contains(role))
        .firstOrNull;
    final nextOptional = optionalRoles
        .where((role) => !capturedRoles.contains(role))
        .firstOrNull;
    final completedRequired = requiredRoles
        .where((role) => capturedRoles.contains(role))
        .length;
    final completionPercentage = requiredRoles.isEmpty
        ? 1.0
        : completedRequired / requiredRoles.length;

    return ScanCapturePlan(
      requiredRoles: requiredRoles,
      optionalRoles: optionalRoles,
      nextRecommendedRole: nextRequired ?? nextOptional,
      completionPercentage: completionPercentage.clamp(0, 1).toDouble(),
      isMinimumReadyForAnalyze: nextRequired == null,
      userGuidance: _guidance(goal, nextRequired ?? nextOptional),
    );
  }

  List<ScanCaptureRole> _requiredRoles(ScanGoal goal) {
    return switch (goal) {
      ScanGoal.identifyValue => const [ScanCaptureRole.front],
      ScanGoal.detailedAnalysis => const [
        ScanCaptureRole.front,
        ScanCaptureRole.back,
        ScanCaptureRole.closeUp,
      ],
      ScanGoal.prepareForSale => const [
        ScanCaptureRole.front,
        ScanCaptureRole.back,
        ScanCaptureRole.side,
      ],
    };
  }

  List<ScanCaptureRole> _optionalRoles(ScanGoal goal) {
    return switch (goal) {
      ScanGoal.identifyValue => const [
        ScanCaptureRole.back,
        ScanCaptureRole.closeUp,
      ],
      ScanGoal.detailedAnalysis => const [
        ScanCaptureRole.edge,
        ScanCaptureRole.serialOrMark,
        ScanCaptureRole.damageDetail,
        ScanCaptureRole.angledReflective,
      ],
      ScanGoal.prepareForSale => const [
        ScanCaptureRole.top,
        ScanCaptureRole.bottom,
        ScanCaptureRole.damageDetail,
        ScanCaptureRole.angledReflective,
        ScanCaptureRole.serialOrMark,
      ],
    };
  }

  String _guidance(ScanGoal goal, ScanCaptureRole? nextRole) {
    if (nextRole == null) {
      return switch (goal) {
        ScanGoal.prepareForSale =>
          'Minimum listing views are ready. Add optional details if needed.',
        _ => 'Minimum photos are ready for analysis.',
      };
    }
    if (goal == ScanGoal.prepareForSale && nextRole == ScanCaptureRole.side) {
      return 'Add a side view so buyers can judge shape and thickness.';
    }
    return nextRole.guidance;
  }
}
