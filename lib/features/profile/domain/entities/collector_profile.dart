class CollectorProfile {
  const CollectorProfile({
    required this.displayName,
    this.avatarPath,
    this.countryCode = defaultCountryCode,
    this.preferredCurrency = defaultPreferredCurrency,
  });

  static const defaultDisplayName = 'PackLox Collector';
  static const defaultCountryCode = 'AU';

  /// What a collector reads in before they choose. USD because that is what
  /// the pricing providers quote and what values are stored in --
  /// PriceCharting and SportsCardsPro are USD-only -- so the untouched
  /// default shows provider prices with no conversion applied at all.
  /// Picking a country in Settings still sets the matching currency.
  static const defaultPreferredCurrency = 'USD';

  final String displayName;
  final String? avatarPath;
  final String countryCode;
  final String preferredCurrency;

  String get countryName => countryNameFor(countryCode);

  CollectorProfile copyWith({
    String? displayName,
    String? avatarPath,
    String? countryCode,
    String? preferredCurrency,
  }) {
    return CollectorProfile(
      displayName: displayName ?? this.displayName,
      avatarPath: avatarPath ?? this.avatarPath,
      countryCode: normalizeCountryCode(countryCode ?? this.countryCode),
      preferredCurrency: normalizeCurrency(
        preferredCurrency ?? this.preferredCurrency,
      ),
    );
  }

  static String normalizeCountryCode(String value) {
    final normalized = value.trim().toUpperCase();
    return switch (normalized) {
      'US' || 'USA' || 'UNITED STATES' => 'US',
      'CA' || 'CAN' || 'CANADA' => 'CA',
      'GB' || 'UK' || 'UNITED KINGDOM' => 'GB',
      'AU' || 'AUS' || 'AUSTRALIA' || '' => 'AU',
      _ => 'AU',
    };
  }

  static String normalizeCurrency(String value) {
    final normalized = value.trim().toUpperCase();
    return switch (normalized) {
      'USD' || 'CAD' || 'GBP' || 'AUD' => normalized,
      _ => defaultPreferredCurrency,
    };
  }

  static String currencyForCountry(String countryCode) {
    return switch (normalizeCountryCode(countryCode)) {
      'US' => 'USD',
      'CA' => 'CAD',
      'GB' => 'GBP',
      _ => 'AUD',
    };
  }

  static String countryNameFor(String countryCode) {
    return switch (normalizeCountryCode(countryCode)) {
      'US' => 'United States',
      'CA' => 'Canada',
      'GB' => 'United Kingdom',
      _ => 'Australia',
    };
  }
}
