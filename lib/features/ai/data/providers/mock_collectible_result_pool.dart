import 'dart:io';
import 'dart:typed_data';

import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';

class MockCollectibleResultPool {
  const MockCollectibleResultPool();

  static const templates = <MockCollectibleTemplate>[
    MockCollectibleTemplate(
      title: '1999 Pokemon Charizard Holo',
      category: 'Pokemon Card',
      year: '1999',
      brand: 'Pokemon',
      setName: 'Base Set',
      series: 'Pokemon TCG',
      cardNumber: '4/102',
      character: 'Charizard',
      rarity: 'Holo Rare',
      condition: 'Near Mint',
      value: 1850,
      low: 1443,
      high: 2257,
      confidence: 0.94,
      grade: 'PSA 8-9',
      material: 'Cardstock',
      notes: 'Verify holo surface, edition, and back centering.',
    ),
    MockCollectibleTemplate(
      title: '1999 Pokemon Blastoise Holo',
      category: 'Pokemon Card',
      year: '1999',
      brand: 'Pokemon',
      setName: 'Base Set',
      series: 'Pokemon TCG',
      cardNumber: '2/102',
      character: 'Blastoise',
      rarity: 'Holo Rare',
      condition: 'Excellent',
      value: 620,
      low: 480,
      high: 780,
      confidence: 0.88,
      grade: 'PSA 7-8',
      material: 'Cardstock',
      notes: 'Check holo scratching and edge whitening.',
    ),
    MockCollectibleTemplate(
      title: '2000 Pokemon Lugia Neo Genesis Holo',
      category: 'Pokemon Card',
      year: '2000',
      brand: 'Pokemon',
      setName: 'Neo Genesis',
      series: 'Pokemon TCG',
      cardNumber: '9/111',
      character: 'Lugia',
      rarity: 'Holo Rare',
      condition: 'Lightly Played',
      value: 410,
      low: 290,
      high: 560,
      confidence: 0.84,
      grade: 'PSA 6-7',
      material: 'Cardstock',
      notes: 'Confirm Neo Genesis symbol and holo condition.',
    ),
    MockCollectibleTemplate(
      title: '2002 Pokemon Expedition Mewtwo Reverse Holo',
      category: 'Pokemon Card',
      year: '2002',
      brand: 'Pokemon',
      setName: 'Expedition',
      series: 'e-Card',
      cardNumber: '20/165',
      character: 'Mewtwo',
      rarity: 'Reverse Holo',
      condition: 'Very Good',
      value: 185,
      low: 125,
      high: 260,
      confidence: 0.80,
      grade: 'Raw VG',
      material: 'Cardstock',
      notes: 'E-reader strip and reverse holo surface need close inspection.',
    ),
    MockCollectibleTemplate(
      title: '1986 Fleer Michael Jordan Rookie',
      category: 'Sports Card',
      year: '1986',
      brand: 'Fleer',
      setName: 'Fleer Basketball',
      series: 'NBA',
      cardNumber: '57',
      character: 'Michael Jordan',
      rarity: 'Rookie Card',
      condition: 'Excellent',
      value: 4200,
      low: 3100,
      high: 5600,
      confidence: 0.89,
      grade: 'PSA 6-7',
      material: 'Cardstock',
      notes: 'Centering and print dots drive value.',
    ),
    MockCollectibleTemplate(
      title: '1989 Upper Deck Ken Griffey Jr. Rookie',
      category: 'Sports Card',
      year: '1989',
      brand: 'Upper Deck',
      setName: 'Upper Deck Baseball',
      series: 'MLB',
      cardNumber: '1',
      character: 'Ken Griffey Jr.',
      rarity: 'Rookie Card',
      condition: 'Near Mint',
      value: 140,
      low: 95,
      high: 210,
      confidence: 0.87,
      grade: 'PSA 8-9',
      material: 'Cardstock',
      notes: 'Look for hologram condition and corner sharpness.',
    ),
    MockCollectibleTemplate(
      title: '1993 SP Derek Jeter Foil Rookie',
      category: 'Sports Card',
      year: '1993',
      brand: 'SP',
      setName: 'SP Baseball',
      series: 'MLB',
      cardNumber: '279',
      character: 'Derek Jeter',
      rarity: 'Foil Rookie',
      condition: 'Excellent',
      value: 520,
      low: 360,
      high: 760,
      confidence: 0.82,
      grade: 'PSA 7',
      material: 'Foil cardstock',
      notes: 'Foil scratches and edge chipping are common.',
    ),
    MockCollectibleTemplate(
      title: '1921 Morgan Silver Dollar',
      category: 'Coin',
      year: '1921',
      brand: 'United States Mint',
      series: 'Morgan Dollar',
      condition: 'Very Fine',
      value: 145,
      low: 95,
      high: 210,
      confidence: 0.87,
      grade: 'VF',
      country: 'United States',
      mint: 'Philadelphia',
      material: '90% silver',
      notes: 'Do not clean; confirm mint mark and rim wear.',
    ),
    MockCollectibleTemplate(
      title: '1964 Kennedy Half Dollar',
      category: 'Coin',
      year: '1964',
      brand: 'United States Mint',
      series: 'Kennedy Half Dollar',
      condition: 'About Uncirculated',
      value: 24,
      low: 14,
      high: 42,
      confidence: 0.83,
      grade: 'AU',
      country: 'United States',
      mint: 'Denver',
      material: '90% silver',
      notes: 'Silver content sets a floor; cameo surfaces can add value.',
    ),
    MockCollectibleTemplate(
      title: '1911 Australian Half Sovereign',
      category: 'Coin',
      year: '1911',
      brand: 'Royal Mint',
      series: 'Half Sovereign',
      condition: 'Fine',
      value: 385,
      low: 300,
      high: 520,
      confidence: 0.78,
      grade: 'F',
      country: 'Australia',
      mint: 'Sydney',
      material: 'Gold',
      notes: 'Confirm weight and mint mark for authenticity.',
    ),
    MockCollectibleTemplate(
      title: 'Transformers Optimus Prime G1 Figure',
      category: 'Action Figure',
      year: '1984',
      brand: 'Hasbro',
      series: 'Transformers Generation 1',
      character: 'Optimus Prime',
      rarity: 'Vintage Figure',
      condition: 'Good',
      value: 260,
      low: 170,
      high: 380,
      confidence: 0.84,
      grade: 'Loose Good',
      country: 'Japan',
      material: 'Plastic and die-cast metal',
      notes: 'Trailer, fists, blaster, and stickers affect value.',
    ),
    MockCollectibleTemplate(
      title: 'Star Wars 1978 Darth Vader 12-Back',
      category: 'Action Figure',
      year: '1978',
      brand: 'Kenner',
      series: 'Star Wars',
      character: 'Darth Vader',
      rarity: '12-Back',
      condition: 'Loose Complete',
      value: 310,
      low: 220,
      high: 470,
      confidence: 0.82,
      grade: 'Loose Complete',
      country: 'United States',
      material: 'Plastic',
      notes: 'Check cape, saber tip, COO stamp, and limb tightness.',
    ),
    MockCollectibleTemplate(
      title: 'GI Joe Snake Eyes V2 Figure',
      category: 'Action Figure',
      year: '1985',
      brand: 'Hasbro',
      series: 'GI Joe: A Real American Hero',
      character: 'Snake Eyes',
      rarity: 'Vintage Figure',
      condition: 'Very Good',
      value: 120,
      low: 80,
      high: 180,
      confidence: 0.80,
      grade: 'Loose VG',
      material: 'Plastic',
      notes: 'Wolf companion and accessories materially change value.',
    ),
    MockCollectibleTemplate(
      title: 'Amazing Spider-Man #300',
      category: 'Comic Book',
      year: '1988',
      brand: 'Marvel Comics',
      series: 'Amazing Spider-Man',
      cardNumber: '#300',
      character: 'Spider-Man / Venom',
      rarity: 'Key Issue',
      condition: 'Fine',
      value: 900,
      low: 620,
      high: 1250,
      confidence: 0.91,
      grade: 'Fine',
      material: 'Paper',
      notes: 'First full Venom appearance; spine ticks affect grade.',
    ),
    MockCollectibleTemplate(
      title: 'Uncanny X-Men #266',
      category: 'Comic Book',
      year: '1990',
      brand: 'Marvel Comics',
      series: 'Uncanny X-Men',
      cardNumber: '#266',
      character: 'Gambit',
      rarity: 'Key Issue',
      condition: 'Very Fine',
      value: 180,
      low: 120,
      high: 260,
      confidence: 0.86,
      grade: 'VF',
      material: 'Paper',
      notes: 'First full Gambit; inspect spine and cover gloss.',
    ),
    MockCollectibleTemplate(
      title: 'Batman: The Killing Joke First Print',
      category: 'Comic Book',
      year: '1988',
      brand: 'DC Comics',
      series: 'Batman',
      character: 'Batman / Joker',
      rarity: 'First Print',
      condition: 'Near Mint',
      value: 110,
      low: 75,
      high: 170,
      confidence: 0.84,
      grade: 'NM-',
      material: 'Paper',
      notes: 'Confirm first-print indicators and squarebound spine condition.',
    ),
    MockCollectibleTemplate(
      title: 'Penny Black Stamp',
      category: 'Stamp',
      year: '1840',
      brand: 'Royal Mail',
      series: 'Victorian Definitive',
      rarity: 'Classic Stamp',
      condition: 'Used',
      value: 190,
      low: 100,
      high: 320,
      confidence: 0.77,
      grade: 'Used Fine',
      country: 'United Kingdom',
      material: 'Gummed paper',
      notes: 'Margins, cancellation, and plate position drive value.',
    ),
    MockCollectibleTemplate(
      title: '1918 Inverted Jenny Stamp Reproduction',
      category: 'Stamp',
      year: '1918',
      brand: 'US Post Office',
      series: 'Airmail',
      rarity: 'Reproduction',
      condition: 'Mint Hinged',
      value: 35,
      low: 18,
      high: 60,
      confidence: 0.73,
      grade: 'MH',
      country: 'United States',
      material: 'Gummed paper',
      notes:
          'Treat as reproduction unless expert certification confirms otherwise.',
    ),
    MockCollectibleTemplate(
      title: 'Pokemon Red Game Boy Cartridge',
      category: 'Retro Game',
      year: '1998',
      brand: 'Nintendo',
      series: 'Game Boy',
      character: 'Pokemon',
      rarity: 'Loose Cartridge',
      condition: 'Good',
      value: 85,
      low: 55,
      high: 130,
      confidence: 0.85,
      material: 'Plastic cartridge',
      notes: 'Battery save function and label wear affect value.',
    ),
    MockCollectibleTemplate(
      title: 'The Legend of Zelda NES Gold Cartridge',
      category: 'Retro Game',
      year: '1987',
      brand: 'Nintendo',
      series: 'NES',
      character: 'Link',
      rarity: 'Gold Cartridge',
      condition: 'Very Good',
      value: 120,
      low: 80,
      high: 190,
      confidence: 0.86,
      material: 'Plastic cartridge',
      notes: 'Gold label scratches and save battery should be checked.',
    ),
    MockCollectibleTemplate(
      title: 'Super Mario 64 Nintendo 64 Cart',
      category: 'Retro Game',
      year: '1996',
      brand: 'Nintendo',
      series: 'Nintendo 64',
      character: 'Mario',
      rarity: 'Launch Title',
      condition: 'Good',
      value: 65,
      low: 40,
      high: 95,
      confidence: 0.82,
      material: 'Plastic cartridge',
      notes: 'Label fading and regional variant matter.',
    ),
    MockCollectibleTemplate(
      title: 'Magic: The Gathering Black Lotus Collector Edition',
      category: 'Trading Card',
      year: '1993',
      brand: 'Wizards of the Coast',
      setName: 'Collector Edition',
      series: 'Magic: The Gathering',
      character: 'Black Lotus',
      rarity: 'Rare',
      condition: 'Lightly Played',
      value: 1200,
      low: 850,
      high: 1650,
      confidence: 0.79,
      grade: 'Raw LP',
      material: 'Cardstock',
      notes:
          'Square corners and CE back distinguish this from tournament-legal copies.',
    ),
    MockCollectibleTemplate(
      title: 'Yu-Gi-Oh! Blue-Eyes White Dragon SDK-001',
      category: 'Trading Card',
      year: '2002',
      brand: 'Konami',
      setName: 'Starter Deck Kaiba',
      series: 'Yu-Gi-Oh!',
      cardNumber: 'SDK-001',
      character: 'Blue-Eyes White Dragon',
      rarity: 'Ultra Rare',
      condition: 'Near Mint',
      value: 210,
      low: 135,
      high: 320,
      confidence: 0.84,
      grade: 'Raw NM',
      material: 'Cardstock',
      notes: 'Check foil scratching and first-edition mark.',
    ),
    MockCollectibleTemplate(
      title: 'Lorcana Elsa Spirit of Winter Enchanted',
      category: 'Trading Card',
      year: '2023',
      brand: 'Ravensburger',
      setName: 'The First Chapter',
      series: 'Disney Lorcana',
      character: 'Elsa',
      rarity: 'Enchanted',
      condition: 'Near Mint',
      value: 760,
      low: 560,
      high: 980,
      confidence: 0.80,
      grade: 'Raw NM',
      material: 'Cardstock',
      notes: 'Foil quality and centering are key for grading.',
    ),
    MockCollectibleTemplate(
      title: '1983 Cabbage Patch Kids Doll',
      category: 'Vintage Toy',
      year: '1983',
      brand: 'Coleco',
      series: 'Cabbage Patch Kids',
      rarity: 'First Wave',
      condition: 'Good',
      value: 95,
      low: 55,
      high: 150,
      confidence: 0.78,
      material: 'Fabric and vinyl',
      notes: 'Birth certificate, tags, and original clothing affect value.',
    ),
    MockCollectibleTemplate(
      title: '1982 Masters of the Universe He-Man Figure',
      category: 'Vintage Toy',
      year: '1982',
      brand: 'Mattel',
      series: 'Masters of the Universe',
      character: 'He-Man',
      rarity: 'Vintage Figure',
      condition: 'Loose Good',
      value: 70,
      low: 42,
      high: 115,
      confidence: 0.81,
      material: 'Plastic',
      notes: 'Chest emblem, power sword, and rubber legs need inspection.',
    ),
    MockCollectibleTemplate(
      title: 'Hot Wheels Redline Custom Camaro',
      category: 'Vintage Toy',
      year: '1968',
      brand: 'Mattel',
      series: 'Hot Wheels Redline',
      rarity: 'Redline',
      condition: 'Play Worn',
      value: 180,
      low: 90,
      high: 310,
      confidence: 0.76,
      material: 'Die-cast metal',
      notes: 'Paint color, wheel condition, and base text drive value.',
    ),
    MockCollectibleTemplate(
      title: 'Teenage Mutant Ninja Turtles Leonardo Figure',
      category: 'Vintage Toy',
      year: '1988',
      brand: 'Playmates',
      series: 'TMNT',
      character: 'Leonardo',
      rarity: 'Soft Head Variant',
      condition: 'Very Good',
      value: 85,
      low: 55,
      high: 135,
      confidence: 0.79,
      material: 'Plastic',
      notes: 'Weapon rack completeness and soft-head variant affect value.',
    ),
    MockCollectibleTemplate(
      title: '1990 Marvel Universe Series 1 Wolverine',
      category: 'Trading Card',
      year: '1990',
      brand: 'Impel',
      setName: 'Marvel Universe Series 1',
      series: 'Marvel Cards',
      cardNumber: '23',
      character: 'Wolverine',
      rarity: 'Base Card',
      condition: 'Near Mint',
      value: 38,
      low: 20,
      high: 70,
      confidence: 0.83,
      material: 'Cardstock',
      notes: 'Centering and corner whitening are the main condition checks.',
    ),
    MockCollectibleTemplate(
      title: '1992 SkyBox Dream Team Michael Jordan',
      category: 'Sports Card',
      year: '1992',
      brand: 'SkyBox',
      setName: 'USA Basketball',
      series: 'Olympics',
      cardNumber: 'USA11',
      character: 'Michael Jordan',
      rarity: 'Dream Team',
      condition: 'Near Mint',
      value: 55,
      low: 32,
      high: 90,
      confidence: 0.84,
      material: 'Cardstock',
      notes: 'Dream Team cards are condition-sensitive but widely collected.',
    ),
    MockCollectibleTemplate(
      title: '1963 Topps Pete Rose Rookie',
      category: 'Sports Card',
      year: '1963',
      brand: 'Topps',
      setName: 'Topps Baseball',
      series: 'MLB',
      cardNumber: '537',
      character: 'Pete Rose',
      rarity: 'Rookie Card',
      condition: 'Good',
      value: 950,
      low: 650,
      high: 1350,
      confidence: 0.77,
      grade: 'PSA 3-4',
      material: 'Cardstock',
      notes: 'Four-player rookie layout and centering need close review.',
    ),
  ];

