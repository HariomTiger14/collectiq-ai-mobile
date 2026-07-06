import 'package:collectiq_ai/core/utils/json_parse.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_comp.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_summary.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';

/// Future backend analysis request sent by Flutter to CollectIQ AI backend.
///
/// The request contains image metadata only. The image upload body/transport can
/// be multipart later, but API keys must never be sent from Flutter.
class AiBackendAnalysisRequest {
  const AiBackendAnalysisRequest({
    required this.imagePath,
    required this.imageSource,
    required this.timestamp,
    this.requestedCategory,
    this.appVersion,
    this.deviceMetadata = const {},
    this.images = const [],
    this.scanGoal,
    this.confidenceTarget,
    this.scannerUxVersion,
    this.qualityMetadata = const {},
  });

  final String imagePath;
  final String imageSource;
  final DateTime timestamp;
  final String? requestedCategory;
  final String? appVersion;
  final Map<String, String> deviceMetadata;
  final List<AiBackendAnalysisImage> images;
  final String? scanGoal;
  final double? confidenceTarget;
  final String? scannerUxVersion;
  final Map<String, Object?> qualityMetadata;

  Map<String, dynamic> toJson() {
    return {
      'imagePath': imagePath,
      'imageSource': imageSource,
      'requestedCategory': requestedCategory,
      'appVersion': appVersion,
      'deviceMetadata': deviceMetadata,
      if (scanGoal != null) 'scanGoal': scanGoal,
      if (confidenceTarget != null) 'confidenceTarget': confidenceTarget,
      if (scannerUxVersion != null) 'scannerUxVersion': scannerUxVersion,
      if (qualityMetadata.isNotEmpty) 'qualityMetadata': qualityMetadata,
      'timestamp': timestamp.toIso8601String(),
      if (images.isNotEmpty)
        'images': [for (final image in images) image.toJson()],
    };
  }
}

class AiBackendAnalysisImage {
  const AiBackendAnalysisImage({
    required this.imagePath,
    required this.imageSource,
    required this.imageRole,
  });

  final String imagePath;
  final String imageSource;
  final String imageRole;

  Map<String, dynamic> toJson() {
    return {
      'imagePath': imagePath,
      'imageSource': imageSource,
      'imageRole': imageRole,
    };
  }
}

class AiBackendAnalysisResponse {
  const AiBackendAnalysisResponse({
    required this.id,
    required this.itemName,
    required this.category,
    required this.estimatedValue,
    required this.lowEstimate,
    required this.highEstimate,
    required this.confidence,
    required this.condition,
    required this.marketTrend,
    required this.keyAttributes,
    required this.aiReview,
    required this.alternatives,
    required this.recommendation,
    required this.marketSummary,
    required this.comparableSales,
    required this.imageUrl,
    required this.timestamp,
    this.faceValue,
    this.estimatedMarketValue,
    this.askingPriceWarning,
    this.valuationConfidence,
    this.rawProviderPayload = const {},
  });

  final String? id;
  final String itemName;
  final String category;
  final double estimatedValue;
  final double lowEstimate;
  final double highEstimate;
  final double confidence;
  final String condition;
  final String marketTrend;
  final Map<String, String> keyAttributes;
  final AiBackendReview aiReview;
  final List<AiBackendAlternativeMatch> alternatives;
  final String recommendation;
  final MarketSummary? marketSummary;
  final List<MarketComp> comparableSales;
  final String? imageUrl;
  final DateTime? timestamp;
  final double? faceValue;
  final double? estimatedMarketValue;
  final String? askingPriceWarning;
  final double? valuationConfidence;
  final Map<String, dynamic> rawProviderPayload;

