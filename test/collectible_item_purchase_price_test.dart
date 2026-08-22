import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter_test/flutter_test.dart';

CollectibleItem _item({double? purchasePrice, double estimatedValue = 500}) {
  return CollectibleItem(
    id: 'i1',
    title: 'Charizard',
    category: 'Cards',
    estimatedValue: estimatedValue,
    confidence: 0.9,
    condition: 'Near Mint',
    recommendation: 'Keep',
    imagePath: '',
    createdAt: DateTime(2026, 1, 1),
    purchasePrice: purchasePrice,
  );
}

void main() {
  test('purchasePrice round-trips through JSON', () {
    final restored = CollectibleItem.fromJson(_item(purchasePrice: 300).toJson());
    expect(restored.purchasePrice, 300);

    final noPrice = CollectibleItem.fromJson(_item().toJson());
    expect(noPrice.purchasePrice, isNull);
  });

  test('gainOverPurchase = estimatedValue - purchasePrice (null when unset)', () {
    expect(_item(purchasePrice: 300, estimatedValue: 500).gainOverPurchase, 200);
    expect(
      _item(purchasePrice: 700, estimatedValue: 500).gainOverPurchase,
      -200,
    );
    expect(_item().gainOverPurchase, isNull);
  });

  test('copyWith sets and clears purchasePrice', () {
    expect(_item().copyWith(purchasePrice: 250).purchasePrice, 250);
    expect(
      _item(purchasePrice: 250).copyWith(clearPurchasePrice: true).purchasePrice,
      isNull,
    );
    // Passing neither keeps the existing value.
    expect(_item(purchasePrice: 250).copyWith().purchasePrice, 250);
  });
}