  Future<RecognitionResult> resultFor(AiAnalysisRequest request) async {
    final seed = await seedFor(request);
    return templates[indexForSeed(seed)].toRecognitionResult(
      imageUrl: request.imagePath.startsWith('sample://')
          ? request.imagePath
          : null,
    );
  }

  Future<int> seedFor(AiAnalysisRequest request) async {
    final image = request.image;
    if (image != null) {
      try {
        final imagePath = image.path.trim();
        if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
          return hashBytes(File(imagePath).readAsBytesSync());
        }
        return hashBytes(await image.readAsBytes());
      } on Object {
        // Fall back to path hashing below.
      }
    }

    final path = request.imagePath.trim();
    if (path.isNotEmpty &&
        !path.startsWith('sample://') &&
        !path.startsWith('http://') &&
        !path.startsWith('https://') &&
        File(path).existsSync()) {
      try {
        return hashBytes(File(path).readAsBytesSync());
      } on Object {
        // Fall back to path hashing below.
      }
    }

    if (path == 'sample://sports-card') {
      return 0;
    }

    return hashString('$path-${DateTime.now().microsecondsSinceEpoch}');
  }

  static int indexForSeed(int seed) {
    return seed.abs() % templates.length;
  }

  static int hashBytes(Uint8List bytes) {
    var hash = 0;
    for (final byte in bytes) {
      hash = 0x1fffffff & (hash + byte);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash;
  }

  static int hashString(String value) {
    return hashBytes(Uint8List.fromList(value.codeUnits));
  }
}