  factory AiBackendAnalysisResponse.fromJson(Map<String, dynamic> json) {
    final valueRange = parseJsonMap(json['valueRange']);
    final marketSummaryJson = parseJsonMap(json['marketSummary']);
    final comparableSales = _parseComparableSales(
      json['comparableSales'] ?? json['comps'] ?? marketSummaryJson['comps'],
    );

    final estimatedValue =
        parseNullableDouble(
          json['estimatedValue'] ??
              json['estimatedMarketValue'] ??
              json['marketValue'],
        ) ??
        parseNullableDouble(valueRange['estimated']) ??
        parseNullableDouble(valueRange['mid']) ??
        0;
    final lowEstimate =
        parseNullableDouble(json['lowEstimate'] ?? valueRange['low']) ??
        estimatedValue;
    final highEstimate =
        parseNullableDouble(json['highEstimate'] ?? valueRange['high']) ??
        estimatedValue;

    return AiBackendAnalysisResponse(
      id: _optionalString(json['id']),
      itemName: parseString(
        json['itemName'] ?? json['title'] ?? json['name'],
        fallback: 'Unknown collectible',
      ),
      category: parseString(
        json['category'] ?? json['type'],
        fallback: 'Collectible',
      ),
      estimatedValue: estimatedValue,
      lowEstimate: lowEstimate,
      highEstimate: highEstimate,
      confidence: _normalizeConfidence(json['confidence']),
      condition: parseString(json['condition'], fallback: 'Unknown'),
      marketTrend: parseString(
        json['marketTrend'] ?? json['trendLabel'],
        fallback: 'Stable',
      ),
      keyAttributes: _parseStringMap(
        json['keyAttributes'] ?? json['attributes'],
      ),
      aiReview: AiBackendReview.fromJson(
        parseJsonMap(json['aiReview'] ?? json['review']),
        fallbackPrimaryMatch: parseString(
          json['primaryMatch'] ?? json['itemName'] ?? json['title'],
          fallback: 'Unknown collectible',
        ),
        fallbackReasoning: parseString(
          json['aiReasoning'] ?? json['description'],
        ),
      ),
      alternatives:
          _parseList(json['alternatives'] ?? json['alternativeMatches'])
              .whereType<Map>()
              .map((match) => AiBackendAlternativeMatch.fromJson(match))
              .toList(growable: false),
      recommendation: parseString(
        json['recommendation'],
        fallback: 'Review the result before saving.',
      ),
      marketSummary: marketSummaryJson.isEmpty
          ? null
          : MarketSummary.fromJson({
              ...marketSummaryJson,
              if (!marketSummaryJson.containsKey('comps'))
                'comps': [for (final sale in comparableSales) sale.toJson()],
            }),
      comparableSales: comparableSales,
      imageUrl: _optionalString(json['imageUrl'] ?? json['image_url']),
      timestamp: parseNullableDateTime(json['timestamp']),
      faceValue: parseNullableDouble(json['faceValue']),
      estimatedMarketValue: parseNullableDouble(json['estimatedMarketValue']),
      askingPriceWarning: _optionalString(json['askingPriceWarning']),
      valuationConfidence: _normalizeNullableConfidence(
        json['valuationConfidence'],
      ),
      rawProviderPayload: {
        ...parseJsonMap(json['rawProviderPayload']),
        if (_optionalString(json['selectedProvider']) != null)
          'selectedProvider': _optionalString(json['selectedProvider']),
        if (_optionalString(json['requestedProvider']) != null)
          'requestedProvider': _optionalString(json['requestedProvider']),
        if (_optionalString(json['provider']) != null)
          'provider': _optionalString(json['provider']),
        if (_optionalString(json['model']) != null)
          'model': _optionalString(json['model']),
      },
    );
  }

  ScanResult toScanResult({required String thumbnail, DateTime? scanDate}) {
    final resultDate = scanDate ?? timestamp ?? DateTime.now();
    final resolvedMarketSummary = marketSummary ?? _fallbackMarketSummary();
    final pricingSource =
        resolvedMarketSummary == null || resolvedMarketSummary.sources.isEmpty
        ? 'Backend AI'
        : resolvedMarketSummary.sources.first;
    final pricing = PricingInfo(
      estimatedMarketValue: estimatedValue,
      lowEstimate: lowEstimate,
      highEstimate: highEstimate,
      currency: 'AUD',
      pricingSource: pricingSource,
      pricingConfidence: confidence,
      lastUpdated: resolvedMarketSummary?.lastUpdated,
    );

    return ScanResult(
      id: id ?? 'backend-${resultDate.microsecondsSinceEpoch}',
      title: itemName,
      category: category,
      estimatedValue: estimatedValue,
      confidence: confidence,
      condition: condition,
      thumbnail: imageUrl ?? thumbnail,
      scanDate: resultDate,
      primaryMatch: aiReview.primaryMatch,
      alternativeMatches: [
        for (final match in alternatives)
          ScanAlternativeMatch(
            title: match.title,
            category: match.category,
            confidence: match.confidence,
            reason: match.reason,
          ),
      ],
      confidenceExplanation: aiReview.confidenceExplanation,
      detectionQuality: aiReview.detectionQuality,
      aiReasoning: aiReview.reasoning,
      pricing: pricing,
      marketSummary: resolvedMarketSummary,
      year: _attribute('year'),
      brand: _attribute('brand'),
      setName: _attribute('setName'),
      series: _attribute('series'),
      cardNumber: _attribute('cardNumber'),
      playerOrCharacter: _attribute('playerOrCharacter'),
      rarity: _attribute('rarity'),
      estimatedGrade: _attribute('estimatedGrade'),
      language: _attribute('language'),
      edition: _attribute('edition'),
      country: _attribute('country'),
      mint: _attribute('mint'),
      material: _attribute('material'),
      notes: _attribute('notes'),
      faceValue: faceValue,
      estimatedMarketValue: estimatedMarketValue,
      askingPriceWarning: askingPriceWarning,
      valuationConfidence: valuationConfidence,
      photosUsed: _photosUsed(),
      photoRoles: _photoRoles(),
    );
  }

