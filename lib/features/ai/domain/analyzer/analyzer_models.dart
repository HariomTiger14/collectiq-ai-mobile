import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/core/network/network_exceptions.dart';
import 'package:collectiq_ai/features/ai/domain/clients/ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:image_picker/image_picker.dart';

/// High-level lifecycle states for an analyzer request.
enum AnalysisStatus {
  queued,
  uploading,
  analyzing,
  completed,
  failed,
  cancelled,
}

/// Provider choices supported by the analyzer abstraction.
enum AnalyzerProviderType {
  mock,
  futureVision,
  futureOpenAI,
  futureGemini;

  /// Parses provider config while preserving legacy values.
  static AnalyzerProviderType fromConfig(String value) {
    return switch (value.trim().toLowerCase()) {
      'future_vision' || 'vision' => AnalyzerProviderType.futureVision,
      'openai' ||
      'openai_vision' ||
      'future_openai' => AnalyzerProviderType.futureOpenAI,
      'gemini' ||
      'gemini_vision' ||
      'auto' ||
      'gemini_openai' ||
      'future_gemini' => AnalyzerProviderType.futureGemini,
      _ => AnalyzerProviderType.mock,
    };
  }

  String get configValue {
    return switch (this) {
      AnalyzerProviderType.mock => 'mock',
      AnalyzerProviderType.futureVision => 'future_vision',
      AnalyzerProviderType.futureOpenAI => 'future_openai',
      AnalyzerProviderType.futureGemini => 'future_gemini',
    };
  }

  String get displayName {
    return switch (this) {
      AnalyzerProviderType.mock => 'Mock Analyzer',
      AnalyzerProviderType.futureVision => 'Future Vision',
      AnalyzerProviderType.futureOpenAI => 'Future OpenAI',
      AnalyzerProviderType.futureGemini => 'Future Gemini',
    };
  }
}

/// User-safe analyzer error categories.
enum AnalyzerErrorType {
  timeout,
  network,
  invalidImage,
  providerUnavailable,
  quotaExceeded,
  authentication,
  unknown,
  cancelled,
}

/// Runtime analyzer configuration.
class AnalyzerConfig {
  const AnalyzerConfig({
    this.providerType = AnalyzerProviderType.mock,
    this.timeout = const Duration(seconds: 30),
    this.retryPolicy = const AnalyzerRetryPolicy(),
  });

  factory AnalyzerConfig.fromEnvironment() {
    const configuredProvider = String.fromEnvironment(
      'AI_ANALYSIS_PROVIDER',
      defaultValue: '',
    );
    const timeoutSeconds = int.fromEnvironment(
      'ANALYZER_TIMEOUT_SECONDS',
      defaultValue: 30,
    );
    const maxAttempts = int.fromEnvironment(
      'ANALYZER_MAX_ATTEMPTS',
      defaultValue: 2,
    );

    final providerType = configuredProvider.trim().isEmpty
        ? _defaultAnalyzerProviderFor(EnvironmentConfig.fromEnvironment().environment)
        : AnalyzerProviderType.fromConfig(configuredProvider);

    return AnalyzerConfig(
      providerType: providerType,
      timeout: Duration(seconds: timeoutSeconds < 1 ? 30 : timeoutSeconds),
      retryPolicy: AnalyzerRetryPolicy(
        maxAttempts: maxAttempts < 1 ? 1 : maxAttempts,
      ),
    );
  }

  final AnalyzerProviderType providerType;
  final Duration timeout;
  final AnalyzerRetryPolicy retryPolicy;
}

AnalyzerProviderType _defaultAnalyzerProviderFor(AppEnvironment environment) {
  if (environment == AppEnvironment.local) {
    return AnalyzerProviderType.mock;
  }

  return AnalyzerProviderType.futureGemini;
}

/// Retry policy applied by AnalyzerService.
class AnalyzerRetryPolicy {
  const AnalyzerRetryPolicy({
    this.maxAttempts = 2,
    this.retryDelay = const Duration(milliseconds: 200),
  });

  final int maxAttempts;
  final Duration retryDelay;

  bool shouldRetry(AnalyzerErrorType type) {
    return switch (type) {
      AnalyzerErrorType.timeout ||
      AnalyzerErrorType.network ||
      AnalyzerErrorType.providerUnavailable ||
      AnalyzerErrorType.unknown => true,
      AnalyzerErrorType.invalidImage ||
      AnalyzerErrorType.quotaExceeded ||
      AnalyzerErrorType.authentication ||
      AnalyzerErrorType.cancelled => false,
    };
  }
}