class MockCollectibleTemplate {
  const MockCollectibleTemplate({
    required this.title,
    required this.category,
    required this.year,
    required this.brand,
    required this.condition,
    required this.value,
    required this.low,
    required this.high,
    required this.confidence,
    required this.notes,
    this.setName,
    this.series,
    this.cardNumber,
    this.character,
    this.rarity,
    this.grade,
    this.language = 'English',
    this.edition,
    this.country,
    this.mint,
    this.material,
  });

  final String title;
  final String category;
  final String? year;
  final String brand;
  final String? setName;
  final String? series;
  final String? cardNumber;
  final String? character;
  final String? rarity;
  final String condition;
  final double value;
  final double low;
  final double high;
  final double confidence;
  final String? grade;
  final String? language;
  final String? edition;
  final String? country;
  final String? mint;
  final String? material;
  final String notes;

  RecognitionResult toRecognitionResult({String? imageUrl}) {
    return RecognitionResult(
      success: true,
      filename: null,
      imageUrl: imageUrl,
      title: title,
      category: category,
      confidence: confidence,
      description: _description,
      estimatedValue: value,
      condition: condition,
      recommendation: _recommendation,
      primaryMatch: title,
      alternativeMatches: _alternatives,
      confidenceExplanation:
          'Mock confidence is based on visible collectible type, era, brand, and condition cues.',
      detectionQuality:
          'Good - mock SIT analysis assumes the main collectible is visible enough for review.',
      aiReasoning:
          'SIT mock result selected from a varied collectible pool using the uploaded image signal.',
      pricing: PricingInfo(
        estimatedMarketValue: value,
        lowEstimate: low,
        highEstimate: high,
        currency: 'AUD',
        pricingSource: 'SIT mock market range',
        pricingConfidence: (confidence - 0.06).clamp(0.55, 0.92),
        lastUpdated: DateTime.parse('2026-07-01T00:00:00Z'),
      ),
      year: year,
      brand: brand,
      setName: setName,
      series: series,
      cardNumber: cardNumber,
      playerOrCharacter: character,
      rarity: rarity,
      estimatedGrade: grade,
      language: language,
      edition: edition,
      country: country,
      mint: mint,
      material: material,
      notes: '$notes SIT MOCK DATA - verify before sale or grading.',
    );
  }