  MarketSummary? _fallbackMarketSummary() {
    if (comparableSales.isEmpty && estimatedValue == 0) {
      return null;
    }

    return MarketSummary(
      averagePrice: estimatedValue,
      medianPrice: estimatedValue,
      lowPrice: lowEstimate,
      highPrice: highEstimate,
      salesCount: comparableSales.length,
      trendLabel: marketTrend,
      confidence: confidence,
      lastUpdated: timestamp ?? DateTime.now(),
      sources: const ['Backend AI'],
      comps: comparableSales,
    );
  }

  String? _attribute(String key) {
    final value = keyAttributes[key];
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }

    return null;
  }

  int? _photosUsed() {
    final value = rawProviderPayload['photosUsed'];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  List<String> _photoRoles() {
    final roles = rawProviderPayload['photoRoles'];
    if (roles is! List) {
      return const [];
    }
    return [
      for (final role in roles)
        if (role is String && role.trim().isNotEmpty) role.trim(),
    ];
  }
}

class AiBackendReview {
  const AiBackendReview({
    required this.primaryMatch,
    required this.confidenceExplanation,
    required this.detectionQuality,
    required this.reasoning,
  });

  final String primaryMatch;
  final String confidenceExplanation;
  final String detectionQuality;
  final String reasoning;

  factory AiBackendReview.fromJson(
    Map<String, dynamic> json, {
    required String fallbackPrimaryMatch,
    required String fallbackReasoning,
  }) {
    return AiBackendReview(
      primaryMatch: parseString(
        json['primaryMatch'] ?? json['primaryResult'],
        fallback: fallbackPrimaryMatch,
      ),
      confidenceExplanation: parseString(
        json['confidenceExplanation'] ?? json['whyThisMatch'],
        fallback: 'Confidence is based on visible collectible details.',
      ),
      detectionQuality: parseString(
        json['detectionQuality'],
        fallback: 'Image quality was sufficient for analysis.',
      ),
      reasoning: parseString(json['reasoning'], fallback: fallbackReasoning),
    );
  }
}

class AiBackendAlternativeMatch {
  const AiBackendAlternativeMatch({
    required this.title,
    required this.category,
    required this.confidence,
    required this.reason,
  });

  final String title;
  final String category;
  final double confidence;
  final String reason;

  factory AiBackendAlternativeMatch.fromJson(Map<dynamic, dynamic> json) {
    return AiBackendAlternativeMatch(
      title: parseString(json['title'], fallback: 'Unknown alternative'),
      category: parseString(json['category'], fallback: 'Collectible'),
      confidence: _normalizeConfidence(json['confidence']),
      reason: parseString(json['reason']),
    );
  }
}

class AiBackendAnalysisError {
  const AiBackendAnalysisError({
    required this.code,
    required this.message,
    required this.retryable,
    required this.details,
  });

  final String code;
  final String message;
  final bool retryable;
  final Map<String, dynamic> details;

  factory AiBackendAnalysisError.fromJson(Map<String, dynamic> json) {
    return AiBackendAnalysisError(
      code: parseString(json['code'], fallback: 'backend_ai_error'),
      message: parseString(
        json['message'],
        fallback: 'Unable to analyze image.',
      ),
      retryable: json['retryable'] == true,
      details: parseJsonMap(json['details']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'retryable': retryable,
      'details': details,
    };
  }
}

Map<String, String> _parseStringMap(Object? value) {
  return {
    for (final entry in parseJsonMap(value).entries)
      if (parseString(entry.value).trim().isNotEmpty)
        entry.key: parseString(entry.value).trim(),
  };
}

List<MarketComp> _parseComparableSales(Object? value) {
  return _parseList(value)
      .whereType<Map>()
      .map((sale) => MarketComp.fromJson(parseJsonMap(sale)))
      .toList(growable: false);
}

List<dynamic> _parseList(Object? value) {
  return value is List<dynamic> ? value : const [];
}

double _normalizeConfidence(Object? value) {
  final confidence = parseNullableDouble(value) ?? 0;
  return confidence > 1 ? confidence / 100 : confidence;
}

double? _normalizeNullableConfidence(Object? value) {
  final confidence = parseNullableDouble(value);
  if (confidence == null) {
    return null;
  }
  return confidence > 1 ? confidence / 100 : confidence;
}

String? _optionalString(Object? value) {
  final parsed = parseString(value).trim();
  return parsed.isEmpty ? null : parsed;
}
