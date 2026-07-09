import 'package:collectiq_ai/features/scanner/domain/entities/captured_scan_image.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_capture_plan_service.dart';
import 'package:collectiq_ai/features/scanner/domain/services/smart_scan_guidance_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = SmartScanGuidanceService();

  test('no-photo guidance says start with front/package', () {
    final guidance = service.buildGuidance(
      category: CollectibleCategory.toyCar,
      images: const [],
      goal: ScanGoal.identifyValue,
    );

    expect(guidance.canAnalyze, isFalse);
    expect(guidance.headline, 'Start with the front');
    expect(guidance.guidance, contains('front or package'));
    expect(guidance.recommendedNextRole, ScanCaptureRole.front);
  });

  test('one front photo is enough to identify and suggests another photo', () {
    final guidance = service.buildGuidance(
      category: CollectibleCategory.generic,
      images: const [_frontImage],
      goal: ScanGoal.identifyValue,
    );

    expect(guidance.canAnalyze, isTrue);
    expect(guidance.headline, 'Enough to identify');
    expect(guidance.guidance, contains('improve'));
    expect(guidance.recommendedNextRole, ScanCaptureRole.back);
  });

  test('front and back says ready to analyze', () {
    final guidance = service.buildGuidance(
      category: CollectibleCategory.generic,
      images: const [_frontImage, _backImage],
      goal: ScanGoal.identifyValue,
    );

    expect(guidance.canAnalyze, isTrue);
    expect(guidance.headline, 'Ready to analyze');
    expect(guidance.guidance, contains('optional'));
  });

  test('toy car recommends base or underside after front and back', () {
    final guidance = service.buildGuidance(
      category: CollectibleCategory.toyCar,
      images: const [_frontImage, _backImage],
      goal: ScanGoal.identifyValue,
    );

    expect(guidance.recommendedNextRole, ScanCaptureRole.baseUnderside);
  });

  test('card recommends back then corner', () {
    final first = service.buildGuidance(
      category: CollectibleCategory.tradingCard,
      images: const [_frontImage],
      goal: ScanGoal.identifyValue,
    );
    final second = service.buildGuidance(
      category: CollectibleCategory.tradingCard,
      images: const [_frontImage, _backImage],
      goal: ScanGoal.identifyValue,
    );

    expect(first.recommendedNextRole, ScanCaptureRole.back);
    expect(second.recommendedNextRole, ScanCaptureRole.cornerCondition);
  });

  test('coin recommends reverse then edge', () {
    final first = service.buildGuidance(
      category: CollectibleCategory.coin,
      images: const [_frontImage],
      goal: ScanGoal.identifyValue,
    );
    final second = service.buildGuidance(
      category: CollectibleCategory.coin,
      images: const [_frontImage, _backImage],
      goal: ScanGoal.identifyValue,
    );

    expect(first.recommendedNextRole, ScanCaptureRole.back);
    expect(second.recommendedNextRole, ScanCaptureRole.edge);
  });

  test('optional missing roles do not block analyze', () {
    final plan = const ScanCapturePlanService().buildPlan(
      ScanGoal.detailedAnalysis,
      CollectibleCategory.toyCar,
      const [_frontImage],
    );
    final guidance = service.buildGuidance(
      category: CollectibleCategory.toyCar,
      images: const [_frontImage],
      goal: ScanGoal.detailedAnalysis,
    );

    expect(plan.isMinimumReadyForAnalyze, isTrue);
    expect(plan.optionalRoles, contains(ScanCaptureRole.baseUnderside));
    expect(guidance.canAnalyze, isTrue);
    expect(guidance.guidance.toLowerCase(), isNot(contains('required')));
  });
}

const _frontImage = CapturedScanImage(
  path: '/tmp/front.jpg',
  role: ScanCaptureRole.front,
  source: 'camera',
);

const _backImage = CapturedScanImage(
  path: '/tmp/back.jpg',
  role: ScanCaptureRole.back,
  source: 'camera',
);