  String get _description {
    return 'Realistic SIT mock match for $title with a market range of AUD '
        '${low.toStringAsFixed(0)}-${high.toStringAsFixed(0)}.';
  }

  String get _recommendation {
    if (category.contains('Card') || category == 'Trading Card') {
      return 'Sleeve it, verify authenticity, and inspect centering before grading.';
    }
    if (category == 'Coin' || category == 'Stamp') {
      return 'Avoid cleaning and confirm authenticity with close-up inspection.';
    }
    if (category.contains('Comic')) {
      return 'Bag and board it, then inspect spine, staples, and page color.';
    }
    return 'Document condition and accessories before saving or listing.';
  }

  List<RecognitionAlternativeMatch> get _alternatives {
    return [
      RecognitionAlternativeMatch(
        title: '$title variant',
        category: category,
        confidence: (confidence - 0.12).clamp(0.45, 0.82),
        reason:
            'Same collectible family with variant-specific details to verify.',
      ),
      RecognitionAlternativeMatch(
        title: '$brand related collectible',
        category: category,
        confidence: (confidence - 0.20).clamp(0.38, 0.76),
        reason: 'Brand and era overlap, but exact identifiers may differ.',
      ),
      RecognitionAlternativeMatch(
        title: 'Similar era $category',
        category: category,
        confidence: (confidence - 0.28).clamp(0.30, 0.68),
        reason: 'Comparable category and period; needs manual confirmation.',
      ),
    ];
  }
}
