/// Input for future collectible market-pricing providers.
class MarketPricingRequest {
  /// Creates an immutable pricing request.
  const MarketPricingRequest({
    required this.title,
    required this.category,
    this.condition,
    this.year,
    this.brand,
    this.setName,
    this.cardNumber,
    this.playerOrCharacter,
    this.currency = 'AUD',
    this.asOfDate,
    this.imageSource,
    this.localImagePath,
  });

  /// Recognized collectible title/name.
  final String title;

  /// Recognized collectible category/type.
  final String category;

  /// Optional condition estimate.
  final String? condition;

  /// Optional collectible year.
  final String? year;

  /// Optional brand/manufacturer.
  final String? brand;

  /// Optional set or release name.
  final String? setName;

  /// Optional card/catalog number.
  final String? cardNumber;

  /// Optional player or character name.
  final String? playerOrCharacter;

  /// Preferred currency.
  final String currency;

  /// Optional pricing date, useful for deterministic tests.
  final DateTime? asOfDate;

  /// Optional scanner image source such as camera, gallery, or sample.
  final String? imageSource;

  /// Optional local image path/reference metadata.
  final String? localImagePath;
}
