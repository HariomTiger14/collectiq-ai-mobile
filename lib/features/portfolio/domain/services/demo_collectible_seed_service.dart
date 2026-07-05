import 'package:collectiq_ai/features/market/domain/entities/market_summary.dart';
import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const packLoxDemoSeedItemCount = 500;
const packLoxDemoItemIdPrefix = 'packlox-demo-';

final demoSeedEnabledProvider = Provider<bool>((ref) {
  return const bool.fromEnvironment('PACKLOX_DEMO_SEED');
});

class DemoCollectibleSeedService {
  const DemoCollectibleSeedService();

  static const categories = [
    'Trading Cards',
    'Pokemon/TCG',
    'Sports Cards',
    'Coins',
    'Banknotes',
    'Comics',
    'Action Figures',
    'Sneakers',
    'Watches',
    'Stamps',
    'Books',
    'Vinyl Records',
    'Video Games',
    'Toys',
    'Memorabilia',
    'Antiques',
    'Art/Prints',
    'Cameras',
    'LEGO/Building Sets',
    'Other Collectibles',
  ];

  List<CollectibleItem> generateItems({DateTime? anchorDate}) {
    final baseDate = anchorDate ?? DateTime.utc(2026, 7, 1, 12);
    return [
      for (var index = 0; index < packLoxDemoSeedItemCount; index++)
        _buildItem(index, baseDate),
    ];
  }

  Future<int> seedPortfolio(PortfolioRepository repository) async {
    final items = generateItems();
    for (final item in items) {
      await repository.upsertSyncedItem(item);
    }
    return items.length;
  }

  Future<int> clearDemoItems(PortfolioRepository repository) async {
    final items = await repository.getItems();
    var removed = 0;
    for (final item in items) {
      if (isDemoItem(item)) {
        await repository.removeItem(item.id);
        removed++;
      }
    }
    return removed;
  }

  static bool isDemoItem(CollectibleItem item) {
    return item.id.startsWith(packLoxDemoItemIdPrefix) ||
        (item.notes?.contains('DEMO MOCK DATA') ?? false);
  }

  CollectibleItem _buildItem(int index, DateTime baseDate) {
    final category = categories[index % categories.length];
    final categoryRound = index ~/ categories.length;
    final sequence = index + 1;
    final title = _titleFor(category, categoryRound, sequence);
    final value = _valueFor(category, categoryRound, index);
    final confidence = 0.68 + ((index * 7) % 27) / 100;
    final year = _yearFor(category, categoryRound, index);
    final condition = _conditionFor(index);
    final trend = _trendFor(index);
    final createdAt = baseDate.subtract(Duration(days: index % 180));

    return CollectibleItem(
      id: '$packLoxDemoItemIdPrefix${sequence.toString().padLeft(4, '0')}',
      title: title,
      category: category,
      estimatedValue: value,
      confidence: confidence.clamp(0.0, 0.96),
      condition: condition,
      recommendation:
          'Demo/mock record for local portfolio testing. Verify real items with independent sources.',
      imagePath: 'sample://demo-${_slug(category)}',
      createdAt: createdAt,
      pricing: PricingInfo(
        estimatedMarketValue: value,
        lowEstimate: value * 0.78,
        highEstimate: value * 1.24,
        currency: 'AUD',
        pricingSource: 'PackLox demo seed (mock)',
        pricingConfidence: 0.62 + ((index * 5) % 22) / 100,
        lastUpdated: createdAt,
      ),
      marketSummary: MarketSummary(
        averagePrice: value,
        medianPrice: value * 0.96,
        lowPrice: value * 0.72,
        highPrice: value * 1.32,
        salesCount: 3 + (index % 42),
        trendLabel: trend,
        confidence: 0.60 + ((index * 3) % 30) / 100,
        lastUpdated: createdAt,
        sources: const ['PackLox demo/mock dataset'],
        comps: const [],
      ),
      primaryMatch: title,
      confidenceExplanation:
          'Generated demo/mock confidence based on category and condition variety.',
      detectionQuality: index % 5 == 0 ? 'Good' : 'High',
      aiReasoning:
          'DEMO MOCK DATA: synthetic item summary for local UI, search, filter, sort, and detail testing only.',
      year: year,
      brand: _brandFor(category, index),
      setName: _setNameFor(category, categoryRound),
      series: _seriesFor(category, categoryRound),
      cardNumber: _cardNumberFor(category, sequence),
      playerOrCharacter: _subjectFor(category, index),
      rarity: _rarityFor(index),
      estimatedGrade: _gradeFor(category, index),
      language: index % 9 == 0 ? 'Japanese' : 'English',
      edition: _editionFor(index),
      country: _countryFor(category, index),
      mint: _mintFor(category, index),
      material: _materialFor(category, index),
      notes:
          'DEMO MOCK DATA - local-only PackLox seed record. Source: synthetic demo generator. Do not treat as real inventory.',
    );
  }

