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
        expect(source, contains('PackLoxHeader('));
        expect(source, contains('PackLoxHero('));
        expect(source, contains('PackLoxEntryTile('));
        expect(source, contains("variant: PackLoxHeroVariant.scanner"));
        expect(source, contains("variant: PackLoxEntryTileVariant.scanner"));
        expect(source, contains("title: 'Ready when your item is.'"));
        expect(source, contains("< 12 => 'Good morning'"));
        expect(source, contains("< 18 => 'Good afternoon'"));
        expect(source, contains("_ => 'Good evening'"));
        expect(source, contains("? 'Collector'"));
        expect(source, contains('Choose an option'));
        expect(source, isNot(contains('class ScanHubHero')));
        expect(source, isNot(contains('class ScanHubEntryTile')));
        expect(source, isNot(contains('scan-hub-real-collectible-montage')));
        expect(source, isNot(contains('Cards • Coins')));
      },
    );

    test('camera and review use shared scanner controls', () {
      final camera = _read(
        'lib/features/scanner/presentation/pages/camera_capture_page.dart',
      );
      final review = _read(
        'lib/features/scanner/presentation/pages/image_enhancement_preview_page.dart',
      );

      expect(camera, contains('ScannerCameraControl'));
      expect(camera, contains('ScannerCameraShutter'));
      expect(camera, contains('ScannerGuidancePanel'));
      expect(camera, isNot(contains('IconButton.filled')));
      expect(camera, isNot(contains('IconButton.filledTonal')));
      expect(camera, contains('Place the collectible in the frame'));
      expect(camera, contains('Starting camera…'));

      expect(review, contains('ScannerSegmentedSelector'));
      expect(review, contains('ScannerSecondaryButton'));
      expect(review, contains('ScannerPrimaryButton'));
      expect(review, isNot(contains('OutlinedButton(')));
      expect(review, contains("label: 'Use photo'"));
      expect(review, contains("label: 'Original'"));
      expect(review, contains("label: 'Enhanced'"));
    });

    test(
      'workspace uses approved copy, shared treatments, and no raw confidence',
      () {
        final source = _read(
          'lib/features/scanner/presentation/pages/scan_workspace_screen.dart',
        );

        expect(source, contains('ScannerStatusCard'));
        expect(source, contains('ScannerPhotoThumbnail'));
        expect(source, contains('ScannerSecondaryButton'));
        expect(source, contains('ScannerTertiaryAction'));
        expect(source, contains('Nice first photo'));
        expect(source, contains('One more photo recommended'));
        expect(source, contains('Take back photo'));
        expect(source, contains('Analyze now'));
        expect(source, contains('Add a different photo'));
        expect(source, contains('Great — ready to analyze'));
        expect(source, contains('Analyze collectible'));
        expect(source, contains('Add another photo'));
        expect(source, isNot(contains('raw confidence')));
        expect(source, isNot(contains('Auto Detect')));

        _expectInOrder(source, const [
          "label: _takePhotoLabel(nextBestRole)",
          "label: 'Analyze now'",
          "label: 'Add a different photo'",
        ]);
        _expectInOrder(source, const [
          "label: 'Analyze collectible'",
          "label: 'Add another photo'",
        ]);
      },
    );

    test('analysing state uses approved progress copy', () {
      final source = _read(
        'lib/features/scanner/presentation/pages/scan_workspace_screen.dart',
      );

      expect(source, contains('Analyzing your collectible…'));
      expect(source, contains('ScannerAnalyzingIndicator'));
      expect(source, contains('This may take a few moments.'));
      expect(source, contains('Preparing photos'));
      expect(source, contains('Identifying item'));
      expect(source, contains('Estimating value'));
      expect(source, contains('Finalizing results'));
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
