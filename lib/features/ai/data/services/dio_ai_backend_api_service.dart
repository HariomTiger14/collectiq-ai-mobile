import 'dart:convert';

import 'package:collectiq_ai/features/ai/data/models/ai_backend_analysis_models.dart';
import 'package:collectiq_ai/features/ai/data/models/ai_backend_contract_validation.dart';
import 'package:collectiq_ai/features/ai/data/models/ai_image_upload_payload.dart';
import 'package:collectiq_ai/features/ai/domain/clients/ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/domain/services/ai_backend_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Dio-backed API service for future CollectIQ backend AI analysis.
///
/// This service calls only the configured CollectIQ backend/proxy endpoint.
/// OpenAI, Gemini, marketplace, and pricing API keys must remain server-side.
class DioAiBackendApiService implements AiBackendApiService {
  /// Creates a Dio-backed backend API service.
  DioAiBackendApiService({
    required this.endpointUrl,
    Dio? dio,
    this.timeout = const Duration(seconds: 30),
    this.validator = const AiBackendContractValidator(),
    this.readinessChecker = const AiBackendEndpointReadinessChecker(),
    this.isReleaseMode = false,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: timeout,
               receiveTimeout: timeout,
               sendTimeout: timeout,
               responseType: ResponseType.json,
               headers: const {
                 'Accept': 'application/json',
                 'Content-Type': 'application/json',
               },
             ),
           );

  /// Future backend endpoint supplied by build config.
  final String endpointUrl;

  /// Request timeout.
  final Duration timeout;

  /// Contract validator used before and after transport.
  final AiBackendContractValidator validator;

  /// Endpoint readiness checker.
  final AiBackendEndpointReadinessChecker readinessChecker;

  /// Whether the app is running in release mode.
  final bool isReleaseMode;

  final Dio _dio;

  @override
  Future<AiBackendAnalysisResponse> analyzeImage({
    required AiBackendAnalysisRequest request,
    required AiImageUploadPayload imagePayload,
    List<AiImageUploadPayload> imagePayloads = const [],
  }) async {
    _validateEndpoint();
    _validateRequest(request);

    try {
      final stopwatch = Stopwatch()..start();
      _logAnalyzerTrace(
        'http-request-start endpoint=${_safeEndpoint(endpointUrl)} '
        'file=${imagePayload.fileName} mime=${imagePayload.mimeType} '
        'sizeBytes=${imagePayload.sizeBytes} '
        'base64Length=${imagePayload.base64Image?.length ?? 0} '
        'imageCount=${_effectivePayloads(imagePayload, imagePayloads).length}',
      );
      final response = await _dio.post<dynamic>(
        endpointUrl.trim(),
        data: {
          'request': request.toJson(),
          'image': imagePayload.toMetadataJson(),
          'images': [
            for (final payload in _effectivePayloads(
              imagePayload,
              imagePayloads,
            ))
              payload.toMetadataJson(),
          ],
        },
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: timeout,
          receiveTimeout: timeout,
          validateStatus: (_) => true,
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );
      stopwatch.stop();
      _logAnalyzerTrace(
        'http-response endpoint=${_safeEndpoint(endpointUrl)} '
        'status=${response.statusCode ?? 0} '
        'durationMs=${stopwatch.elapsedMilliseconds}',
      );
      return _handleResponse(response);
    } on DioException catch (error) {
      _logAnalyzerTrace(
        'http-error endpoint=${_safeEndpoint(endpointUrl)} '
        'type=${error.type.name} status=${error.response?.statusCode ?? 0}',
      );
      throw _mapDioException(error);
    } on FormatException {
      _logAnalyzerTrace(
        'http-error endpoint=${_safeEndpoint(endpointUrl)} type=malformed_json',
      );
      throw AiBackendClientException.malformedJson();
    }
  }

