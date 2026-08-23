import 'package:collectiq_ai/features/settings/presentation/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('manageSubscriptionUri', () {
    test('iOS always opens the App Store subscriptions page directly', () {
      final uri = manageSubscriptionUri(isIOS: true, isAndroid: false);

      expect(uri, Uri.parse('https://apps.apple.com/account/subscriptions'));
    });

    test(
      'iOS ignores any Android args passed alongside it (isIOS wins)',
      () {
        final uri = manageSubscriptionUri(
          isIOS: true,
          isAndroid: true,
          androidPackageName: 'com.collectiq.ai',
          androidProductId: 'collectiq_pro_monthly',
        );

        expect(uri, Uri.parse('https://apps.apple.com/account/subscriptions'));
      },
    );

    test(
      'Android links to the specific subscription (sku + package), not '
      'just the generic Play Store subscriptions list',
      () {
        final uri = manageSubscriptionUri(
          isIOS: false,
          isAndroid: true,
          androidPackageName: 'com.collectiq.ai',
          androidProductId: 'collectiq_pro_monthly',
        );

        expect(
          uri,
          Uri.parse(
            'https://play.google.com/store/account/subscriptions'
            '?sku=collectiq_pro_monthly&package=com.collectiq.ai',
          ),
        );
      },
    );

    test('Android with no package name yet returns null, not a broken URL', () {
      final uri = manageSubscriptionUri(
        isIOS: false,
        isAndroid: true,
        androidPackageName: null,
        androidProductId: 'collectiq_pro_monthly',
      );

      expect(uri, isNull);
    });

    test('Android with no product id returns null, not a broken URL', () {
      final uri = manageSubscriptionUri(
        isIOS: false,
        isAndroid: true,
        androidPackageName: 'com.collectiq.ai',
        androidProductId: null,
      );

      expect(uri, isNull);
    });

    test('neither platform (e.g. a desktop/test host) returns null', () {
      final uri = manageSubscriptionUri(isIOS: false, isAndroid: false);

      expect(uri, isNull);
    });
  });
}
