import 'package:collectiq_ai/features/profile/data/repositories/shared_preferences_profile_repository.dart';
import 'package:collectiq_ai/features/profile/domain/entities/collector_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const repository = SharedPreferencesProfileRepository();

  test('an untouched install reads in the default currency', () async {
    // The default used to be unreachable: normalizeCountryCode maps an empty
    // string to AU, so loadProfile derived AUD from a country the collector
    // had never chosen, whatever defaultPreferredCurrency said.
    SharedPreferences.setMockInitialValues({});

    final profile = await repository.loadProfile();

    expect(profile.preferredCurrency, CollectorProfile.defaultPreferredCurrency);
    expect(profile.preferredCurrency, 'USD');
  });

  test('a chosen country still sets its own currency', () async {
    SharedPreferences.setMockInitialValues({
      'packlox.profile.country_code': 'AU',
    });

    final profile = await repository.loadProfile();

    expect(profile.preferredCurrency, 'AUD');
  });

  test('an explicitly saved currency always wins', () async {
    SharedPreferences.setMockInitialValues({
      'packlox.profile.country_code': 'AU',
      'packlox.profile.preferred_currency': 'GBP',
    });

    final profile = await repository.loadProfile();

    expect(profile.preferredCurrency, 'GBP');
  });
}
