/// One alert per item per rule type.
///
/// The id used to carry microsecondsSinceEpoch, so every tap of "Alert if
/// value rises 10%" minted a fresh id and a fresh row. Observed in production
/// on 2026-09-05: three identical "Increases by 10%" alerts on one item,
/// created at 17:26, 21:59 and 23:07 — one per tap.
///
/// It also broke deletion: the cloud delete upserts on (id, user_id) to mark
/// the row disabled, and a timestamped id gave it nothing stable to match.
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the same alert on the same item has the same id every time', () {
    final first = buildPriceAlertId(
      itemId: 'item-1',
      type: PriceAlertRuleType.percentageIncrease,
    );
    final second = buildPriceAlertId(
      itemId: 'item-1',
      type: PriceAlertRuleType.percentageIncrease,
    );
    expect(first, second);
  });

  test('different rule types on one item stay distinct', () {
    final up = buildPriceAlertId(
      itemId: 'item-1',
      type: PriceAlertRuleType.percentageIncrease,
    );
    final down = buildPriceAlertId(
      itemId: 'item-1',
      type: PriceAlertRuleType.percentageDecrease,
    );
    final stale = buildPriceAlertId(
      itemId: 'item-1',
      type: PriceAlertRuleType.stalePricingReminder,
    );
    expect({up, down, stale}, hasLength(3));
  });

  test('the same rule on different items stays distinct', () {
    expect(
      buildPriceAlertId(
        itemId: 'item-1',
        type: PriceAlertRuleType.percentageIncrease,
      ),
      isNot(
        buildPriceAlertId(
          itemId: 'item-2',
          type: PriceAlertRuleType.percentageIncrease,
        ),
      ),
    );
  });

  test('the id carries no timestamp', () {
    // The specific regression: a clock value in the id made every creation
    // unique and therefore duplicable.
    final id = buildPriceAlertId(
      itemId: 'item-1',
      type: PriceAlertRuleType.percentageIncrease,
    );
    expect(id, 'alert-item-1-percentageIncrease');
    expect(RegExp(r'\d{10,}').hasMatch(id), isFalse);
  });
}