/// Cooperative cancellation token for analyzer requests.
class AnalyzerCancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw const AnalyzerException(
        type: AnalyzerErrorType.cancelled,
        message: 'Analysis was cancelled.',
      );
    }
  }
}

/// Request sent from app workflow to the analyzer service.
class AnalyzerRequest {
  const AnalyzerRequest({
    required this.imagePath,
    this.image,
    this.images = const [],
    this.metadata = const {},
    this.cancellationToken,
  });

  final String imagePath;
  final XFile? image;
  final List<AnalyzerImageInput> images;
  final Map<String, Object?> metadata;
  final AnalyzerCancellationToken? cancellationToken;
}

class AnalyzerImageInput {
  const AnalyzerImageInput({
    required this.path,
    required this.role,
    this.image,
    this.source,
    this.slotType,
    this.systemTag,
    this.capturedAt,
  });

  final String path;
  final String role;
  final XFile? image;
  final String? source;
  final String? slotType;
  final String? systemTag;
  final DateTime? capturedAt;
}

/// Upload/progress event emitted during analysis.
class AnalyzerProgressEvent {
  const AnalyzerProgressEvent({
    required this.status,
    this.bytesSent,
    this.totalBytes,
    this.message,
  });

  final AnalysisStatus status;
  final int? bytesSent;
  final int? totalBytes;
  final String? message;

  double? get fraction {
    final sent = bytesSent;
    final total = totalBytes;
    if (sent == null || total == null || total <= 0) {
      return null;
    }

    return sent / total;
  }
}

typedef AnalyzerProgressCallback = void Function(AnalyzerProgressEvent event);

/// Provider-neutral analyzer response model.
class AnalyzerResponse {
  const AnalyzerResponse({
    required this.status,
    required this.scanResult,
    required this.recommendation,
    required this.title,
    required this.category,
    this.manufacturer,
    this.year,
    this.series,
    this.variant,
    this.condition,
    this.confidence,
    this.estimatedValue,
    this.currency,
    this.tags = const [],
    this.description,
    this.attributes = const {},
    this.images = const [],
    this.rawProviderPayload = const {},
  });

  factory AnalyzerResponse.fromAiAnalysisResult(
    AiAnalysisResult result, {
    Map<String, Object?> rawProviderPayload = const {},
  }) {
    final scanResult = result.scanResult;
    return AnalyzerResponse(
      status: AnalysisStatus.completed,
      scanResult: scanResult,
      recommendation: result.recommendation,
      title: scanResult.title,
      category: scanResult.category,
      manufacturer: scanResult.brand,
      year: scanResult.year,
      series: scanResult.series ?? scanResult.setName,
      condition: scanResult.condition,
      confidence: scanResult.confidence,
      estimatedValue: scanResult.estimatedValue,
      currency: scanResult.pricing.currency,
      description: scanResult.aiReasoning,
      attributes: {
        if (scanResult.brand != null) 'manufacturer': scanResult.brand,
        if (scanResult.year != null) 'year': scanResult.year,
        if (scanResult.setName != null) 'setName': scanResult.setName,
        if (scanResult.series != null) 'series': scanResult.series,
        if (scanResult.rarity != null) 'rarity': scanResult.rarity,
        if (scanResult.estimatedGrade != null)
          'estimatedGrade': scanResult.estimatedGrade,
        if (scanResult.material != null) 'material': scanResult.material,
      },
      images: [scanResult.thumbnail],
      rawProviderPayload: rawProviderPayload,
    );
  }

  final AnalysisStatus status;
  final ScanResult scanResult;
  final String recommendation;
  final String title;
  final String category;
  final String? manufacturer;
  final String? year;
  final String? series;
  final String? variant;
  final String? condition;
  final double? confidence;
  final double? estimatedValue;
  final String? currency;
  final List<String> tags;
  final String? description;
  final Map<String, Object?> attributes;
  final List<String> images;
  final Map<String, Object?> rawProviderPayload;

  AiAnalysisResult toAiAnalysisResult() {
    return AiAnalysisResult(
      scanResult: scanResult,
      recommendation: recommendation,
    );
  }
}

/// Analyzer exception with normalized error mapping.
class AnalyzerException implements Exception {
  const AnalyzerException({
    required this.type,
    required this.message,
    this.statusCode,
    this.details = const {},
  });

