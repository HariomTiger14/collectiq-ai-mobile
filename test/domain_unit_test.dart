import 'dart:typed_data';

import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:collectiq_ai/features/portfolio/data/repositories/shared_preferences_portfolio_repository.dart';
import 'package:collectiq_ai/features/scanner/services/gallery_service.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CollectibleItem', () {
    test('toJson serializes all fields', () {
      final item = _testItem();

      final json = item.toJson();

      expect(json['id'], 'item-1');
      expect(json['title'], '1999 Pokémon Charizard');
      expect(json['category'], 'Trading Card');
      expect(json['estimatedValue'], 1850);
      expect(json['confidence'], 0.94);
      expect(json['condition'], 'Near Mint');
      expect(json['recommendation'], 'Consider grading before selling.');
      expect(json['imagePath'], 'sample://sports-card');
      expect(json['createdAt'], '2026-06-27T00:00:00.000');
    });

    test('fromJson restores all fields', () {
      final item = CollectibleItem.fromJson({
        'id': 'item-1',
        'title': '1999 Pokémon Charizard',
        'category': 'Trading Card',
        'estimatedValue': 1850,
        'confidence': 0.94,
        'condition': 'Near Mint',
        'recommendation': 'Consider grading before selling.',
        'imagePath': 'sample://sports-card',
        'createdAt': '2026-06-27T00:00:00.000',
      });

      expect(item.id, 'item-1');
      expect(item.title, '1999 Pokémon Charizard');
      expect(item.category, 'Trading Card');
      expect(item.estimatedValue, 1850);
      expect(item.confidence, 0.94);
      expect(item.condition, 'Near Mint');
      expect(item.recommendation, 'Consider grading before selling.');
      expect(item.imagePath, 'sample://sports-card');
      expect(item.createdAt, DateTime.parse('2026-06-27T00:00:00.000'));
    });
  });

  group('SharedPreferencesPortfolioRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('adds and loads portfolio items', () async {
      const repository = SharedPreferencesPortfolioRepository();
      final item = _testItem();

      await repository.addItem(item);
      final items = await repository.getItems();

      expect(items, hasLength(1));
      expect(items.single.id, item.id);
      expect(items.single.title, item.title);
    });

    test('removeItem removes saved item', () async {
      const repository = SharedPreferencesPortfolioRepository();
      final item = _testItem();

      await repository.addItem(item);
      await repository.removeItem(item.id);
      final items = await repository.getItems();

      expect(items, isEmpty);
    });

    test('loads existing saved items from local storage', () async {
      SharedPreferences.setMockInitialValues({
        'portfolio_items':
            '[{"id":"persisted-1","title":"Persisted Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000"}]',
      });
      const repository = SharedPreferencesPortfolioRepository();

      final items = await repository.getItems();

      expect(items, hasLength(1));
      expect(items.single.id, 'persisted-1');
      expect(items.single.title, 'Persisted Charizard');
    });
  });

  group('RecognitionResult', () {
    test('fromJson parses backend response', () {
      final result = RecognitionResult.fromJson({
        'success': true,
        'filename': 'scan.png',
        'imageUrl': 'http://192.168.0.81:8000/uploads/scan.png',
        'title': '1999 Pokémon Charizard',
        'category': 'Trading Card',
        'confidence': 94,
        'estimatedValue': 1850,
        'condition': 'Near Mint',
        'recommendation': 'Consider grading before selling.',
      });

      expect(result.title, '1999 Pokémon Charizard');
      expect(result.success, isTrue);
      expect(result.filename, 'scan.png');
      expect(result.imageUrl, 'http://192.168.0.81:8000/uploads/scan.png');
      expect(result.category, 'Trading Card');
      expect(result.confidence, 0.94);
      expect(result.description, isEmpty);
      expect(result.estimatedValue, 1850);
      expect(result.condition, 'Near Mint');
      expect(result.recommendation, 'Consider grading before selling.');
    });
  });

  group('GalleryService', () {
    test('validates supported image extensions case-insensitively', () async {
      final service = GalleryService();

      for (final name in [
        'image.PNG',
        'image.Png',
        'image.jpg',
        'image.JPEG',
      ]) {
        final image = XFile.fromData(Uint8List.fromList([1, 2, 3]), path: name);

        await expectLater(service.validateImage(image), completion(isTrue));
      }
    });

    test('rejects unsupported image extension with clear message', () async {
      final service = GalleryService();
      final image = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        path: 'image.gif',
      );

      await expectLater(
        service.validateImage(image),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Please select a PNG, JPG, or JPEG image.'),
          ),
        ),
      );
    });
  });
}

CollectibleItem _testItem() {
  return CollectibleItem(
    id: 'item-1',
    title: '1999 Pokémon Charizard',
    category: 'Trading Card',
    estimatedValue: 1850,
    confidence: 0.94,
    condition: 'Near Mint',
    recommendation: 'Consider grading before selling.',
    imagePath: 'sample://sports-card',
    createdAt: DateTime.parse('2026-06-27T00:00:00.000'),
  );
}
