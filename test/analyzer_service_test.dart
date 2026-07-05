import 'dart:async';

import 'package:collectiq_ai/core/network/network_exceptions.dart';
import 'package:collectiq_ai/features/ai/data/analyzer/analyzer_provider_factory.dart';
import 'package:collectiq_ai/features/ai/data/analyzer/future_gemini_provider.dart';
import 'package:collectiq_ai/features/ai/data/analyzer/future_openai_provider.dart';
import 'package:collectiq_ai/features/ai/data/analyzer/future_vision_provider.dart';
import 'package:collectiq_ai/features/ai/data/analyzer/mock_analyzer_provider.dart';
import 'package:collectiq_ai/features/ai/data/models/ai_backend_analysis_models.dart';
import 'package:collectiq_ai/features/ai/domain/clients/ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_models.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_provider.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_service.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyzerProviderType', () {
    test('parses provider config and keeps mock as safe default', () {
      expect(
        AnalyzerProviderType.fromConfig('mock'),
        AnalyzerProviderType.mock,
      );
      expect(
        AnalyzerProviderType.fromConfig('future_vision'),
        AnalyzerProviderType.futureVision,
      );
      expect(
        AnalyzerProviderType.fromConfig('openai_vision'),
        AnalyzerProviderType.futureOpenAI,
      );
      expect(
        AnalyzerProviderType.fromConfig('gemini'),
        AnalyzerProviderType.futureGemini,
      );
      expect(
        AnalyzerProviderType.fromConfig('anything-else'),
        AnalyzerProviderType.mock,
      );
    });
  });

  group('AnalyzerProviderFactory', () {
    test('creates replaceable providers from config', () {
      const factory = AnalyzerProviderFactory();
      const legacyProvider = _SuccessfulLegacyProvider();

      expect(
        factory.create(
          config: const AnalyzerConfig(),
          legacyAnalysisProvider: legacyProvider,
          backendClient: const _FakeBackendClient(),
        ),
        isA<MockAnalyzerProvider>(),
      );
      expect(
        factory.create(
          config: const AnalyzerConfig(
            providerType: AnalyzerProviderType.futureVision,
          ),
          legacyAnalysisProvider: legacyProvider,
          backendClient: const _FakeBackendClient(),
        ),
        isA<FutureVisionProvider>(),
      );
      expect(
        factory.create(
          config: const AnalyzerConfig(
            providerType: AnalyzerProviderType.futureOpenAI,
          ),
          legacyAnalysisProvider: legacyProvider,
          backendClient: const _FakeBackendClient(),
        ),
        isA<FutureOpenAIProvider>(),
      );
      expect(
        factory.create(
          config: const AnalyzerConfig(
            providerType: AnalyzerProviderType.futureGemini,
          ),
          legacyAnalysisProvider: legacyProvider,
          backendClient: const _FakeBackendClient(),
        ),
        isA<FutureGeminiProvider>(),
      );
    });
  });

  group('AnalyzerService', () {
    test('returns provider response and emits progress', () async {
      final progress = <AnalysisStatus>[];
      final service = AnalyzerService(
        provider: _SuccessfulAnalyzerProvider(),
        config: const AnalyzerConfig(
          retryPolicy: AnalyzerRetryPolicy(maxAttempts: 1),
        ),
      );

      final response = await service.analyze(
        const AnalyzerRequest(imagePath: '/tmp/card.jpg'),
        onProgress: (event) => progress.add(event.status),
      );

      expect(response.title, 'Analyzer Test Card');
      expect(response.manufacturer, 'PackLox');
      expect(response.year, '2026');
      expect(response.currency, 'AUD');
      expect(response.attributes['rarity'], 'Rare');
      expect(response.images, ['/tmp/card.jpg']);
      expect(response.rawProviderPayload['provider'], 'fake');
      expect(
        progress,
        containsAll(<AnalysisStatus>[
          AnalysisStatus.queued,
          AnalysisStatus.uploading,
          AnalysisStatus.analyzing,
          AnalysisStatus.completed,
        ]),
      );
    });

    test('retries retryable errors', () async {
      final provider = _FlakyAnalyzerProvider(
        firstError: const AnalyzerException(
          type: AnalyzerErrorType.network,
          message: 'Network connection failed.',
        ),
      );
      final service = AnalyzerService(
        provider: provider,
        config: const AnalyzerConfig(
          retryPolicy: AnalyzerRetryPolicy(
            maxAttempts: 2,
            retryDelay: Duration.zero,
          ),
        ),
      );

      final response = await service.analyze(
        const AnalyzerRequest(imagePath: '/tmp/card.jpg'),
      );

      expect(response.title, 'Analyzer Test Card');
      expect(provider.calls, 2);
    });

    test('does not retry invalid images', () async {
      final provider = _FlakyAnalyzerProvider(
        firstError: const AnalyzerException(
          type: AnalyzerErrorType.invalidImage,
          message: 'Invalid image.',
        ),
      );
      final service = AnalyzerService(
        provider: provider,
        config: const AnalyzerConfig(
          retryPolicy: AnalyzerRetryPolicy(
            maxAttempts: 3,
            retryDelay: Duration.zero,
          ),
        ),
      );

      await expectLater(
        service.analyze(const AnalyzerRequest(imagePath: '/tmp/card.txt')),
        throwsA(
          isA<AnalyzerException>().having(
            (error) => error.type,
            'type',
            AnalyzerErrorType.invalidImage,
          ),
        ),
      );
      expect(provider.calls, 1);
    });

    test('maps timeout to timeout error', () async {
      final service = AnalyzerService(
        provider: _NeverCompletesAnalyzerProvider(),
        config: const AnalyzerConfig(
          timeout: Duration(milliseconds: 20),
          retryPolicy: AnalyzerRetryPolicy(
            maxAttempts: 1,
            retryDelay: Duration.zero,
          ),
        ),
      );

      await expectLater(
        service.analyze(const AnalyzerRequest(imagePath: '/tmp/card.jpg')),
        throwsA(
          isA<AnalyzerException>().having(
            (error) => error.type,
            'type',
            AnalyzerErrorType.timeout,
          ),
        ),
      );
    });

    test('supports cooperative cancellation', () async {
      final token = AnalyzerCancellationToken()..cancel();
      final service = AnalyzerService(
        provider: _SuccessfulAnalyzerProvider(),
        config: const AnalyzerConfig(),
      );

      await expectLater(
        service.analyze(
          AnalyzerRequest(imagePath: '/tmp/card.jpg', cancellationToken: token),
        ),
        throwsA(
          isA<AnalyzerException>().having(
            (error) => error.type,
            'type',
            AnalyzerErrorType.cancelled,
          ),
        ),
      );
    });
  });

  group('MockAnalyzerProvider', () {
    test('consumes the backend analyzer contract when configured', () async {
      final provider = MockAnalyzerProvider(
        analysisProvider: const _SuccessfulLegacyProvider(),
        backendClient: const _FakeBackendClient(),
        useBackendContract: true,
      );

      final response = await provider.analyze(
        const AnalyzerRequest(
          imagePath: '/tmp/card.jpg',
          metadata: {'imageSource': 'gallery'},
        ),
      );

      expect(response.title, 'Backend Contract Card');
      expect(response.rawProviderPayload['contract'], 'POST /analyze');
    });
  });

  group('AnalyzerException', () {
    test('maps network status codes to analyzer errors', () {
      expect(
        AnalyzerException.fromObject(
          const NetworkException(message: 'Quota', statusCode: 429),
        ).type,
        AnalyzerErrorType.quotaExceeded,
      );
      expect(
        AnalyzerException.fromObject(
          const NetworkException(message: 'Auth', statusCode: 401),
        ).type,
        AnalyzerErrorType.authentication,
      );
      expect(
        AnalyzerException.fromObject(
          const NetworkException(message: 'Bad image', statusCode: 422),
        ).type,
        AnalyzerErrorType.invalidImage,
      );
      expect(
        AnalyzerException.fromObject(
          const NetworkException(message: 'Unavailable', statusCode: 503),
        ).type,
        AnalyzerErrorType.providerUnavailable,
      );
    });
  });
}

