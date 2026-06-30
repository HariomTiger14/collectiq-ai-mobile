import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:image_picker/image_picker.dart';

/// Supported AI analysis provider choices.
enum AiAnalysisProviderType {
  /// Current mock/local analysis flow.
  mock,

  /// Placeholder for a future OpenAI Vision implementation.
  openAiVision,

  /// Placeholder for a future Gemini Vision implementation.
  geminiVision;

  /// Parses a provider type from configuration text.
  static AiAnalysisProviderType fromConfig(String value) {
    return switch (value.trim().toLowerCase()) {
      'openai' ||
      'openai_vision' ||
      'openaivision' => AiAnalysisProviderType.openAiVision,
      'gemini' ||
      'gemini_vision' ||
      'geminivision' => AiAnalysisProviderType.geminiVision,
      _ => AiAnalysisProviderType.mock,
    };
  }

  /// Build/config value used for this provider.
  String get configValue {
    return switch (this) {
      AiAnalysisProviderType.mock => 'mock',
      AiAnalysisProviderType.openAiVision => 'openai_vision',
      AiAnalysisProviderType.geminiVision => 'gemini_vision',
    };
  }

  /// Human-readable provider name.
  String get displayName {
    return switch (this) {
      AiAnalysisProviderType.mock => 'Mock AI',
      AiAnalysisProviderType.openAiVision => 'OpenAI Vision',
      AiAnalysisProviderType.geminiVision => 'Gemini Vision',
    };
  }

  /// Whether this provider can run analysis in the current app build.
  bool get isAvailable {
    return this == AiAnalysisProviderType.mock;
  }

  /// Short status label for developer settings.
  String get statusLabel {
    return isAvailable ? 'Active' : 'Coming soon';
  }
}

/// Lightweight configuration for choosing the analysis provider.
class AiAnalysisProviderConfig {
  /// Creates provider configuration.
  const AiAnalysisProviderConfig({
    this.type = AiAnalysisProviderType.mock,
    this.backendAnalysisEndpointUrl = '',
  });

  /// Creates provider configuration from compile-time environment values.
  factory AiAnalysisProviderConfig.fromEnvironment() {
    const configuredProvider = String.fromEnvironment(
      'AI_ANALYSIS_PROVIDER',
      defaultValue: 'mock',
    );
    const backendAnalysisEndpointUrl = String.fromEnvironment(
      'AI_BACKEND_ANALYSIS_ENDPOINT_URL',
    );

    return AiAnalysisProviderConfig(
      type: AiAnalysisProviderType.fromConfig(configuredProvider),
      backendAnalysisEndpointUrl: backendAnalysisEndpointUrl,
    );
  }

  /// Selected analysis provider.
  final AiAnalysisProviderType type;

  /// Future CollectIQ backend endpoint URL for server-side AI analysis.
  ///
  /// This must point to the app backend/proxy, not directly to OpenAI/Gemini.
  /// API keys must stay server-side and must never be shipped in Flutter.
  final String backendAnalysisEndpointUrl;

  /// Whether a backend/proxy endpoint was supplied through build config.
  bool get hasBackendAnalysisEndpoint =>
      backendAnalysisEndpointUrl.trim().isNotEmpty;

  /// Whether the selected provider is currently implemented and runnable.
  bool get isSelectedProviderAvailable => type.isAvailable;

  /// Safe user-facing warning for the selected provider.
  String get selectedProviderMessage {
    return switch (type) {
      AiAnalysisProviderType.mock =>
        'Mock mode is active. Results are generated locally for development.',
      AiAnalysisProviderType.openAiVision =>
        hasBackendAnalysisEndpoint
            ? 'OpenAI Vision is configured for a backend endpoint, but the mobile integration is not implemented yet.'
            : 'OpenAI Vision requires the CollectIQ AI backend endpoint before it can be enabled.',
      AiAnalysisProviderType.geminiVision =>
        'Gemini Vision is prepared as a future backend-only provider.',
    };
  }
}

/// Input sent to an AI analysis provider.
class AiAnalysisRequest {
  /// Creates an immutable analysis request.
  const AiAnalysisRequest({
    required this.imagePath,
    this.image,
    this.metadata = const {},
  });

  /// Selected image path or image reference.
  final String imagePath;

  /// Selected image file, when available.
  final XFile? image;

  /// Optional provider-specific metadata.
  final Map<String, Object?> metadata;
}

/// Output returned by an AI analysis provider.
class AiAnalysisResult {
  /// Creates an immutable analysis output.
  const AiAnalysisResult({
    required this.scanResult,
    required this.recommendation,
  });

  /// Existing scan result model consumed by the scanner UI.
  final ScanResult scanResult;

  /// Recommendation displayed and saved with the portfolio item.
  final String recommendation;
}

/// Provider abstraction for collectible image analysis.
abstract interface class AiAnalysisProvider {
  /// Analyzes a collectible image and returns the existing scan result model.
  Future<AiAnalysisResult> analyze(AiAnalysisRequest request);
}

/// User-safe provider error.
class AiAnalysisException implements Exception {
  /// Creates an analysis exception.
  const AiAnalysisException(this.message);

  /// Message safe to show in the scanner error panel.
  final String message;

  @override
  String toString() => 'AiAnalysisException: $message';
}
