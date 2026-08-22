import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Volume 03 scanner structure', () {
    test('shared scanner component system is defined centrally', () {
      final source = _read(
        'lib/features/scanner/presentation/scanner_visual_theme.dart',
      );

      expect(source, contains('class ScannerPrimaryButton'));
      expect(source, contains('class ScannerSecondaryButton'));
      expect(source, contains('class ScannerTertiaryAction'));
      expect(source, contains('class ScannerFocusedScaffold'));
      expect(source, contains('class ScannerPageHeader'));
      expect(source, contains('class ScannerIconButton'));
      expect(source, contains('class ScannerCameraControl'));
      expect(source, contains('class ScannerCameraShutter'));
      expect(source, contains('class ScannerGuidancePanel'));
      expect(source, contains('class ScannerSegmentedSelector'));
      expect(source, contains('class ScannerPhotoThumbnail'));
      expect(source, contains('class ScannerStatusCard'));
      expect(source, contains('class ScannerAnalyzingIndicator'));
    });

    test(
      'hub uses approved S01 action order and excludes workspace content',
      () {
        final source =
            _read(
              'lib/features/scanner/presentation/pages/scan_hub_page.dart',
            ) +
            _read(
              'lib/features/scanner/presentation/widgets/'
              'scan_hub_presentation.dart',
            );

        _expectInOrder(source, const [
          "title: 'Take a photo'",
          "title: 'Choose from gallery'",
          "title: 'Try a sample scan'",
        ]);
        // Camera is the accent-filled primary; both actions are buttons, not
        // navigation rows, so they carry no disclosure chevron.
        expect(source, contains('emphasis: true'));
        expect(source, contains('showChevron: false'));
        // Animated viewfinder anchors the hub; single trust line replaces the
        // old repeated marketing copy.
        expect(source, contains("ValueKey('scan-hub-reticle')"));
        expect(source, contains("ValueKey('scan-hub-trust-note')"));
        // The PackLox brand lockup now leads the hub for cross-tab header
        // consistency (Home/Portfolio/Search/Settings all show it).
        expect(source, contains('HomeBrandLockup'));
        // Retired surfaces stay retired.
        expect(source, isNot(contains('_ScannerHeroCard')));
        expect(source, isNot(contains('Choose an option')));
        expect(source, isNot(contains('class ScanHubHero')));
        expect(source, isNot(contains('class ScanHubEntryTile')));
        expect(source, isNot(contains('scan-hub-real-collectible-montage')));
        expect(source, isNot(contains('Cards')));
      },
    );

    test('camera and review preserve scanner capture contracts', () {
      final camera = _read(
        'lib/features/scanner/presentation/pages/camera_capture_page.dart',
      );
      final review = _read(
        'lib/features/scanner/presentation/pages/image_enhancement_preview_page.dart',
      );
      final scannerVisualTheme = _read(
        'lib/features/scanner/presentation/scanner_visual_theme.dart',
      );

      expect(camera, contains('CameraCapturePage'));
      expect(camera, contains('CameraPreview('));
      expect(camera, contains('ImageEnhancementPreviewSurface'));
      expect(camera, contains('ScannerCameraShutter'));
      expect(camera, contains('camera-authority-viewfinder'));
      expect(scannerVisualTheme, contains('camera-capture-button'));
      expect(
        scannerVisualTheme,
        contains('onTap: isCapturing ? null : onPressed'),
      );
      expect(camera, contains('PackLox needs camera access'));
      expect(camera, contains('Camera access is off for PackLox.'));
      expect(camera, contains('Open Settings'));
      expect(camera, contains('Try Again'));

      expect(review, contains('ImageEnhancementPreviewSurface'));
      expect(review, contains('enhancement-preview-original'));
      expect(review, contains('enhancement-preview-auto_enhance'));
      expect(review, contains('ImageEnhancementPreset.original'));
      expect(review, contains('ImageEnhancementPreset.autoEnhance'));
      expect(review, contains('_ReviewReadinessPill'));
      expect(review, contains('Photo readiness'));
      expect(review, isNot(contains('Use Anyway')));
      expect(review, contains("Text('Use Photo')"));
      expect(review, contains("label: 'Original'"));
      expect(review, contains("label: 'AI Enhance'"));
    });

    test(
      'workspace uses canonical CaptureWorkspace and no fabricated confidence',
      () {
        final screen = _read(
          'lib/features/scanner/presentation/pages/scanner_screen.dart',
        );
        final workspace = _read(
          'lib/features/scanner/presentation/widgets/capture_workspace.dart',
        );
        final legacyWorkspaceFile = File(
          'lib/features/scanner/presentation/pages/scan_workspace_screen.dart',
        );

        expect(screen, contains('CaptureWorkspace('));
        expect(screen, contains('scannerState.captureImages'));
        expect(screen, contains('selectedPath: selectedImagePath'));
        expect(
          screen,
          contains('onPreview: scannerController.selectCapturedPhoto'),
        );
        expect(screen, contains('onUseAsPrimary:'));
        expect(screen, contains('scannerController.useCapturedPhotoAsPrimary'));
        expect(
          screen,
          contains('onDelete: scannerController.deleteCapturedImage'),
        );
        expect(screen, isNot(contains('_workspaceConfidence')));

        expect(workspace, contains('scan-image-filmstrip'));
        expect(workspace, contains('workspace-filmstrip'));
        expect(workspace, contains('photo-review-carousel'));
        expect(workspace, contains('photo-review-page-view'));
        expect(workspace, contains('photo-review-retake'));
        expect(workspace, contains('photo-review-delete'));
        expect(workspace, contains('photo-review-primary'));
        expect(workspace, contains('Use as Primary'));
        expect(workspace, isNot(contains('Auto Detect')));
        expect(workspace, isNot(contains('raw confidence')));
        expect(legacyWorkspaceFile.existsSync(), isFalse);
      },
    );

    test('analysis state stays controller-owned and avoids fake progress', () {
      final source = _read(
        'lib/features/scanner/presentation/pages/scanner_screen.dart',
      );

      expect(source, contains('onAnalyze: scannerController.analyzeWithAi'));
      expect(source, contains('scan-busy-overlay'));
      expect(source, contains('scan-primary-Analyze Image'));
      expect(source, isNot(contains('50%')));
      expect(source, isNot(contains('provider status')));
      expect(source, isNot(contains('Future.delayed')));
    });
  });
}

String _read(String path) => File(path).readAsStringSync();

void _expectInOrder(String source, List<String> needles) {
  var cursor = -1;
  for (final needle in needles) {
    final index = source.indexOf(needle, cursor + 1);
    expect(index, isNot(-1), reason: 'Expected "$needle" after $cursor.');
    cursor = index;
  }
}
