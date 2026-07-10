import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_capture_plan_service.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/capture_role_guide.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/capture_workspace.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/scan_goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scanner goal and role guide widgets render', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ScanGoalCard(
                goal: ScanGoal.identifyValue,
                selected: true,
                onTap: () => tapped = true,
              ),
              const CaptureRoleGuide(role: ScanCaptureRole.angledReflective),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Identify & Value'), findsOneWidget);
    expect(find.text('Fast ID and valuation'), findsOneWidget);
    expect(find.textContaining('Tilt slightly'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('scan-goal-identifyValue')));
    expect(tapped, isTrue);
  });

  testWidgets('ScanImageFilmstrip renders multiple captured images', (
    WidgetTester tester,
  ) async {
    final slots = [
      _slot(role: ScanCaptureRole.front, path: 'sample://front'),
      _slot(role: ScanCaptureRole.back, path: 'sample://back'),
      _slot(
        role: ScanCaptureRole.closeUp,
        path: 'sample://close',
        qualityMetadata: const {
          'severity': 'WARNING',
          'userMessage': 'Image looks slightly blurry.',
        },
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanImageFilmstrip(
            images: slots,
            selectedPath: 'sample://back',
            canAddPhoto: true,
            onTapImage: (_) {},
            onRetake: (_) {},
            onDelete: (_) {},
            onAddPhoto: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('filmstrip-front')), findsOneWidget);
    expect(find.byKey(const ValueKey('filmstrip-back')), findsOneWidget);
    expect(find.byKey(const ValueKey('filmstrip-closeup')), findsOneWidget);
    expect(find.byKey(const ValueKey('filmstrip-add-photo')), findsOneWidget);
    expect(find.text('Warning'), findsOneWidget);
    expect(find.text('Accepted'), findsNWidgets(2));
  });

  testWidgets('CaptureRoleCard renders missing captured and warning states', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CaptureRoleCard(
                role: ScanCaptureRole.front,
                requiredRole: true,
                isBusy: false,
                onCapture: () {},
                onGallery: () {},
                onPreview: () {},
                onDelete: () {},
              ),
              CaptureRoleCard(
                role: ScanCaptureRole.back,
                requiredRole: true,
                slot: _slot(role: ScanCaptureRole.back),
                isBusy: false,
                onCapture: () {},
                onGallery: () {},
                onPreview: () {},
                onDelete: () {},
              ),
              CaptureRoleCard(
                role: ScanCaptureRole.closeUp,
                requiredRole: false,
                slot: _slot(
                  role: ScanCaptureRole.closeUp,
                  qualityMetadata: const {
                    'severity': 'WARNING',
                    'userMessage': 'Lighting appears low.',
                  },
                ),
                isBusy: false,
                onCapture: () {},
                onGallery: () {},
                onPreview: () {},
                onDelete: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Missing'), findsOneWidget);
    expect(find.text('Captured'), findsOneWidget);
    expect(find.text('Warning'), findsOneWidget);
    expect(find.text('Required'), findsNWidgets(2));
    expect(find.text('Optional'), findsOneWidget);
  });

  testWidgets(
    'CaptureWorkspace disables analyze until required roles are done',
    (WidgetTester tester) async {
      const service = ScanCapturePlanService();
      final emptyPlan = service.buildPlan(
        ScanGoal.prepareForSale,
        null,
        const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CaptureWorkspace(
                goal: ScanGoal.prepareForSale,
                plan: emptyPlan,
                slots: const {},
                isBusy: false,
                hasResult: false,
                onPrimaryCapture: () {},
                onAnalyze: () {},
                onCamera: (_) async {},
                onGallery: (_) async {},
                onPreview: (_) {},
                onDelete: (_) {},
                onSample: () {},
                onReset: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('0 of 2 required photos captured'), findsOneWidget);
      expect(find.text('Add 2 more required photos'), findsWidgets);
      final disabledAnalyze = tester.widget<FilledButton>(
        find.byKey(const ValueKey('scan-primary-Analyze Image')),
      );
      expect(disabledAnalyze.onPressed, isNull);
    },
  );
}

ScannerPhotoSlot _slot({
  required ScanCaptureRole role,
  String? path,
  Map<String, Object?> qualityMetadata = const {
    'severity': 'PASS',
    'userMessage': 'Image accepted.',
  },
}) {
  return ScannerPhotoSlot(
    role: role.id,
    label: role.title,
    path: path ?? 'sample://${role.id}',
    source: 'sample',
    qualityMetadata: qualityMetadata,
  );
}
