import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PackLox production SVG assets are bundled and readable', () async {
    for (final assetPath in PackLoxAssets.all) {
      final svg = await rootBundle.loadString(assetPath);

      expect(svg, contains('<svg'));
    }
  });
}
