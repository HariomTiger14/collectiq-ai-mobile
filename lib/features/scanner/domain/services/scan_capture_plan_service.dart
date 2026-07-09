import 'package:collectiq_ai/features/scanner/domain/entities/captured_scan_image.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_plan.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';

enum CollectibleCategory {
  toyCar,
  tradingCard,
  coin,
  generic;

  String get id {
    return switch (this) {
      CollectibleCategory.toyCar => 'toy_car',
      CollectibleCategory.tradingCard => 'trading_card',
      CollectibleCategory.coin => 'coin',
      CollectibleCategory.generic => 'generic',
    };
  }

  String get title {
    return switch (this) {
      CollectibleCategory.toyCar => 'Toy car',
      CollectibleCategory.tradingCard => 'Trading card',
      CollectibleCategory.coin => 'Coin',
      CollectibleCategory.generic => 'Generic',
    };
  }

  static CollectibleCategory fromId(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return switch (normalized) {
      'toy_car' ||
      'toycar' ||
      'die_cast' ||
      'diecast' ||
      'hot_wheels' => CollectibleCategory.toyCar,
      'trading_card' || 'card' || 'cards' => CollectibleCategory.tradingCard,
      'coin' || 'coins' => CollectibleCategory.coin,
      _ => CollectibleCategory.generic,
    };
  }
}

class ScanCapturePlanService {
  const ScanCapturePlanService();

  ScanCapturePlan buildPlan(
    ScanGoal goal,
    CollectibleCategory? category,
    List<CapturedScanImage> images,
  ) {
    final effectiveCategory = category ?? CollectibleCategory.generic;
    final requiredRoles = _requiredRoles(goal, effectiveCategory);
    final optionalRoles = _optionalRoles(goal, effectiveCategory);
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

  List<ScanCaptureRole> _requiredRoles(
    ScanGoal goal,
    CollectibleCategory category,
  ) {
    return const [ScanCaptureRole.front];
  }

  List<ScanCaptureRole> _optionalRoles(
    ScanGoal goal,
    CollectibleCategory category,
  ) {
    return switch ((goal, category)) {
      (ScanGoal.identifyValue, CollectibleCategory.toyCar) => const [
        ScanCaptureRole.back,
        ScanCaptureRole.baseUnderside,
        ScanCaptureRole.barcode,
      ],
      (ScanGoal.identifyValue, CollectibleCategory.tradingCard) => const [
        ScanCaptureRole.back,
        ScanCaptureRole.surfaceGlare,
      ],
      (ScanGoal.identifyValue, CollectibleCategory.coin) => const [
        ScanCaptureRole.edge,
        ScanCaptureRole.dateMint,
      ],
      (ScanGoal.identifyValue, CollectibleCategory.generic) => const [
        ScanCaptureRole.back,
        ScanCaptureRole.closeUp,
      ],
      (ScanGoal.detailedAnalysis, CollectibleCategory.toyCar) => const [
        ScanCaptureRole.back,
        ScanCaptureRole.leftSide,
        ScanCaptureRole.rightSide,
        ScanCaptureRole.baseUnderside,
        ScanCaptureRole.top,
        ScanCaptureRole.barcode,
      ],
      (ScanGoal.detailedAnalysis, CollectibleCategory.tradingCard) => const [
        ScanCaptureRole.back,
        ScanCaptureRole.cornerCondition,
        ScanCaptureRole.surfaceGlare,
      ],
      (ScanGoal.detailedAnalysis, CollectibleCategory.coin) => const [
        ScanCaptureRole.back,
        ScanCaptureRole.edge,
        ScanCaptureRole.dateMint,
        ScanCaptureRole.angledReflective,
      ],
      (ScanGoal.detailedAnalysis, CollectibleCategory.generic) => const [
        ScanCaptureRole.back,
        ScanCaptureRole.closeUp,
        ScanCaptureRole.damageDetail,
        ScanCaptureRole.angledReflective,
      ],
      (ScanGoal.prepareForSale, CollectibleCategory.toyCar) => const [
        ScanCaptureRole.back,
        ScanCaptureRole.leftSide,
        ScanCaptureRole.rightSide,
        ScanCaptureRole.top,
        ScanCaptureRole.baseUnderside,
        ScanCaptureRole.barcode,
        ScanCaptureRole.damageDetail,
      ],
      (ScanGoal.prepareForSale, CollectibleCategory.tradingCard) => const [
        ScanCaptureRole.back,
        ScanCaptureRole.cornerCondition,
        ScanCaptureRole.surfaceGlare,
        ScanCaptureRole.damageDetail,
      ],
      (ScanGoal.prepareForSale, CollectibleCategory.coin) => const [
        ScanCaptureRole.back,
        ScanCaptureRole.edge,
        ScanCaptureRole.dateMint,
        ScanCaptureRole.angledReflective,
      ],
      (ScanGoal.prepareForSale, CollectibleCategory.generic) => const [
        ScanCaptureRole.back,
        ScanCaptureRole.closeUp,
        ScanCaptureRole.damageDetail,
        ScanCaptureRole.serialOrMark,
        ScanCaptureRole.angledReflective,
      ],
    };
  }

  String _guidance(ScanGoal goal, ScanCaptureRole? nextRole) {
    if (nextRole == null) {
      return switch (goal) {
        ScanGoal.prepareForSale =>
          'Minimum listing views are ready. Add optional details if needed.',
        _ => 'Ready to analyze. More photos are optional.',
      };
    }
    if (nextRole == ScanCaptureRole.baseUnderside) {
      return 'Next: Capture underside/base';
    }
    if (nextRole == ScanCaptureRole.barcode) {
      return 'Next: Capture packaging barcode';
    }
    if (nextRole == ScanCaptureRole.leftSide ||
        nextRole == ScanCaptureRole.rightSide) {
      return 'Recommended: side view for better identification';
    }
    if (goal == ScanGoal.prepareForSale && nextRole == ScanCaptureRole.back) {
      return 'Capture the back clearly for listing condition notes.';
    }
    return nextRole.guidance;
  }
}
