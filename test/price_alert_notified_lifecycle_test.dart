import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/domain/services/price_alert_evaluator.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CollectibleItem item(double value) {
    return CollectibleItem(
      id: 'item-1',
      title: 'Charizard',
      category: 'Trading Card',
      estimatedValue: value,
      confidence: 90,
      condition: 'Near Mint',
      recommendation: '',
      imagePath: '',
      createdAt: DateTime(2026, 1, 1),
      valuationStatus: ValuationStatus.marketEstimated,
    );
  }

  PriceAlert alert(PriceAlertStatus status) {
    return PriceAlert(
      id: 'alert-1',
      itemId: 'item-1',
      itemTitle: 'Charizard',
      rule: const PriceAlertRule(
        type: PriceAlertRuleType.priceRisesAboveAmount,
        amount: 100,
      ),
      status: status,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      triggeredAt: status == PriceAlertStatus.active ? null : DateTime(2026, 1, 2),
      message: status == PriceAlertStatus.active ? null : 'Charizard rose above AUD 100.',
    );
  }

  group('notified status', () {
    test('parses from wire name', () {
      expect(PriceAlertStatus.fromName('notified'), PriceAlertStatus.notified);
    });

    test('is treated as fired (isTriggered)', () {
      expect(alert(PriceAlertStatus.notified).isTriggered, isTrue);
      expect(alert(PriceAlertStatus.triggered).isTriggered, isTrue);
      expect(alert(PriceAlertStatus.active).isTriggered, isFalse);
    });
  });

  group('evaluator notify-once', () {
    const evaluator = PriceAlertEvaluator();

    test('active alert crossing its threshold triggers', () {
      final result = evaluator.evaluateAlert(
        alert: alert(PriceAlertStatus.active),
        item: item(150),
      );
      expect(result.triggered, isTrue);
      expect(result.alert.status, PriceAlertStatus.triggered);
    });

    test('notified alert still met does NOT re-trigger or change status', () {
      final result = evaluator.evaluateAlert(
        alert: alert(PriceAlertStatus.notified),
        item: item(150), // still above 100
      );
      expect(result.triggered, isFalse);
      expect(result.alert.status, PriceAlertStatus.notified);
    });

    test('triggered alert still met does NOT re-trigger (idempotent)', () {
      final result = evaluator.evaluateAlert(
        alert: alert(PriceAlertStatus.triggered),
        item: item(150),
      );
      expect(result.triggered, isFalse);
      expect(result.alert.status, PriceAlertStatus.triggered);
    });
  });
}
