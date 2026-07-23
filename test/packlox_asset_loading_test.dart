import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PackLox production assets are bundled and readable', () async {
    for (final assetPath in PackLoxAssets.all) {
      final data = await rootBundle.load(assetPath);

      expect(data.lengthInBytes, greaterThan(0));
      if (assetPath.endsWith('.svg')) {
        final svg = await rootBundle.loadString(assetPath);
        expect(svg, contains('<svg'));
      }
    }
  });
}
