import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_summary.dart';
import 'package:collectiq_ai/features/market/domain/repositories/market_provider.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Mock/local AI provider used until paid AI providers are enabled.
class MockAiAnalysisProvider implements AiAnalysisProvider {
  /// Creates a mock analysis provider.
  const MockAiAnalysisProvider({
    required this.recognitionRepository,
    required this.marketProvider,
  });

  final RecognitionRepository recognitionRepository;
  final MarketProvider marketProvider;

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisRequest request) async {
    final recognition = request.imagePath.startsWith('sample://')
        ? _sampleRecognitionResult()
        : await _recognizeSelectedImage(request);
    debugPrint(
      '[Scanner] recognition result created '
      'title="${recognition.title}" '
      'category=${recognition.category} '
      'confidence=${recognition.confidence} '
      'estimatedValue=${recognition.estimatedValue}',
    );

    final marketSummary =
        recognition.marketSummary ??
        await marketProvider.summarizeMarket(recognition);
    final thumbnail = _portfolioImagePathFor(
      selectedImagePath: request.imagePath,
      recognitionImageUrl: recognition.imageUrl,
    );
    debugPrint('[Scanner] ScanResult.thumbnail: $thumbnail');

    return AiAnalysisResult(
      scanResult: _scanResultFromRecognition(
        recognition: recognition,
        thumbnail: thumbnail,
        scanDate: DateTime.now(),
        marketSummary: marketSummary,
      ),
      recommendation: recognition.recommendation,
    );
  }

  Future<RecognitionResult> _recognizeSelectedImage(AiAnalysisRequest request) {
    final image = request.image ?? XFile(request.imagePath);
    if (image.path.trim().isEmpty) {
      throw const AiAnalysisException(
        'Selected image path is missing. Please choose another image.',
      );
    }

    return recognitionRepository.recognizeCollectible(image);
  }

  ScanResult _scanResultFromRecognition({
    required RecognitionResult recognition,
    required String thumbnail,
    required DateTime scanDate,
    required MarketSummary? marketSummary,
  }) {
    return ScanResult(
      id: 'scan-${scanDate.microsecondsSinceEpoch}',
      title: recognition.title,
      category: recognition.category,
      estimatedValue: recognition.estimatedValue,
      confidence: recognition.confidence,
      condition: recognition.condition,
      thumbnail: thumbnail,
      scanDate: scanDate,
      primaryMatch: recognition.primaryMatch,
      alternativeMatches: [
        for (final match in recognition.alternativeMatches)
          ScanAlternativeMatch(
            title: match.title,
            category: match.category,
            confidence: match.confidence,
            reason: match.reason,
          ),
      ],
      confidenceExplanation: recognition.confidenceExplanation,
      detectionQuality: recognition.detectionQuality,
      aiReasoning: recognition.aiReasoning,
      pricing: recognition.pricing,
      marketSummary: recognition.marketSummary ?? marketSummary,
      year: recognition.year,
      brand: recognition.brand,
      setName: recognition.setName,
      series: recognition.series,
      cardNumber: recognition.cardNumber,
      playerOrCharacter: recognition.playerOrCharacter,
      rarity: recognition.rarity,
      estimatedGrade: recognition.estimatedGrade,
      language: recognition.language,
      edition: recognition.edition,
      country: recognition.country,
      mint: recognition.mint,
      material: recognition.material,
      notes: recognition.notes,
    );
  }

  RecognitionResult _sampleRecognitionResult() {
    final result = RecognitionResult(
      success: true,
      filename: null,
      imageUrl: 'sample://sports-card',
      title: '1999 Pok\u00e9mon Charizard',
      category: 'Trading Card',
      confidence: 0.94,
      description: 'Sample scanner result.',
      estimatedValue: 1850,
      condition: 'Near Mint',
      recommendation: 'Consider grading before selling.',
      primaryMatch: '1999 Pokemon Charizard Holo',
      alternativeMatches: const [
        RecognitionAlternativeMatch(
          title: '2016 Pokemon Evolutions Charizard',
          category: 'Trading Card',
          confidence: 0.68,
          reason: 'Similar artwork and card layout.',
        ),
        RecognitionAlternativeMatch(
          title: 'Pokemon Charizard Promo',
          category: 'Trading Card',
          confidence: 0.61,
          reason: 'Character match is plausible.',
        ),
        RecognitionAlternativeMatch(
          title: 'Pokemon Expedition Charizard',
          category: 'Trading Card',
          confidence: 0.58,
          reason: 'Shares fire-type character cues.',
        ),
      ],
      confidenceExplanation:
          'High confidence from the character artwork, card frame, and holographic cues.',
      detectionQuality: 'Good - sample image is clear enough for review.',
      aiReasoning:
          'The sample shows a Charizard-like Pokemon card with collector-relevant holo and border details.',
      pricing: PricingInfo(
        estimatedMarketValue: 1850,
        lowEstimate: 1443,
        highEstimate: 2257,
        currency: 'AUD',
        pricingSource: 'Mock market blend: TCGplayer + eBay comps',
        pricingConfidence: 0.85,
        lastUpdated: DateTime.parse('2026-06-29T00:00:00Z'),
      ),
      year: '1999',
      brand: 'Pokemon',
      setName: 'Base Set',
      series: 'Pokemon TCG',
      cardNumber: '4/102',
      playerOrCharacter: 'Charizard',
      rarity: 'Holo Rare',
      estimatedGrade: 'PSA 8-9',
      language: 'English',
      edition: 'Unlimited',
      country: 'United States',
      material: 'Cardstock',
      notes: 'Verify holo surface and card centering before grading.',
    );
    debugPrint(
      '[Scanner] mock result created '
      'title="${result.title}" '
      'category=${result.category} '
      'confidence=${result.confidence} '
      'estimatedValue=${result.estimatedValue}',
    );
    return result;
  }

  String _portfolioImagePathFor({
    required String selectedImagePath,
    required String? recognitionImageUrl,
  }) {
    if (_isUsableSelectedImagePath(selectedImagePath)) {
      return selectedImagePath;
    }

    final normalizedRecognitionImageUrl = recognitionImageUrl?.trim();
    if (normalizedRecognitionImageUrl != null &&
        normalizedRecognitionImageUrl.isNotEmpty) {
      return normalizedRecognitionImageUrl;
    }

    return selectedImagePath;
  }

  bool _isUsableSelectedImagePath(String imagePath) {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.isEmpty || normalizedPath == 'selected-image') {
      return false;
    }

    return !normalizedPath.startsWith('sample://');
  }
}