  List<AiImageUploadPayload> _effectivePayloads(
    AiImageUploadPayload primary,
    List<AiImageUploadPayload> payloads,
  ) {
    if (payloads.isEmpty) {
      return [primary];
    }
    final seen = <String>{};
    return [
      for (final payload in [primary, ...payloads])
        if (seen.add(payload.localFilePath)) payload,
    ];
  }

  void _validateEndpoint() {
    final readiness = readinessChecker.check(
      endpointUrl: endpointUrl,
      isReleaseMode: isReleaseMode,
    );
    if (!readiness.isConfigured) {
      throw AiBackendClientException.endpointMissing();
    }
    if (!readiness.isValid || !readiness.isReleaseSafe) {
      throw AiBackendClientException.invalidEndpoint(readiness.message);
    }
  }

  void _validateRequest(AiBackendAnalysisRequest request) {
    final validation = validator.validateRequest(request);
    if (!validation.isValid) {
      throw AiBackendClientException.invalidResponse(
        message: 'AI analysis request is missing required image metadata.',
        details: {'issues': validation.issues},
      );
    }
  }

  AiBackendAnalysisResponse _handleResponse(Response<dynamic> response) {
    final statusCode = response.statusCode ?? 0;
    final decoded = _decodeResponseData(response.data);
    if (statusCode < 200 || statusCode >= 300) {
      throw _backendErrorFrom(decoded, statusCode);
    }

    final payload = _unwrapPayload(decoded);
    final payloadValidation = validator.validateResponsePayload(payload);
    if (!payloadValidation.isValid) {
      throw AiBackendClientException.invalidResponse(
        details: {'issues': payloadValidation.issues},
      );
    }

    final parsed = AiBackendAnalysisResponse.fromJson(payload);
    final parsedValidation = validator.validateResponse(parsed);
    if (!parsedValidation.isValid) {
      throw AiBackendClientException.invalidResponse(
        details: {'issues': parsedValidation.issues},
      );
    }

    return parsed;
  }

  AiBackendClientException _mapDioException(DioException error) {
    final response = error.response;
    if (response != null) {
      try {
        _handleResponse(response);
      } on AiBackendClientException catch (mapped) {
        return mapped;
      }
    }

    if (error.type == DioExceptionType.unknown &&
        (error.error is FormatException ||
            (error.message ?? '').contains('FormatException') ||
            (error.message ?? '').contains('Unexpected character'))) {
      return AiBackendClientException.malformedJson();
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => AiBackendClientException.timeout(),
      DioExceptionType.badResponse => AiBackendClientException.invalidResponse(
        details: {'statusCode': response?.statusCode},
      ),
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate ||
      DioExceptionType.cancel ||
      DioExceptionType.unknown => AiBackendClientException.networkUnavailable(),
    };
  }

  Map<String, dynamic> _decodeResponseData(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    throw AiBackendClientException.malformedJson();
  }

  Map<String, dynamic> _unwrapPayload(Map<String, dynamic> decoded) {
    for (final key in const ['result', 'analysis', 'data']) {
      final nested = decoded[key];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
    }
    return decoded;
  }

  AiBackendClientException _backendErrorFrom(
    Map<String, dynamic> decoded,
    int statusCode,
  ) {
    final errorJson = decoded['error'];
    final payload = errorJson is Map
        ? Map<String, dynamic>.from(errorJson)
        : decoded;
    final error = AiBackendAnalysisError.fromJson({
      'code': payload['code'] ?? 'backend_ai_error',
      'message':
          payload['message'] ?? 'Backend AI analysis failed. Please try again.',
      'retryable': payload['retryable'] ?? statusCode >= 500,
      'details': payload['details'] ?? {'statusCode': statusCode},
    });
    return AiBackendClientException.backendError(error, statusCode: statusCode);
  }

  void _logAnalyzerTrace(String message) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[AnalyzerTrace] $message');
  }

  String _safeEndpoint(String endpoint) {
    final trimmed = endpoint.trim();
    if (trimmed.isEmpty) {
      return '<empty>';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return '<invalid>';
    }
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
    ).toString();
  }
}