  String _titleFor(String category, int round, int sequence) {
    final suffix = sequence.toString().padLeft(3, '0');
    return switch (category) {
      'Trading Cards' => 'Demo Foil Dragon Card #$suffix',
      'Pokemon/TCG' => 'Demo Electric Mouse Holo TCG #$suffix',
      'Sports Cards' => 'Demo Rookie Forward Card #$suffix',
      'Coins' => 'Demo Silver Crown Coin #$suffix',
      'Banknotes' => 'Demo Commonwealth Banknote #$suffix',
      'Comics' => 'Demo Cosmic Hero Comic #$suffix',
      'Action Figures' => 'Demo Space Ranger Figure #$suffix',
      'Sneakers' => 'Demo Limited Runner Sneakers #$suffix',
      'Watches' => 'Demo Automatic Field Watch #$suffix',
      'Stamps' => 'Demo Airmail Stamp Pair #$suffix',
      'Books' => 'Demo First Edition Adventure Book #$suffix',
      'Vinyl Records' => 'Demo Blue Note Vinyl Pressing #$suffix',
      'Video Games' => 'Demo Cartridge Adventure Game #$suffix',
      'Toys' => 'Demo Tin Wind-Up Toy #$suffix',
      'Memorabilia' => 'Demo Signed Event Program #$suffix',
      'Antiques' => 'Demo Brass Desk Compass #$suffix',
      'Art/Prints' => 'Demo Numbered Gallery Print #$suffix',
      'Cameras' => 'Demo Rangefinder Camera #$suffix',
      'LEGO/Building Sets' => 'Demo Modular Building Set #$suffix',
      _ => 'Demo Collector Lot ${round + 1} #$suffix',
    };
  }

  double _valueFor(String category, int round, int index) {
    final base = switch (category) {
      'Trading Cards' => 35,
      'Pokemon/TCG' => 55,
      'Sports Cards' => 42,
      'Coins' => 90,
      'Banknotes' => 70,
      'Comics' => 65,
      'Action Figures' => 48,
      'Sneakers' => 180,
      'Watches' => 420,
      'Stamps' => 32,
      'Books' => 85,
      'Vinyl Records' => 60,
      'Video Games' => 95,
      'Toys' => 45,
      'Memorabilia' => 120,
      'Antiques' => 240,
      'Art/Prints' => 210,
      'Cameras' => 260,
      'LEGO/Building Sets' => 150,
      _ => 50,
    };
    final variation = (index % 17) * 7.5 + round * 18;
    return double.parse((base + variation).toStringAsFixed(2));
  }

  String _yearFor(String category, int round, int index) {
    final base = switch (category) {
      'Coins' || 'Banknotes' || 'Stamps' || 'Antiques' => 1925,
      'Comics' || 'Books' || 'Vinyl Records' || 'Cameras' => 1960,
      'Video Games' || 'Action Figures' || 'Toys' => 1984,
      'Sneakers' || 'Watches' || 'LEGO/Building Sets' => 1998,
      _ => 2004,
    };
    return (base + ((round * 3 + index) % 24)).toString();
  }

