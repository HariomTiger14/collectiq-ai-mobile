import 'package:collectiq_ai/features/scanner/domain/entities/captured_scan_image.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_capture_plan_service.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/capture_role_guide.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/capture_workspace.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/scan_goal_card.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/scanner_widgets.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  testWidgets('ScanImageFilmstrip renders placeholders and captured images', (
    WidgetTester tester,
  ) async {
    final slots = _slots([
      _slot(role: ScanCaptureRole.front, path: 'sample://front'),
      _slot(
        role: ScanCaptureRole.closeUp,
        path: 'sample://close',
        qualityMetadata: const {
          'severity': 'WARNING',
          'userMessage': 'Image looks slightly blurry.',
        },
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanImageFilmstrip(
            roles: const [
              ScanCaptureRole.front,
              ScanCaptureRole.back,
              ScanCaptureRole.closeUp,
              ScanCaptureRole.barcode,
            ],
            requiredRoles: const [ScanCaptureRole.front, ScanCaptureRole.back],
            recommendedRoleId: ScanCaptureRole.back.id,
            slots: slots,
            captureImages: slots.values.toList(),
            roleCounts: const {'front': 1, 'closeup': 1},
            selectedPath: 'sample://front',
            canAddPhoto: true,
            onSelectRole: (_) {},
            onCaptureRole: (_) async {},
            onTapImage: (_) {},
            onRetake: (_) {},
            onDelete: (_) {},
            onAddPhoto: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('filmstrip-photo-front-sample://front')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('filmstrip-back')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('filmstrip-photo-closeup-sample://close')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('filmstrip-add-photo')), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Captured'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('Optional'), findsOneWidget);

    final filmstripPhotoSize = tester.getSize(
      find.byKey(const ValueKey('filmstrip-photo-front-sample://front')),
    );
    expect(filmstripPhotoSize.width, lessThanOrEqualTo(96));
    expect(filmstripPhotoSize.height, lessThanOrEqualTo(132));
    expect(
      tester.getSize(find.byKey(const ValueKey('filmstrip-add-photo'))).width,
      lessThanOrEqualTo(84),
    );
  });

  testWidgets('empty filmstrip tile captures the correct role', (
    WidgetTester tester,
  ) async {
    var capturedRole = '';
    var selectedRole = '';
    final slots = _slots([_slot(role: ScanCaptureRole.front)]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanImageFilmstrip(
            roles: const [ScanCaptureRole.front, ScanCaptureRole.back],
            requiredRoles: const [ScanCaptureRole.front, ScanCaptureRole.back],
            recommendedRoleId: ScanCaptureRole.back.id,
            slots: slots,
            captureImages: slots.values.toList(),
            roleCounts: const {'front': 1},
            onSelectRole: (role) => selectedRole = role,
            onCaptureRole: (role) async => capturedRole = role,
            onTapImage: (_) {},
            onRetake: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const ValueKey('filmstrip-back')));
    await tester.tap(find.byKey(const ValueKey('filmstrip-back')));
    expect(selectedRole, ScanCaptureRole.back.id);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('filmstrip-back')),
        matching: find.byIcon(Icons.photo_camera_outlined),
      ),
    );
    expect(capturedRole, ScanCaptureRole.back.id);
  });

  testWidgets('filmstrip keeps multiple images for the same role visible', (
    WidgetTester tester,
  ) async {
    final captureImages = [
      _slot(role: ScanCaptureRole.front, path: 'sample://front-1'),
      _slot(role: ScanCaptureRole.front, path: 'sample://front-2'),
      _slot(role: ScanCaptureRole.back, path: 'sample://back'),
    ];
    final slots = {
      ScanCaptureRole.front.id: captureImages[1],
      ScanCaptureRole.back.id: captureImages[2],
    };
    ScannerPhotoSlot? selectedSlot;
    var deletedPath = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanImageFilmstrip(
            roles: const [ScanCaptureRole.front, ScanCaptureRole.back],
            requiredRoles: const [ScanCaptureRole.front, ScanCaptureRole.back],
            recommendedRoleId: ScanCaptureRole.back.id,
            slots: slots,
            captureImages: captureImages,
            roleCounts: const {'front': 2, 'back': 1},
            selectedPath: 'sample://front-2',
            onSelectRole: (_) {},
            onCaptureRole: (_) async {},
            onTapImage: (slot) => selectedSlot = slot,
            onRetake: (_) {},
            onDelete: (slot) => deletedPath = slot.path,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('filmstrip-photo-front-sample://front-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('filmstrip-photo-front-sample://front-2')),
      findsOneWidget,
    );
    expect(find.text('2'), findsWidgets);

    final frontPhoto = find.byKey(
      const ValueKey('filmstrip-photo-front-sample://front-1'),
    );
    await tester.ensureVisible(frontPhoto);
    await tester.tap(frontPhoto);
    expect(selectedSlot?.path, 'sample://front-1');

    await tester.tap(
      find.descendant(
        of: find.byKey(
          const ValueKey('filmstrip-photo-front-sample://front-1'),
        ),
        matching: find.byIcon(Icons.close),
      ),
    );
    expect(deletedPath, 'sample://front-1');
  });

  testWidgets('filmstrip thumbnail tap selects active large preview', (
    WidgetTester tester,
  ) async {
    final slots = _slots([
      _slot(role: ScanCaptureRole.front, path: 'sample://front'),
      _slot(role: ScanCaptureRole.back, path: 'sample://back'),
    ]);
    ScannerPhotoSlot? selectedSlot;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanImageFilmstrip(
            roles: const [ScanCaptureRole.front, ScanCaptureRole.back],
            requiredRoles: const [ScanCaptureRole.front],
            recommendedRoleId: ScanCaptureRole.back.id,
            slots: slots,
            captureImages: slots.values.toList(),
            roleCounts: const {'front': 1, 'back': 1},
            selectedPath: 'sample://front',
            onSelectRole: (_) {},
            onCaptureRole: (_) async {},
            onTapImage: (slot) => selectedSlot = slot,
            onRetake: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('filmstrip-photo-back-sample://back')),
    );
    expect(selectedSlot?.role, ScanCaptureRole.back.id);
  });

  testWidgets('deleting one filmstrip image does not delete all images', (
    WidgetTester tester,
  ) async {
    final slots = _slots([
      _slot(role: ScanCaptureRole.front, path: 'sample://front'),
      _slot(role: ScanCaptureRole.back, path: 'sample://back'),
    ]);
    var deletedRole = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanImageFilmstrip(
            roles: const [ScanCaptureRole.front, ScanCaptureRole.back],
            requiredRoles: const [ScanCaptureRole.front, ScanCaptureRole.back],
            recommendedRoleId: ScanCaptureRole.back.id,
            slots: slots,
            captureImages: slots.values.toList(),
            roleCounts: const {'front': 1, 'back': 1},
            selectedPath: 'sample://front',
            onSelectRole: (_) {},
            onCaptureRole: (_) async {},
            onTapImage: (_) {},
            onRetake: (_) {},
            onDelete: (slot) => deletedRole = slot.role,
          ),
        ),
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('filmstrip-photo-back-sample://back')),
        matching: find.byIcon(Icons.close),
      ),
    );
    expect(deletedRole, ScanCaptureRole.back.id);
    expect(slots.length, 2);
  });

  testWidgets('tapping a captured photo opens full-screen carousel', (
    WidgetTester tester,
  ) async {
    final captureImages = [
      _slot(role: ScanCaptureRole.front, path: 'sample://front-1'),
      _slot(role: ScanCaptureRole.back, path: 'sample://back-1'),
    ];
    final plan = const ScanCapturePlanService().buildPlan(
      ScanGoal.detailedAnalysis,
      CollectibleCategory.toyCar,
      const [
        CapturedScanImage(
          path: 'sample://front-1',
          role: ScanCaptureRole.front,
          source: 'sample',
        ),
        CapturedScanImage(
          path: 'sample://back-1',
          role: ScanCaptureRole.back,
          source: 'sample',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CaptureWorkspace(
              goal: ScanGoal.detailedAnalysis,
              category: CollectibleCategory.toyCar,
              plan: plan,
              slots: _slots(captureImages),
              captureImages: captureImages,
              selectedPath: 'sample://front-1',
              isBusy: false,
              hasResult: false,
              onPrimaryCapture: () {},
              onAnalyze: () {},
              onCamera: (_) async {},
              onGallery: (_) async {},
              onSelectRole: (_) {},
              onPreview: (_) {},
              onUseAsPrimary: (_) {},
              onEnhance: (_, _) async {},
              onDelete: (_) {},
              onSample: () {},
              onReset: () {},
            ),
          ),
        ),
      ),
    );

    final frontPhoto = find.byKey(
      const ValueKey('filmstrip-photo-front-sample://front-1'),
    );
    await tester.ensureVisible(frontPhoto);
    await tester.tap(frontPhoto);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('photo-review-carousel')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('photo-review-page-view')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('photo-review-primary')), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-review-delete')), findsOneWidget);
    expect(find.text('Photo 1 of 2'), findsOneWidget);
    expect(find.textContaining('Front'), findsWidgets);
  });

  testWidgets('carousel can navigate and delete only selected photo', (
    WidgetTester tester,
  ) async {
    final captureImages = [
      _slot(role: ScanCaptureRole.front, path: 'sample://front-1'),
      _slot(role: ScanCaptureRole.back, path: 'sample://back-1'),
    ];
    var selectedPath = '';
    var deletedPath = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _PhotoReviewTestHost(
            photos: captureImages,
            onSelect: (slot) => selectedPath = slot.path,
            onDelete: (slot) => deletedPath = slot.path,
            onUseAsPrimary: (_) {},
          ),
        ),
      ),
    );
    final frontPhoto = find.byKey(
      const ValueKey('filmstrip-photo-front-sample://front-1'),
    );
    await tester.ensureVisible(frontPhoto);
    await tester.tap(frontPhoto);
    await tester.pumpAndSettle();

    await tester.fling(
      find.byKey(const ValueKey('photo-review-page-view')),
      const Offset(-500, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text('Photo 2 of 2'), findsOneWidget);
    expect(selectedPath, 'sample://back-1');

    await tester.tap(find.byKey(const ValueKey('photo-review-delete')));
    await tester.pumpAndSettle();

    expect(deletedPath, 'sample://back-1');
    expect(find.text('Photo 1 of 1'), findsOneWidget);
  });

  testWidgets('use as primary action reports selected carousel photo', (
    WidgetTester tester,
  ) async {
    final captureImages = [
      _slot(role: ScanCaptureRole.front, path: 'sample://front-1'),
      _slot(role: ScanCaptureRole.closeUp, path: 'sample://detail-1'),
    ];
    var primaryPath = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _PhotoReviewTestHost(
            photos: captureImages,
            onSelect: (_) {},
            onDelete: (_) {},
            onUseAsPrimary: (slot) => primaryPath = slot.path,
          ),
        ),
      ),
    );
    final frontPhoto = find.byKey(
      const ValueKey('filmstrip-photo-front-sample://front-1'),
    );
    await tester.ensureVisible(frontPhoto);
    await tester.tap(frontPhoto);
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('photo-review-page-view')),
      const Offset(-500, 0),
      1000,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('photo-review-primary')));

    expect(primaryPath, 'sample://detail-1');
  });

  testWidgets('group chips filter photo strip by role', (
    WidgetTester tester,
  ) async {
    final captureImages = [
      _slot(role: ScanCaptureRole.front, path: 'sample://front-1'),
      _slot(role: ScanCaptureRole.front, path: 'sample://front-2'),
      _slot(role: ScanCaptureRole.back, path: 'sample://back-1'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanImageFilmstrip(
            roles: const [ScanCaptureRole.front, ScanCaptureRole.back],
            requiredRoles: const [ScanCaptureRole.front],
            recommendedRoleId: ScanCaptureRole.back.id,
            slots: {
              ScanCaptureRole.front.id: captureImages[1],
              ScanCaptureRole.back.id: captureImages[2],
            },
            captureImages: captureImages,
            roleCounts: const {'front': 2, 'back': 1},
            selectedPath: 'sample://front-1',
            onSelectRole: (_) {},
            onCaptureRole: (_) async {},
            onTapImage: (_) {},
            onRetake: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('filmstrip-photo-front-sample://front-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('filmstrip-photo-back-sample://back-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('photo-set-chip-back')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('filmstrip-photo-front-sample://front-1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('filmstrip-photo-back-sample://back-1')),
      findsOneWidget,
    );
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
    'CaptureWorkspace primary CTA changes from capture to analyze when ready',
    (WidgetTester tester) async {
      const service = ScanCapturePlanService();
      final emptyPlan = service.buildPlan(
        ScanGoal.identifyValue,
        CollectibleCategory.toyCar,
        const [],
      );
      var primaryCaptures = 0;
      var analyzes = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CaptureWorkspace(
                goal: ScanGoal.identifyValue,
                category: CollectibleCategory.toyCar,
                plan: emptyPlan,
                slots: const {},
                captureImages: const [],
                isBusy: false,
                hasResult: false,
                onPrimaryCapture: () => primaryCaptures += 1,
                onAnalyze: () => analyzes += 1,
                onCamera: (_) async {},
                onGallery: (_) async {},
                onSelectRole: (_) {},
                onPreview: (_) {},
                onUseAsPrimary: (_) {},
                onEnhance: (_, _) async {},
                onDelete: (_) {},
                onSample: () {},
                onReset: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Recommended next photo'), findsOneWidget);
      expect(find.textContaining('front/package'), findsWidgets);
      expect(
        find.byKey(const ValueKey('scan-primary-Analyze Image')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('scan-primary-Scan with Camera')),
        findsOneWidget,
      );
      expect(find.text('Capture Next Best Photo'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scan-secondary-New Scan')),
        findsNothing,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('scan-primary-Scan with Camera')),
      );
      await tester.tap(
        find.byKey(const ValueKey('scan-primary-Scan with Camera')),
      );
      expect(primaryCaptures, 1);

      final readySlots = _slots([_slot(role: ScanCaptureRole.front)]);
      final readyPlan = service
          .buildPlan(ScanGoal.identifyValue, CollectibleCategory.toyCar, const [
            CapturedScanImage(
              path: 'sample://front',
              role: ScanCaptureRole.front,
              source: 'sample',
            ),
          ]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CaptureWorkspace(
                goal: ScanGoal.identifyValue,
                category: CollectibleCategory.toyCar,
                plan: readyPlan,
                slots: readySlots,
                captureImages: readySlots.values.toList(),
                isBusy: false,
                hasResult: false,
                onPrimaryCapture: () => primaryCaptures += 1,
                onAnalyze: () => analyzes += 1,
                onCamera: (_) async {},
                onGallery: (_) async {},
                onSelectRole: (_) {},
                onPreview: (_) {},
                onUseAsPrimary: (_) {},
                onEnhance: (_, _) async {},
                onDelete: (_) {},
                onSample: () {},
                onReset: () {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('scan-primary-Analyze Image')),
        findsOneWidget,
      );
      expect(find.text('Analyze 1 photo'), findsOneWidget);
      expect(find.byKey(const ValueKey('workspace-filmstrip')), findsOneWidget);
      expect(find.textContaining('Auto Detect'), findsNothing);
      expect(find.textContaining('55%'), findsNothing);
      expect(find.textContaining('readiness'), findsNothing);
      await tester.ensureVisible(
        find.byKey(const ValueKey('scan-primary-Analyze Image')),
      );
      await tester.tap(
        find.byKey(const ValueKey('scan-primary-Analyze Image')),
      );
      expect(analyzes, 1);
    },
  );

  testWidgets(
    'CaptureWorkspace keeps role checklist collapsed and sample accessible',
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
                category: CollectibleCategory.generic,
                plan: emptyPlan,
                slots: const {},
                captureImages: const [],
                isBusy: false,
                hasResult: false,
                onPrimaryCapture: () {},
                onAnalyze: () {},
                onCamera: (_) async {},
                onGallery: (_) async {},
                onSelectRole: (_) {},
                onPreview: (_) {},
                onUseAsPrimary: (_) {},
                onEnhance: (_, _) async {},
                onDelete: (_) {},
                onSample: () {},
                onReset: () {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('capture-guide-expansion')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('photo-checklist')), findsNothing);
      expect(
        find.byKey(const ValueKey('capture-role-card-front')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
        findsOneWidget,
      );
    },
  );

  test('quick and detailed modes recommend different toy car roles', () {
    const service = ScanCapturePlanService();

    final quickPlan = service.buildPlan(
      ScanGoal.identifyValue,
      CollectibleCategory.toyCar,
      const [],
    );
    final detailedPlan = service.buildPlan(
      ScanGoal.detailedAnalysis,
      CollectibleCategory.toyCar,
      const [
        CapturedScanImage(
          path: 'sample://front',
          role: ScanCaptureRole.front,
          source: 'sample',
        ),
      ],
    );

    expect(quickPlan.requiredRoles, [ScanCaptureRole.front]);
    expect(detailedPlan.requiredRoles, [ScanCaptureRole.front]);
    expect(
      detailedPlan.optionalRoles,
      containsAll([ScanCaptureRole.back, ScanCaptureRole.baseUnderside]),
    );
    expect(detailedPlan.nextRecommendedRole, ScanCaptureRole.back);
  });

  testWidgets('portfolio detail renders saved gallery images', (
    WidgetTester tester,
  ) async {
    final item = _itemWithGallery();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: CollectibleDetailPage(item: item)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey('collectible-detail-gallery-filmstrip')),
      findsOneWidget,
    );
    expect(find.text('Front'), findsWidgets);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('result gallery switches the active preview image', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiResultCard(
                item: 'Hot Wheels Audi RS 6 Avant',
                category: 'Toy Car',
                estimatedValue: 'Value unavailable',
                confidence: '92%',
                condition: 'Packaged',
                imagePath: 'sample://front',
                confidenceScore: 0.92,
                rawEstimatedValue: 0,
                primaryMatch: 'Hot Wheels Audi RS 6 Avant',
                alternativeMatches: const <ScanAlternativeMatch>[],
                confidenceExplanation: 'Strong packaging and model match.',
                detectionQuality: 'Clear',
                aiReasoning: 'Recognized the model and package text.',
                pricing: _pricing(),
                recommendation: 'Keep the complete capture set.',
                isSaved: false,
                isSaving: false,
                onScanAnother: () {},
                galleryImages: const [
                  CollectibleImage(
                    path: 'sample://front',
                    role: 'front',
                    source: 'sample',
                    isPrimary: true,
                  ),
                  CollectibleImage(
                    path: 'sample://detail',
                    role: 'detail',
                    source: 'sample',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('scan-result-gallery-filmstrip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('result-primary-add-to-portfolio')),
      findsOneWidget,
    );
    expect(find.text('Valuation evidence'), findsOneWidget);
    expect(find.text('Valuation status'), findsNothing);
    expect(
      find.byKey(const ValueKey('scan-result-hero-sample://front')),
      findsOneWidget,
    );
    expect(find.text('Saved to Portfolio'), findsNothing);

    final detailTile = find.byKey(
      const ValueKey('scan-result-gallery-sample://detail'),
    );
    await tester.ensureVisible(detailTile);
    await tester.tap(detailTile);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('scan-result-hero-sample://detail')),
      findsOneWidget,
    );
  });

  testWidgets('result saved state shows approved confirmation card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiResultCard(
                item: 'Hot Wheels Audi RS 6 Avant',
                category: 'Toy Car',
                estimatedValue: 'Value unavailable',
                confidence: '92%',
                condition: 'Packaged',
                imagePath: 'sample://front',
                confidenceScore: 0.92,
                rawEstimatedValue: 0,
                primaryMatch: 'Hot Wheels Audi RS 6 Avant',
                alternativeMatches: const <ScanAlternativeMatch>[],
                confidenceExplanation: 'Strong packaging and model match.',
                detectionQuality: 'Clear',
                aiReasoning: 'Recognized the model and package text.',
                pricing: _pricing(),
                recommendation: 'Keep the complete capture set.',
                isSaved: true,
                isSaving: false,
                onScanAnother: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Saved to Portfolio'), findsWidgets);
    expect(find.byKey(const ValueKey('scanner-status-card')), findsOneWidget);
    expect(find.text('Your item has been added successfully.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('result-primary-add-to-portfolio')),
      findsOneWidget,
    );
  });

  test('old one-image portfolio items expose a compatible gallery', () {
    final item = CollectibleItem.fromJson({
      'id': 'legacy-1',
      'title': 'Legacy Card',
      'category': 'Trading Card',
      'estimatedValue': 25,
      'confidence': 0.8,
      'condition': 'Good',
      'recommendation': 'Hold.',
      'imagePath': 'sample://legacy-card',
      'createdAt': '2026-07-07T00:00:00.000',
    });

    expect(item.effectiveGalleryImages, hasLength(1));
    expect(item.effectiveGalleryImages.single.path, 'sample://legacy-card');
    expect(item.effectiveGalleryImages.single.isPrimary, isTrue);
  });
}

PricingInfo _pricing() {
  return const PricingInfo(
    estimatedMarketValue: 0,
    lowEstimate: 0,
    highEstimate: 0,
    currency: 'AUD',
    pricingSource: 'Unavailable',
    pricingConfidence: 0,
    lastUpdated: null,
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

Map<String, ScannerPhotoSlot> _slots(List<ScannerPhotoSlot> slots) {
  return {for (final slot in slots) slot.role: slot};
}

CollectibleItem _itemWithGallery() {
  return CollectibleItem(
    id: 'gallery-item',
    title: 'Gallery Hot Wheels',
    category: 'Toy Car',
    estimatedValue: 0,
    confidence: 0.92,
    condition: 'Packaged',
    recommendation: 'Keep complete photo set.',
    imagePath: 'sample://front',
    createdAt: DateTime(2026, 7, 7),
    galleryImages: const [
      CollectibleImage(
        path: 'sample://front',
        role: 'front',
        source: 'sample',
        isPrimary: true,
      ),
      CollectibleImage(path: 'sample://back', role: 'back', source: 'sample'),
    ],
  );
}

class _PhotoReviewTestHost extends StatelessWidget {
  const _PhotoReviewTestHost({
    required this.photos,
    required this.onSelect,
    required this.onDelete,
    required this.onUseAsPrimary,
  });

  final List<ScannerPhotoSlot> photos;
  final void Function(ScannerPhotoSlot slot) onSelect;
  final void Function(ScannerPhotoSlot slot) onDelete;
  final void Function(ScannerPhotoSlot slot) onUseAsPrimary;

  @override
  Widget build(BuildContext context) {
    final capturedImages = [
      for (final photo in photos)
        CapturedScanImage(
          path: photo.path,
          role: ScanCaptureRole.fromId(photo.role),
          source: photo.source,
        ),
    ];
    final plan = const ScanCapturePlanService().buildPlan(
      ScanGoal.detailedAnalysis,
      CollectibleCategory.toyCar,
      capturedImages,
    );
    return SingleChildScrollView(
      child: CaptureWorkspace(
        goal: ScanGoal.detailedAnalysis,
        category: CollectibleCategory.toyCar,
        plan: plan,
        slots: _slots(photos),
        captureImages: photos,
        selectedPath: photos.first.path,
        isBusy: false,
        hasResult: false,
        onPrimaryCapture: () {},
        onAnalyze: () {},
        onCamera: (_) async {},
        onGallery: (_) async {},
        onSelectRole: (_) {},
        onPreview: onSelect,
        onUseAsPrimary: onUseAsPrimary,
        onEnhance: (_, _) async {},
        onDelete: (path) {
          final slot = photos.firstWhere((photo) => photo.path == path);
          onDelete(slot);
        },
        onSample: () {},
        onReset: () {},
      ),
    );
  }
}
