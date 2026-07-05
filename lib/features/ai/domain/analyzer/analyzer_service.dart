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
            .analyze(request, onProgress: onProgress)
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
}