  String _conditionFor(int index) {
    const values = [
      'Mint',
      'Near Mint',
      'Excellent',
      'Very Good',
      'Good',
      'Lightly Used',
      'Display Wear',
    ];
    return values[index % values.length];
  }

  String _trendFor(int index) {
    const values = ['Stable', 'Rising', 'Cooling', 'Volatile'];
    return values[index % values.length];
  }

  String _brandFor(String category, int index) {
    return switch (category) {
      'Watches' => 'Demo Horology Co.',
      'Sneakers' => 'Demo Athletics',
      'Cameras' => 'Demo Optics',
      'LEGO/Building Sets' => 'Demo Brick Studio',
      'Video Games' => 'Demo Game Works',
      _ => 'PackLox Demo',
    };
  }

  String? _setNameFor(String category, int round) {
    if (category.contains('Card') || category == 'Pokemon/TCG') {
      return 'Demo Collector Series ${round % 5 + 1}';
    }
    if (category == 'LEGO/Building Sets') {
      return 'Demo City Blocks';
    }
    return null;
  }

  String? _seriesFor(String category, int round) {
    if (category == 'Comics') {
      return 'Demo Cosmic Run';
    }
    if (category == 'Vinyl Records') {
      return 'Demo Jazz Sessions';
    }
    if (category == 'Video Games') {
      return 'Demo Cartridge Classics';
    }
    return round.isEven ? 'Demo Archive' : null;
  }

  String? _cardNumberFor(String category, int sequence) {
    if (!category.contains('Card') && category != 'Pokemon/TCG') {
      return null;
    }
    return '${sequence % 199 + 1}/200';
  }

  String? _subjectFor(String category, int index) {
    return switch (category) {
      'Sports Cards' => 'Demo Player ${index % 25 + 1}',
      'Action Figures' => 'Demo Hero ${index % 18 + 1}',
      'Memorabilia' => 'Demo Performer ${index % 12 + 1}',
      'Pokemon/TCG' => 'Demo Creature ${index % 30 + 1}',
      _ => null,
    };
  }

  String _rarityFor(int index) {
    const values = ['Common', 'Uncommon', 'Rare', 'Limited', 'Promo'];
    return values[index % values.length];
  }

  String? _gradeFor(String category, int index) {
    if (category.contains('Card') || category == 'Pokemon/TCG') {
      return 'PSA ${(index % 5) + 6} equivalent';
    }
    if (category == 'Coins' || category == 'Banknotes') {
      return index.isEven ? 'AU' : 'VF';
    }
    return null;
  }

  String _editionFor(int index) {
    const values = ['Demo Standard', 'Demo First Run', 'Demo Limited'];
    return values[index % values.length];
  }

  String? _countryFor(String category, int index) {
    if (category == 'Coins' ||
        category == 'Banknotes' ||
        category == 'Stamps') {
      const countries = [
        'Australia',
        'United States',
        'Japan',
        'United Kingdom',
      ];
      return countries[index % countries.length];
    }
    return null;
  }

  String? _mintFor(String category, int index) {
    if (category != 'Coins') {
      return null;
    }
    const mints = ['Perth', 'Melbourne', 'Denver', 'Royal Mint'];
    return mints[index % mints.length];
  }

  String? _materialFor(String category, int index) {
    return switch (category) {
      'Coins' => index.isEven ? 'Silver' : 'Copper alloy',
      'Watches' => index.isEven ? 'Stainless steel' : 'Titanium',
      'Antiques' => index.isEven ? 'Brass' : 'Walnut',
      'Art/Prints' => 'Archival paper',
      _ => null,
    };
  }

  String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