  factory AnalyzerException.fromObject(Object error) {
    if (error is AnalyzerException) {
      return error;
    }
    if (error is AiAnalysisException) {
      return AnalyzerException(
        type: _typeFromMessage(error.message),
        message: error.message,
      );
    }
    if (error is NetworkException) {
      final type = _typeFromNetworkException(error);
      return AnalyzerException(
        type: type,
        message: type == AnalyzerErrorType.network
            ? 'AI backend is not reachable. Check your internet/backend setup.'
            : error.message,
        statusCode: error.statusCode,
        details: {'code': error.code},
      );
    }
    if (error is AiBackendClientException) {
      return AnalyzerException(
        type: _typeFromBackendException(error),
        message: error.message,
        statusCode: error.statusCode,
        details: {...error.details, 'backendClientErrorType': error.type.name},
      );
    }

    return const AnalyzerException(
      type: AnalyzerErrorType.unknown,
      message: 'AI analysis is not available right now. Please try again.',
    );
  }

  final AnalyzerErrorType type;
  final String message;
  final int? statusCode;
  final Map<String, Object?> details;

  @override
  String toString() => 'AnalyzerException($type): $message';
}

AnalyzerErrorType _typeFromNetworkException(NetworkException error) {
  final statusCode = error.statusCode;
  if (statusCode == 401 || statusCode == 403) {
    return AnalyzerErrorType.authentication;
  }
  if (statusCode == 429) {
    return AnalyzerErrorType.quotaExceeded;
  }
  if (statusCode == 400 || statusCode == 415 || statusCode == 422) {
    return AnalyzerErrorType.invalidImage;
  }
  if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
    return AnalyzerErrorType.providerUnavailable;
  }

  final code = error.code?.toLowerCase() ?? '';
  final message = error.message.toLowerCase();
  if (code.contains('timeout') || message.contains('timed out')) {
    return AnalyzerErrorType.timeout;
  }
  if (code.contains('connection') || message.contains('network')) {
    return AnalyzerErrorType.network;
  }

  return AnalyzerErrorType.unknown;
}

AnalyzerErrorType _typeFromBackendException(AiBackendClientException error) {
  return switch (error.type) {
    AiBackendClientErrorType.timeout => AnalyzerErrorType.timeout,
    AiBackendClientErrorType.networkUnavailable => AnalyzerErrorType.network,
    AiBackendClientErrorType.invalidImagePayload =>
      AnalyzerErrorType.invalidImage,
    AiBackendClientErrorType.endpointMissing ||
    AiBackendClientErrorType.invalidEndpoint ||
    AiBackendClientErrorType.unsupportedProvider =>
      AnalyzerErrorType.providerUnavailable,
    AiBackendClientErrorType.backendError => _typeFromBackendStatus(error),
    AiBackendClientErrorType.invalidResponse ||
    AiBackendClientErrorType.malformedJson => AnalyzerErrorType.unknown,
  };
}

AnalyzerErrorType _typeFromBackendStatus(AiBackendClientException error) {
  final statusCode = error.statusCode;
  if (statusCode == 401 || statusCode == 403) {
    return AnalyzerErrorType.authentication;
  }
  if (statusCode == 429) {
    return AnalyzerErrorType.quotaExceeded;
  }
  if (statusCode == 400 || statusCode == 415 || statusCode == 422) {
    return AnalyzerErrorType.invalidImage;
  }
  if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
    return AnalyzerErrorType.providerUnavailable;
  }

  return AnalyzerErrorType.unknown;
}

AnalyzerErrorType _typeFromMessage(String message) {
  final normalized = message.toLowerCase();
  if (normalized.contains('timeout') || normalized.contains('timed out')) {
    return AnalyzerErrorType.timeout;
  }
  if (normalized.contains('network') || normalized.contains('offline')) {
    return AnalyzerErrorType.network;
  }
  if (normalized.contains('image')) {
    return AnalyzerErrorType.invalidImage;
  }
  if (normalized.contains('quota') || normalized.contains('limit')) {
    return AnalyzerErrorType.quotaExceeded;
  }
  if (normalized.contains('auth') || normalized.contains('unauthorized')) {
    return AnalyzerErrorType.authentication;
  }
  if (normalized.contains('not enabled') ||
      normalized.contains('not configured') ||
      normalized.contains('unavailable')) {
    return AnalyzerErrorType.providerUnavailable;
  }

  return AnalyzerErrorType.unknown;
}
