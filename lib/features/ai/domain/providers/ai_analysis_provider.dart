import 'package:collectiq_ai/core/network/api_constants.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:image_picker/image_picker.dart';

/// Supported AI analysis provider choices.
enum AiAnalysisProviderType {
  /// Explicit local/QA analysis flow.
  mock,

  /// Backend-backed OpenAI Vision implementation.
  openAiVision,

  /// Backend-backed Gemini Vision implementation.
  geminiVision;

  /// Parses a provider type from configuration text.
  static AiAnalysisProviderType fromConfig(String value) {
    return switch (value.trim().toLowerCase()) {
      'openai' ||
      'openai_vision' ||
      'openaivision' => AiAnalysisProviderType.openAiVision,
      'gemini' ||
      'gemini_vision' ||
      'auto' ||
      'gemini_openai' ||
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
  bool get isAvailable => true;

  /// Whether this provider returns local-only synthetic results.
  bool get isLocalOnly => this == AiAnalysisProviderType.mock;

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
      defaultValue: '',
    );
    const backendAnalysisEndpointUrl = String.fromEnvironment(
      'AI_BACKEND_ANALYSIS_ENDPOINT_URL',
    );
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const appEnvironment = String.fromEnvironment('APP_ENV');
    const legacyEnvironment = String.fromEnvironment(
      'COLLECTIQ_ENV',
      defaultValue: 'local',
    );
    final networkConfig = EnvironmentConfig.fromEnvironment();

    final provider = configuredProvider.trim().isEmpty
        ? _defaultProviderFor(
            appEnvironment: appEnvironment,
            legacyEnvironment: legacyEnvironment,
          )
        : AiAnalysisProviderType.fromConfig(configuredProvider);

    return AiAnalysisProviderConfig(
      type: provider,
      backendAnalysisEndpointUrl: resolveBackendAnalysisEndpointUrl(
        environment: networkConfig.environment,
        backendAnalysisEndpointUrl: backendAnalysisEndpointUrl,
        apiBaseUrl: apiBaseUrl,
      ),
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
            ? 'OpenAI Vision is routed through the PackLox backend.'
            : 'OpenAI Vision requires the CollectIQ AI backend endpoint before it can be enabled.',
      AiAnalysisProviderType.geminiVision =>
        hasBackendAnalysisEndpoint
            ? 'Gemini Vision is routed through the PackLox backend.'
            : 'Gemini Vision requires the PackLox backend endpoint before it can be enabled.',
    };
  }
}

AiAnalysisProviderType _defaultProviderFor({
  required String appEnvironment,
  required String legacyEnvironment,
}) {
  final raw = appEnvironment.trim().isNotEmpty
      ? appEnvironment
      : legacyEnvironment;
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty ||
      normalized == 'local' ||
      normalized == 'development' ||
      normalized == 'dev') {
    return AiAnalysisProviderType.mock;
  }

  return AiAnalysisProviderType.geminiVision;
}

/// Resolves the backend-only analyzer endpoint for configured environments.
///
/// SIT defaults to the live PackLox backend. Other environments keep the
/// endpoint disabled unless an explicit endpoint or API base URL is supplied.
String resolveBackendAnalysisEndpointUrl({
  required AppEnvironment environment,
  required String backendAnalysisEndpointUrl,
  required String apiBaseUrl,
}) {
  final explicitEndpoint = backendAnalysisEndpointUrl.trim();
  if (explicitEndpoint.isNotEmpty) {
    return explicitEndpoint;
  }

  final baseUrl = apiBaseUrl.trim();
  if (baseUrl.isEmpty) {
    if (environment != AppEnvironment.sit) {
      return '';
    }

    return '${ApiConstants.baseUrlFor(environment)}/analyze';
  }

  return '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/analyze';
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
