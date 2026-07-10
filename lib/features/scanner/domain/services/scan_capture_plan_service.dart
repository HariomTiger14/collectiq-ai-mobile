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
    return switch ((goal, category)) {
      (ScanGoal.identifyValue, CollectibleCategory.tradingCard) => const [
        ScanCaptureRole.front,
      ],
      (ScanGoal.identifyValue, CollectibleCategory.coin) => const [
        ScanCaptureRole.front,
        ScanCaptureRole.back,
      ],
      (ScanGoal.identifyValue, _) => const [ScanCaptureRole.front],
      (ScanGoal.detailedAnalysis, CollectibleCategory.toyCar) => const [
        ScanCaptureRole.front,
        ScanCaptureRole.back,
        ScanCaptureRole.leftSide,
        ScanCaptureRole.rightSide,
        ScanCaptureRole.baseUnderside,
      ],
      (ScanGoal.detailedAnalysis, CollectibleCategory.tradingCard) => const [
        ScanCaptureRole.front,
        ScanCaptureRole.back,
        ScanCaptureRole.cornerCondition,
      ],
      (ScanGoal.detailedAnalysis, CollectibleCategory.coin) => const [
        ScanCaptureRole.front,
        ScanCaptureRole.back,
        ScanCaptureRole.edge,
        ScanCaptureRole.dateMint,
      ],
      (ScanGoal.detailedAnalysis, CollectibleCategory.generic) => const [
        ScanCaptureRole.front,
        ScanCaptureRole.back,
        ScanCaptureRole.closeUp,
      ],
      (ScanGoal.prepareForSale, CollectibleCategory.toyCar) => const [
        ScanCaptureRole.front,
        ScanCaptureRole.back,
        ScanCaptureRole.leftSide,
        ScanCaptureRole.rightSide,
        ScanCaptureRole.top,
        ScanCaptureRole.baseUnderside,
      ],
      (ScanGoal.prepareForSale, CollectibleCategory.tradingCard) => const [
        ScanCaptureRole.front,
        ScanCaptureRole.back,
        ScanCaptureRole.cornerCondition,
        ScanCaptureRole.surfaceGlare,
      ],
      (ScanGoal.prepareForSale, CollectibleCategory.coin) => const [
        ScanCaptureRole.front,
        ScanCaptureRole.back,
        ScanCaptureRole.edge,
        ScanCaptureRole.dateMint,
      ],
      (ScanGoal.prepareForSale, CollectibleCategory.generic) => const [
        ScanCaptureRole.front,
        ScanCaptureRole.back,
        ScanCaptureRole.closeUp,
        ScanCaptureRole.damageDetail,
      ],
    };
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
        ScanCaptureRole.top,
        ScanCaptureRole.barcode,
      ],
      (ScanGoal.detailedAnalysis, CollectibleCategory.tradingCard) => const [
        ScanCaptureRole.surfaceGlare,
      ],
      (ScanGoal.detailedAnalysis, CollectibleCategory.coin) => const [
        ScanCaptureRole.angledReflective,
      ],
      (ScanGoal.detailedAnalysis, CollectibleCategory.generic) => const [
        ScanCaptureRole.damageDetail,
        ScanCaptureRole.angledReflective,
      ],
      (ScanGoal.prepareForSale, CollectibleCategory.toyCar) => const [
        ScanCaptureRole.barcode,
        ScanCaptureRole.damageDetail,
      ],
      (ScanGoal.prepareForSale, CollectibleCategory.tradingCard) => const [
        ScanCaptureRole.damageDetail,
      ],
      (ScanGoal.prepareForSale, CollectibleCategory.coin) => const [
        ScanCaptureRole.angledReflective,
      ],
      (ScanGoal.prepareForSale, CollectibleCategory.generic) => const [
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
        _ => 'Minimum photos are ready for analysis.',
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
