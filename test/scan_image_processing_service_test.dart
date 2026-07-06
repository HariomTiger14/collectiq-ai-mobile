import 'dart:io';

import 'package:collectiq_ai/features/scanner/services/scan_image_processing_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('ScanImageProcessor', () {
    test('compresses large images to about 1600px JPEG', () {
      final temp = Directory.systemTemp.createTempSync('scan_image_processor_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final inputPath = '${temp.path}${Platform.pathSeparator}large.png';
      final outputPath = '${temp.path}${Platform.pathSeparator}optimized.jpg';
      final source = img.Image(width: 2400, height: 1200);
      img.fill(source, color: img.ColorRgb8(220, 220, 220));
      File(inputPath).writeAsBytesSync(img.encodePng(source), flush: true);

      final result = optimizeScanImageFile(
        inputPath: inputPath,
        outputPath: outputPath,
        maxDimension: 1600,
        jpegQuality: 84,
      );

      expect(result.width, 1600);
      expect(result.height, 800);
      expect(result.fileSizeBytes, greaterThan(0));
      expect(File(outputPath).existsSync(), isTrue);
      expect(img.decodeJpg(File(outputPath).readAsBytesSync()), isNotNull);
    });

    test('reports darkness and extremely low resolution warnings', () {
      final source = img.Image(width: 320, height: 320);
      img.fill(source, color: img.ColorRgb8(8, 8, 8));
      final bytes = img.encodeJpg(source);

      final report = inspectScanImageBytes(bytes, bytes.length);

      expect(report.width, 320);
      expect(report.height, 320);
      expect(
        report.warnings.map((warning) => warning.code),
        containsAll(['too_dark', 'low_resolution']),
      );
    });
  });
}
