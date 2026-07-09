import 'package:collectiq_ai/features/scanner/domain/entities/captured_scan_image.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_capture_plan_service.dart';

enum SmartScanReadinessState {
  notStarted,
  needsFirstPhoto,
  identifiable,
  valuationCanImprove,
  readyToAnalyze,
}

class SmartScanGuidance {
  const SmartScanGuidance({
    required this.readinessState,
    required this.headline,
    required this.guidance,
    required this.canAnalyze,
    this.recommendedNextRole,
    this.softWarning,
  });

  final SmartScanReadinessState readinessState;
  final String headline;
  final String guidance;
  final ScanCaptureRole? recommendedNextRole;
  final bool canAnalyze;
  final String? softWarning;
}

class SmartScanGuidanceService {
  const SmartScanGuidanceService();

  SmartScanGuidance buildGuidance({
    required CollectibleCategory category,
    required List<CapturedScanImage> images,
    required ScanGoal goal,
    String? selectedCategoryLabel,
  }) {
    final roleCounts = <ScanCaptureRole, int>{};
    for (final image in images) {
      roleCounts[image.role] = (roleCounts[image.role] ?? 0) + 1;
    }
    final capturedRoles = roleCounts.keys.toSet();
    final hasFront = capturedRoles.contains(ScanCaptureRole.front);
    final hasBack = capturedRoles.contains(ScanCaptureRole.back);
    final warning = _softQualityWarning(images);

    if (images.isEmpty) {
      return const SmartScanGuidance(
        readinessState: SmartScanReadinessState.needsFirstPhoto,
        headline: 'Start with the front',
        guidance:
            'Capture the front or package so PackLox can identify the item.',
        recommendedNextRole: ScanCaptureRole.front,
        canAnalyze: false,
      );
    }

    final recommendation = _nextRoleFor(
      category: category,
      goal: goal,
      capturedRoles: capturedRoles,
    );

    if (!hasFront) {
      return SmartScanGuidance(
        readinessState: SmartScanReadinessState.identifiable,
        headline: 'Enough to identify',
        guidance:
            'A front/package photo can improve the match, but this scan can be analyzed now.',
        recommendedNextRole: ScanCaptureRole.front,
        canAnalyze: true,
        softWarning: warning,
      );
    }

    if (hasFront && hasBack) {
      return SmartScanGuidance(
        readinessState: SmartScanReadinessState.readyToAnalyze,
        headline: 'Ready to analyze',
        guidance:
            'More detail photos are optional and can improve condition confidence.',
        recommendedNextRole: recommendation,
        canAnalyze: true,
        softWarning: warning,
      );
    }

    return SmartScanGuidance(
      readinessState: SmartScanReadinessState.valuationCanImprove,
      headline: 'Enough to identify',
      guidance: _guidanceForRecommendation(category, recommendation),
      recommendedNextRole: recommendation,
      canAnalyze: true,
      softWarning: warning,
    );
  }

  ScanCaptureRole? _nextRoleFor({
    required CollectibleCategory category,
    required ScanGoal goal,
    required Set<ScanCaptureRole> capturedRoles,
  }) {
    final roles = switch (category) {
      CollectibleCategory.toyCar => const [
        ScanCaptureRole.back,
        ScanCaptureRole.baseUnderside,
        ScanCaptureRole.barcode,
        ScanCaptureRole.closeUp,
      ],
      CollectibleCategory.tradingCard => const [
        ScanCaptureRole.back,
        ScanCaptureRole.cornerCondition,
        ScanCaptureRole.surfaceGlare,
      ],
      CollectibleCategory.coin => const [
        ScanCaptureRole.back,
        ScanCaptureRole.edge,
        ScanCaptureRole.dateMint,
      ],
      CollectibleCategory.generic => const [
        ScanCaptureRole.back,
        ScanCaptureRole.closeUp,
        ScanCaptureRole.damageDetail,
      ],
    };

    final detailedExtra = goal == ScanGoal.identifyValue
        ? roles
        : [...roles, ScanCaptureRole.angledReflective];
    for (final role in detailedExtra) {
      if (!capturedRoles.contains(role)) {
        return role;
      }
    }
    return null;
  }

  String _guidanceForRecommendation(
    CollectibleCategory category,
    ScanCaptureRole? role,
  ) {
    if (role == null) {
      return 'Ready when you are. Extra photos are optional.';
    }
    if (category == CollectibleCategory.toyCar) {
      if (role == ScanCaptureRole.baseUnderside) {
        return 'Capture the base/underside to identify production code.';
      }
      if (role == ScanCaptureRole.back) {
        return 'Add a back/package photo to improve valuation accuracy.';
      }
      if (role == ScanCaptureRole.barcode) {
        return 'Add a barcode or logo photo to improve valuation.';
      }
    }
    if (category == CollectibleCategory.tradingCard) {
      if (role == ScanCaptureRole.back) {
        return 'Add the back to improve set and authenticity details.';
      }
      if (role == ScanCaptureRole.cornerCondition) {
        return 'One corner angle can improve condition confidence.';
      }
    }
    if (category == CollectibleCategory.coin) {
      if (role == ScanCaptureRole.back) {
        return 'Add the reverse to improve identification confidence.';
      }
      if (role == ScanCaptureRole.edge) {
        return 'Capture the edge to improve variety and condition confidence.';
      }
    }
    return 'One more angle can improve condition confidence.';
  }

  String? _softQualityWarning(List<CapturedScanImage> images) {
    for (final image in images.reversed) {
      final warning = image.qualityMetadata['qualityWarnings'];
      if (warning is Iterable) {
        final label = warning.whereType<String>().firstOrNull;
        if (label != null && label.trim().isNotEmpty) {
          return label.trim();
        }
      }
      if (image.qualityMetadata['severity'] == 'WARNING') {
        return 'Image quality could be better';
      }
    }
    return null;
  }
}
