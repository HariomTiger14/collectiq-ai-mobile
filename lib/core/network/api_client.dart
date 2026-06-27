import 'package:collectiq_ai/core/network/api_constants.dart';
import 'package:collectiq_ai/core/network/network_exceptions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the active environment configuration.
final environmentConfigProvider = Provider<EnvironmentConfig>((ref) {
  return EnvironmentConfig.fromEnvironment();
});

/// Provides the configured API client.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(config: ref.watch(environmentConfigProvider));
});

/// Lightweight Dio-backed API client for future Azure integrations.
class ApiClient {
  /// Creates an API client for the supplied environment.
  ApiClient({required EnvironmentConfig config})
    : _config = config,
      _dio = Dio(
        BaseOptions(
          baseUrl: config.baseUrl,
          connectTimeout: ApiConstants.connectionTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

  final EnvironmentConfig _config;

  final Dio _dio;

  /// Current API base URL.
  String get baseUrl => _dio.options.baseUrl;

  /// Executes a GET request.
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    _logRequest('GET', path);
    try {
      return await _dio.get<dynamic>(path, queryParameters: queryParameters);
    } on DioException catch (error) {
      _logError('GET', path, error);
      throw NetworkException.fromDioException(error);
    }
  }

  /// Executes a POST request.
  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Options? options,
  }) async {
    _logRequest('POST', path);
    try {
      return await _dio.post<dynamic>(path, data: data, options: options);
    } on DioException catch (error) {
      _logError('POST', path, error);
      throw NetworkException.fromDioException(error);
    }
  }

  /// Executes a DELETE request.
  Future<Response<dynamic>> delete(String path, {Object? data}) async {
    _logRequest('DELETE', path);
    try {
      return await _dio.delete<dynamic>(path, data: data);
    } on DioException catch (error) {
      _logError('DELETE', path, error);
      throw NetworkException.fromDioException(error);
    }
  }

  void _logRequest(String method, String path) {
    debugPrint(
      '[ApiClient] platform=$defaultTargetPlatform '
      'environment=${_config.environment.name} '
      'baseUrl=$baseUrl method=$method url=${_fullUrl(path)}',
    );
  }

  void _logError(String method, String path, DioException error) {
    debugPrint(
      '[ApiClient] error platform=$defaultTargetPlatform '
      'environment=${_config.environment.name} '
      'baseUrl=$baseUrl method=$method url=${_fullUrl(path)} '
      'type=${error.type.name} status=${error.response?.statusCode} '
      'message=${error.message}',
    );
  }

  String _fullUrl(String path) {
    final base = Uri.parse(baseUrl);
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return base.resolve(normalizedPath).toString();
  }
}
