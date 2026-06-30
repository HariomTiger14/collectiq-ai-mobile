import 'package:collectiq_ai/features/ai/data/models/ai_backend_analysis_models.dart';

/// Result of validating a future backend AI contract payload.
class AiBackendContractValidationResult {
  /// Creates an immutable validation result.
  const AiBackendContractValidationResult({required this.issues});

  /// Successful validation.
  const AiBackendContractValidationResult.valid() : issues = const [];

  /// Human-readable, non-secret validation issues.
  final List<String> issues;

  /// Whether validation passed.
  bool get isValid => issues.isEmpty;

  /// Short Settings/test label.
  String get statusLabel => isValid ? 'Valid' : 'Invalid';
}

/// Validates future backend AI request and response contract payloads.
class AiBackendContractValidator {
  /// Creates a contract validator.
  const AiBackendContractValidator();

  /// Validates request fields before they are sent to a future backend.
  AiBackendContractValidationResult validateRequest(
    AiBackendAnalysisRequest request,
  ) {
    final issues = <String>[];
    if (request.imagePath.trim().isEmpty) {
      issues.add('imagePath is required.');
    }
    if (request.imageSource.trim().isEmpty) {
      issues.add('imageSource is required.');
    }
    if (!_allowedImageSources.contains(request.imageSource.trim())) {
      issues.add('imageSource must be camera, gallery, sample, or unknown.');
    }
    if (request.timestamp.year < 2020) {
      issues.add('timestamp must be a current ISO-8601 date.');
    }

    return AiBackendContractValidationResult(issues: issues);
  }

  /// Validates raw backend response payload shape and required fields.
  AiBackendContractValidationResult validateResponsePayload(
    Map<String, dynamic> json,
  ) {
    final issues = <String>[];
    if (_isBlank(json['itemName'] ?? json['title'] ?? json['name'])) {
      issues.add('itemName is required.');
    }
    if (_isBlank(json['category'] ?? json['type'])) {
      issues.add('category is required.');
    }
    if (!_hasNumericValue(
      json['estimatedValue'] ??
          json['estimatedMarketValue'] ??
          json['marketValue'] ??
          _valueRange(json)['estimated'] ??
          _valueRange(json)['mid'],
    )) {
      issues.add('estimatedValue is required.');
    }
    if (!_hasNumericValue(json['confidence'])) {
      issues.add('confidence is required.');
    }
    if (_isBlank(json['condition'])) {
      issues.add('condition is required.');
    }
    if (_isBlank(json['recommendation'])) {
      issues.add('recommendation is required.');
    }

    return AiBackendContractValidationResult(issues: issues);
  }

  /// Validates a parsed response after safe defaults have been applied.
  AiBackendContractValidationResult validateResponse(
    AiBackendAnalysisResponse response,
  ) {
    final issues = <String>[];
    if (response.itemName.trim().isEmpty ||
        response.itemName == 'Unknown collectible') {
      issues.add('itemName is missing or defaulted.');
    }
    if (response.category.trim().isEmpty ||
        response.category == 'Collectible') {
      issues.add('category is missing or defaulted.');
    }
    if (response.estimatedValue <= 0) {
      issues.add('estimatedValue must be greater than zero.');
    }
    if (response.confidence <= 0 || response.confidence > 1) {
      issues.add('confidence must be between 0 and 1.');
    }
    if (response.condition.trim().isEmpty || response.condition == 'Unknown') {
      issues.add('condition is missing or defaulted.');
    }

    return AiBackendContractValidationResult(issues: issues);
  }

  Map<String, dynamic> _valueRange(Map<String, dynamic> json) {
    final value = json['valueRange'];
    return value is Map<String, dynamic> ? value : const {};
  }

  bool _isBlank(Object? value) {
    return value is! String || value.trim().isEmpty;
  }

  bool _hasNumericValue(Object? value) {
    if (value is num) {
      return true;
    }
    if (value is String) {
      return double.tryParse(value) != null;
    }
    return false;
  }
}

const _allowedImageSources = {'camera', 'gallery', 'sample', 'unknown'};

/// Readiness state for future backend endpoint integration.
class AiBackendEndpointReadiness {
  /// Creates endpoint readiness.
  const AiBackendEndpointReadiness({
    required this.isConfigured,
    required this.isValid,
    required this.isReleaseSafe,
    required this.message,
  });

  /// Whether a URL was supplied.
  final bool isConfigured;

  /// Whether the supplied URL is structurally valid.
  final bool isValid;

  /// Whether the URL is safe for release builds.
  final bool isReleaseSafe;

  /// Developer-safe readiness message.
  final String message;

  /// Settings label for configuration state.
  String get configuredLabel => isConfigured ? 'Ready' : 'Not configured';

  /// Settings label for URL validity.
  String get validityLabel => isValid ? 'Valid' : 'Invalid';

  /// Settings label for release safety.
  String get releaseSafeLabel => isReleaseSafe ? 'Yes' : 'No';
}

/// Checks backend endpoint readiness without calling the network.
class AiBackendEndpointReadinessChecker {
  /// Creates a readiness checker.
  const AiBackendEndpointReadinessChecker();

  /// Evaluates a future backend URL.
  AiBackendEndpointReadiness check({
    required String endpointUrl,
    bool isReleaseMode = false,
  }) {
    final normalized = endpointUrl.trim();
    if (normalized.isEmpty) {
      return const AiBackendEndpointReadiness(
        isConfigured: false,
        isValid: false,
        isReleaseSafe: false,
        message: 'Backend AI endpoint is not configured.',
      );
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.trim().isEmpty ||
        !_allowedSchemes.contains(uri.scheme.toLowerCase())) {
      return const AiBackendEndpointReadiness(
        isConfigured: true,
        isValid: false,
        isReleaseSafe: false,
        message: 'Backend AI endpoint URL is invalid.',
      );
    }

    final isHttps = uri.scheme.toLowerCase() == 'https';
    final isLocalHttp =
        uri.scheme.toLowerCase() == 'http' && _isLocalHost(uri.host);
    final releaseSafe = isHttps || (!isReleaseMode && isLocalHttp);
    final message = isHttps
        ? 'Backend AI endpoint is HTTPS and release-safe.'
        : isLocalHttp
        ? 'Local HTTP backend endpoint is allowed for debug testing only.'
        : 'HTTP backend endpoint is not release-safe.';

    return AiBackendEndpointReadiness(
      isConfigured: true,
      isValid: true,
      isReleaseSafe: releaseSafe,
      message: message,
    );
  }

  bool _isLocalHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '10.0.2.2' ||
        normalized.startsWith('192.168.') ||
        normalized.startsWith('10.') ||
        normalized.startsWith('172.16.') ||
        normalized.startsWith('172.17.') ||
        normalized.startsWith('172.18.') ||
        normalized.startsWith('172.19.') ||
        normalized.startsWith('172.2') ||
        normalized.startsWith('172.30.') ||
        normalized.startsWith('172.31.');
  }
}

const _allowedSchemes = {'http', 'https'};