class _SuccessfulAnalyzerProvider implements AnalyzerProvider {
  @override
  String get id => 'fake';

  @override
  Future<AnalyzerResponse> analyze(
    AnalyzerRequest request, {
    AnalyzerProgressCallback? onProgress,
  }) async {
    onProgress?.call(
      const AnalyzerProgressEvent(
        status: AnalysisStatus.uploading,
        bytesSent: 50,
        totalBytes: 100,
      ),
    );
    onProgress?.call(
      const AnalyzerProgressEvent(status: AnalysisStatus.analyzing),
    );
    return AnalyzerResponse.fromAiAnalysisResult(
      _legacyResult(request.imagePath),
      rawProviderPayload: {'provider': id},
    );
  }
}

class _FlakyAnalyzerProvider extends _SuccessfulAnalyzerProvider {
  _FlakyAnalyzerProvider({required this.firstError});

  final AnalyzerException firstError;
  int calls = 0;

  @override
  Future<AnalyzerResponse> analyze(
    AnalyzerRequest request, {
    AnalyzerProgressCallback? onProgress,
  }) {
    calls += 1;
    if (calls == 1) {
      throw firstError;
    }

    return super.analyze(request, onProgress: onProgress);
  }
}

class _NeverCompletesAnalyzerProvider implements AnalyzerProvider {
  @override
  String get id => 'never';

