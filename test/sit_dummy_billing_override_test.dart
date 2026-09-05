/// A SIT build must be able to reach real StoreKit.
///
/// billingRepositoryProvider checks the SIT dummy config FIRST, so while it
/// is on, a SIT build can never construct AppleBillingRepository. Before this
/// override existed, a sandbox subscription test would have shown a purchase
/// succeeding with Apple never involved -- the worst kind of green result.
import 'package:collectiq_ai/features/subscription/data/repositories/sit_dummy_billing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool enabled({String override = '', String appEnv = 'sit'}) =>
      SitDummyBillingConfig.resolveEnabled(override: override, appEnv: appEnv);

  test('SIT builds still default to dummy billing', () {
    expect(enabled(), isTrue);
  });

  test('non-SIT builds still default to real billing', () {
    expect(enabled(appEnv: 'prod'), isFalse);
    expect(enabled(appEnv: ''), isFalse);
  });

  test('an explicit false turns it off even in SIT -- the point of this', () {
    expect(enabled(override: 'false'), isFalse);
  });

  test('the usual ways of writing false are all accepted', () {
    for (final value in ['false', 'FALSE', ' False ', '0', 'no', 'off']) {
      expect(enabled(override: value), isFalse, reason: value);
    }
  });

  test('an explicit true forces dummy billing outside SIT', () {
    expect(enabled(override: 'true', appEnv: 'prod'), isTrue);
  });

  test('unset is distinguishable from false', () {
    // The original bug: bool.fromEnvironment cannot tell these apart, so
    // `explicitlyEnabled || appEnv == 'sit'` could never be turned off.
    expect(enabled(override: ''), isTrue);
    expect(enabled(override: 'false'), isFalse);
  });
}
