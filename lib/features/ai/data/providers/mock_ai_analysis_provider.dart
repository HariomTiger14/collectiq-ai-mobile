import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:collectiq_ai/features/ai/data/providers/mock_collectible_result_pool.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_summary.dart';
import 'package:collectiq_ai/features/market/domain/repositories/market_provider.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:flutter/foundation.dart';

/// Mock/local AI provider used until paid AI providers are enabled.
class MockAiAnalysisProvider implements AiAnalysisProvider {
  /// Creates a mock analysis provider.
  const MockAiAnalysisProvider({
    required this.recognitionRepository,
    required this.marketProvider,
    this.resultPool = const MockCollectibleResultPool(),
  });

  final RecognitionRepository recognitionRepository;
  final MarketProvider marketProvider;
  final MockCollectibleResultPool resultPool;

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisRequest request) async {
    final recognition = await resultPool.resultFor(request);
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