  @override
  Future<AnalyzerResponse> analyze(
    AnalyzerRequest request, {
    AnalyzerProgressCallback? onProgress,
  }) {
    return Completer<AnalyzerResponse>().future;
  }
}

class _SuccessfulLegacyProvider implements AiAnalysisProvider {
  const _SuccessfulLegacyProvider();

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisRequest request) async {
    return _legacyResult(request.imagePath);
  }
}

class _FakeBackendClient implements AiBackendClient {
  const _FakeBackendClient();

  @override
  Future<AiBackendAnalysisResponse> analyze(
    AiBackendAnalysisRequest request,
  ) async {
    return AiBackendAnalysisResponse.fromJson({
      'id': 'backend-test',
      'title': 'Backend Contract Card',
      'category': 'Trading Card',
      'estimatedValue': 42,
      'lowEstimate': 35,
      'highEstimate': 55,
      'confidence': 91,
      'condition': 'Near Mint',
      'marketTrend': 'Stable',
      'attributes': {'brand': 'PackLox', 'year': '2026'},
      'aiReview': {
        'primaryMatch': 'Backend Contract Card',
        'confidenceExplanation': 'Mapped from contract JSON.',
        'detectionQuality': 'Good',
        'reasoning': 'Contract mapping test.',
      },
      'alternatives': const [],
      'recommendation': 'Review before saving.',
      'timestamp': '2026-07-05T10:00:00Z',
    });
  }
}

AiAnalysisResult _legacyResult(String imagePath) {
  final now = DateTime.parse('2026-07-05T10:00:00Z');
  return AiAnalysisResult(
    recommendation: 'Keep it protected.',
    scanResult: ScanResult(
      id: 'scan-test',
      title: 'Analyzer Test Card',
      category: 'Trading Card',
      estimatedValue: 99,
      confidence: 0.91,
      condition: 'Near Mint',
      thumbnail: imagePath,
      scanDate: now,
      primaryMatch: 'Analyzer Test Card',
      alternativeMatches: const [],
      confidenceExplanation: 'Visible title and artwork.',
      detectionQuality: 'Good',
      aiReasoning: 'Provider-neutral response.',
      pricing: PricingInfo(
        estimatedMarketValue: 99,
        lowEstimate: 80,
        highEstimate: 120,
        currency: 'AUD',
        pricingSource: 'Fixture',
        pricingConfidence: 0.9,
        lastUpdated: now,
      ),
      year: '2026',
      brand: 'PackLox',
      series: 'Analyzer',
      rarity: 'Rare',
    ),
  );
}
