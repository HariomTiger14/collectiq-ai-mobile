import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_pricing_request.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_summary.dart';
import 'package:collectiq_ai/features/market/domain/repositories/market_pricing_provider.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';

/// Metadata used while enriching a scan result.
class ScanResultEnrichmentMetadata {
  /// Creates immutable enrichment metadata.
  const ScanResultEnrichmentMetadata({
    required this.imagePath,
    required this.imageSource,
  });

  /// Selected image path or reference.
  final String imagePath;

  /// Selected image source such as camera, gallery, sample, or unknown.
  final String imageSource;
}

/// Combines AI analysis output with market-pricing data before presentation.
class ScanResultEnrichmentService {
  /// Creates a scan-result enrichment service.
  const ScanResultEnrichmentService({
    required this.marketPricingProvider,
    this.telemetryService = const NoopTelemetryService(),
  });

  /// Future market-pricing provider dependency.
  final MarketPricingProvider marketPricingProvider;

  final AppTelemetryService telemetryService;

  /// Returns an enriched scan result while preserving user-safe fallbacks.
  Future<AiAnalysisResult> enrich({
    required AiAnalysisResult analysis,
    required ScanResultEnrichmentMetadata metadata,
  }) async {
    final result = analysis.scanResult;
    if (result.valuationStatus != ValuationStatus.unavailable) {
      return analysis;
    }
    try {
      final pricing = await marketPricingProvider.price(
        MarketPricingRequest(
          title: result.title,
          category: result.category,
          condition: result.condition,
          year: result.year,
          brand: result.brand,
          setName: result.setName,
          cardNumber: result.cardNumber,
          playerOrCharacter: result.playerOrCharacter,
          currency: result.pricing.currency,
          asOfDate: result.scanDate,
          imageSource: metadata.imageSource,
          localImagePath: metadata.imagePath,
        ),
      );

      return AiAnalysisResult(
        recommendation: analysis.recommendation,
        scanResult: _copyResult(
          result,
          estimatedValue: pricing.estimatedValue,
          pricing: _mergePricing(
            existing: result.pricing,
            enriched: pricing.toPricingInfo(),
          ),
          marketSummary: pricing.toMarketSummary(),
        ),
      );
    } on Object catch (error, stackTrace) {
      await telemetryService.recordNonFatalError(
        error,
        stackTrace: stackTrace,
        reason: 'pricing_provider_fallback',
        properties: {'category': result.category},
      );
      return AiAnalysisResult(
        recommendation: analysis.recommendation,
        scanResult: _copyResult(
          result,
          pricing: PricingInfo(
            estimatedMarketValue: result.estimatedValue,
            lowEstimate: result.estimatedValue,
            highEstimate: result.estimatedValue,
            currency: result.pricing.currency,
            pricingSource: 'Mock pricing unavailable',
            pricingConfidence: 0,
            lastUpdated: result.scanDate,
            valuationStatus: result.valuationStatus,
            valuationSource: result.valuationSource,
            aiEstimatedValue: result.aiEstimatedValue,
          ),
          marketSummary: result.marketSummary,
        ),
      );
    }
  }

  PricingInfo _mergePricing({
    required PricingInfo existing,
    required PricingInfo enriched,
  }) {
    return PricingInfo(
      estimatedMarketValue: enriched.estimatedMarketValue,
      lowEstimate: enriched.lowEstimate,
      highEstimate: enriched.highEstimate,
      currency: enriched.currency,
      pricingSource: enriched.pricingSource,
      pricingConfidence: enriched.pricingConfidence,
      lastUpdated: enriched.lastUpdated,
      valuationStatus: enriched.valuationStatus,
      valuationSource: enriched.valuationSource,
      aiEstimatedValue: existing.aiEstimatedValue,
    );
  }

  ScanResult _copyResult(
    ScanResult result, {
    double? estimatedValue,
    PricingInfo? pricing,
    MarketSummary? marketSummary,
  }) {
    return ScanResult(
      id: result.id,
      title: result.title,
      category: result.category,
      estimatedValue: estimatedValue ?? result.estimatedValue,
      confidence: result.confidence,
      condition: result.condition,
      thumbnail: result.thumbnail,
      scanDate: result.scanDate,
      primaryMatch: result.primaryMatch,
      alternativeMatches: result.alternativeMatches,
      confidenceExplanation: result.confidenceExplanation,
      detectionQuality: result.detectionQuality,
      aiReasoning: result.aiReasoning,
      pricing: pricing ?? result.pricing,
      marketSummary: marketSummary ?? result.marketSummary,
      year: result.year,
      brand: result.brand,
      setName: result.setName,
      series: result.series,
      cardNumber: result.cardNumber,
      playerOrCharacter: result.playerOrCharacter,
      rarity: result.rarity,
      estimatedGrade: result.estimatedGrade,
      language: result.language,
      edition: result.edition,
      country: result.country,
      mint: result.mint,
      material: result.material,
      notes: result.notes,
      faceValue: result.faceValue,
      estimatedMarketValue: result.estimatedMarketValue,
      askingPriceWarning: result.askingPriceWarning,
      valuationConfidence: result.valuationConfidence,
      valuationStatus: result.valuationStatus,
      valuationSource: result.valuationSource,
      aiEstimatedValue: result.aiEstimatedValue,
      photosUsed: result.photosUsed,
      photoRoles: result.photoRoles,
      galleryImages: result.galleryImages,
    );
  }
}
