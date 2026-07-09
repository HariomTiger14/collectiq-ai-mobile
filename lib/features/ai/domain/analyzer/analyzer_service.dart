import 'dart:async';

import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_models.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_provider.dart';

/// Single app-facing analyzer boundary.
class AnalyzerService {
  const AnalyzerService({required this.provider, required this.config});

  final AnalyzerProvider provider;
  final AnalyzerConfig config;

  /// Runs analysis with timeout, retry, progress, and cancellation handling.
  Future<AnalyzerResponse> analyze(
    AnalyzerRequest request, {
    AnalyzerProgressCallback? onProgress,
  }) async {
    final normalizedRequest = _withAnalyzerMediaMetadata(request);
    final cancellationToken = request.cancellationToken;
    var attempt = 0;
    AnalyzerException? lastError;

    while (attempt < config.retryPolicy.maxAttempts) {
      attempt += 1;
      cancellationToken?.throwIfCancelled();
      onProgress?.call(
        AnalyzerProgressEvent(
          status: AnalysisStatus.queued,
          message: 'Starting analysis attempt $attempt.',
        ),
      );

      try {
        final response = await provider
            .analyze(normalizedRequest, onProgress: onProgress)
            .timeout(
              config.timeout,
              onTimeout: () => throw const AnalyzerException(
                type: AnalyzerErrorType.timeout,
                message: 'AI analysis timed out. Please try again.',
              ),
            );
        cancellationToken?.throwIfCancelled();
        onProgress?.call(
          const AnalyzerProgressEvent(status: AnalysisStatus.completed),
        );
        return response;
      } on Object catch (error) {
        final mapped = AnalyzerException.fromObject(error);
        lastError = mapped;
        onProgress?.call(
          AnalyzerProgressEvent(
            status: AnalysisStatus.failed,
            message: mapped.message,
          ),
        );

        final canRetry =
            attempt < config.retryPolicy.maxAttempts &&
            config.retryPolicy.shouldRetry(mapped.type);
        if (!canRetry) {
          throw mapped;
        }

        await Future<void>.delayed(config.retryPolicy.retryDelay);
      }
    }

    throw lastError ??
        const AnalyzerException(
          type: AnalyzerErrorType.unknown,
          message: 'AI analysis is not available right now. Please try again.',
        );
  }

  AnalyzerRequest _withAnalyzerMediaMetadata(AnalyzerRequest request) {
    final selectedEnhancement =
        request.metadata['activeSelectedEnhancement']?.toString() ??
        request.metadata['selectedEnhancement']?.toString() ??
        'original';
    final enhancedPath = request.metadata['activeEnhancedImagePath']
        ?.toString();
    final originalPath = request.metadata['originalImagePath']?.toString();
    final primaryImage = selectedEnhancement == 'aiEnhance'
        ? _usablePath(enhancedPath, request.imagePath)
        : _usablePath(originalPath, request.imagePath);
    final photos = [
      for (final image in request.images)
        {
          'path': image.path,
          'role': image.role,
          'source': image.source,
          'hasFile': image.image != null,
        },
    ];

    return AnalyzerRequest(
      imagePath: primaryImage,
      image: request.image,
      images: request.images,
      metadata: {
        ...request.metadata,
        'photos': photos,
        'primaryImage': primaryImage,
        'category': request.metadata['captureCategory'],
        'confidence': request.metadata['activeReadinessScore'],
        'enhancement': selectedEnhancement,
      },
      cancellationToken: request.cancellationToken,
    );
  }

  String _usablePath(String? candidate, String fallback) {
    final trimmed = candidate?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == 'null') {
      return fallback;
    }
    return trimmed;
  }
}
