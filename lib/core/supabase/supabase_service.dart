import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance(config: ref.watch(supabaseConfigProvider));
});

class SupabaseService {
  SupabaseService._(this.config)
    : _dio = Dio(
        BaseOptions(
          baseUrl: config.url,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (config.anonKey.isNotEmpty) 'apikey': config.anonKey,
            if (config.anonKey.isNotEmpty)
              'Authorization': 'Bearer ${config.anonKey}',
          },
        ),
      ) {
    _logInitialization();
  }

  static SupabaseService? _instance;
  static const _sessionKey = 'supabase_auth_session';

  final SupabaseConfig config;
  final Dio _dio;
  SupabaseAuthSession? _cachedSession;

  static SupabaseService instance({required SupabaseConfig config}) {
    final current = _instance;
    if (current != null &&
        current.config.url == config.url &&
        current.config.anonKey == config.anonKey &&
        current.config.isEnabled == config.isEnabled) {
      return current;
    }

    _instance = SupabaseService._(config);
    return _instance!;
  }

  bool get isConfigured => config.isConfigured;

  Future<SupabaseAuthSession?> currentSession() async {
    if (!isConfigured) {
      debugPrint('[Supabase] current session skipped: not configured');
      return null;
    }

    final cachedSession = _cachedSession;
    if (_isSessionUsableForCurrentProject(cachedSession)) {
      debugPrint(
        '[Supabase] current user id from memory: ${cachedSession!.userId}',
      );
      return cachedSession;
    }

    final preferences = await SharedPreferences.getInstance();
    final encodedSession = preferences.getString(_sessionKey);
    if (encodedSession == null || encodedSession.isEmpty) {
      debugPrint('[Supabase] auth session exists: no');
      return null;
    }
    debugPrint('[Supabase] auth session exists: yes');

    final session = SupabaseAuthSession.fromJsonString(encodedSession);
    if (!_isSessionUsableForCurrentProject(session)) {
      debugPrint(
        '[Supabase] cached session ignored: project URL changed or '
        'session is incomplete',
      );
      await clearSession();
      return null;
    }

    _cachedSession = session;
    debugPrint('[Supabase] current user id from storage: ${session.userId}');
    return session;
  }

  Future<SupabaseAuthSession> ensureAnonymousSession() async {
    final session = await currentSession();
    if (session != null && session.accessToken.isNotEmpty) {
      final isValid = await _validateSession(session);
      if (!isValid) {
        debugPrint(
          '[Supabase] cached session invalid; clearing and signing in again',
        );
        await clearSession();
        return signInAnonymously();
      }

      return session;
    }

    return signInAnonymously();
  }

  Future<SupabaseAuthSession> signInAnonymously() async {
    _ensureConfigured();
    debugPrint('[Supabase] anonymous sign-in starting');
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/v1/signup',
        data: const {
          'data': {'auth_mode': 'anonymous'},
        },
      );

      final session = SupabaseAuthSession.fromJson(
        response.data ?? {},
        projectUrl: config.url,
      );
      _ensureValidSession(session);
      await _saveSession(session);
      debugPrint(
        '[Supabase] anonymous sign-in success. user id: ${session.userId}',
      );
      return session;
    } on DioException catch (error) {
      logDioException(error, payload: const {'data': '<metadata>'});
      final message = _authFailureMessage(error);
      debugPrint('[Supabase] anonymous sign-in failed: $message');
      throw SupabaseAuthException(message);
    } on FormatException catch (error) {
      debugPrint('[Supabase] anonymous sign-in invalid response: $error');
      throw const SupabaseAuthException(
        'Supabase returned an invalid anonymous auth response.',
      );
    }
  }

  Future<SupabaseAuthSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _ensureConfigured();
    late final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        '/auth/v1/token',
        queryParameters: const {'grant_type': 'password'},
        data: {'email': email, 'password': password},
      );
    } on DioException catch (error) {
      logDioException(error, payload: const {'email': '', 'password': ''});
      rethrow;
    }

    final session = SupabaseAuthSession.fromJson(
      response.data ?? {},
      projectUrl: config.url,
    );
    _ensureValidSession(session);
    await _saveSession(session);
    return session;
  }

  Future<void> signOut(String accessToken) async {
    _ensureConfigured();
    try {
      await _dio.post<void>(
        '/auth/v1/logout',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (error) {
      logDioException(error);
      rethrow;
    }
    await clearSession();
  }

  Future<void> clearSession() async {
    _cachedSession = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
  }

  Future<Response<T>> authenticatedGet<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final session = await ensureAnonymousSession();
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: _authOptions(session),
      );
    } on DioException catch (error) {
      logDioException(error);
      rethrow;
    }
  }

  Future<Response<T>> authenticatedPost<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final session = await ensureAnonymousSession();
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeAuthOptions(session, options),
      );
    } on DioException catch (error) {
      logDioException(error, payload: data);
      rethrow;
    }
  }

  Future<void> _saveSession(SupabaseAuthSession session) async {
    _cachedSession = session;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, session.toJsonString());
  }

  void _logInitialization() {
    if (!config.isEnabled) {
      debugPrint('[Supabase] initialization skipped: disabled');
      return;
    }

    if (!config.isConfigured) {
      debugPrint(
        '[Supabase] initialization incomplete. URL configured: '
        '${config.hasUrl}, anon key configured: ${config.hasAnonKey}',
      );
      return;
    }

    debugPrint('[Supabase] initialization success');
  }

  bool _isSessionUsableForCurrentProject(SupabaseAuthSession? session) {
    if (session == null ||
        session.accessToken.isEmpty ||
        session.userId.isEmpty ||
        session.projectUrl.isEmpty) {
      return false;
    }

    return session.projectUrl == config.url;
  }

  void _ensureValidSession(SupabaseAuthSession session) {
    if (session.accessToken.isEmpty || session.userId.isEmpty) {
      throw const FormatException('Missing access token or user id.');
    }
  }

  Future<bool> _validateSession(SupabaseAuthSession session) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/auth/v1/user',
        options: _authOptions(session),
      );
      final userId = response.data?['id'] as String?;
      final isValid = userId == session.userId;
      debugPrint('[Supabase] cached session validation success: $isValid');
      return isValid;
    } on DioException catch (error) {
      logDioException(error);
      debugPrint(
        '[Supabase] cached session validation failed: '
        '${_authFailureMessage(error)}',
      );
      return false;
    }
  }

  String _authFailureMessage(DioException error) {
    final responseData = error.response?.data;
    final serverMessage = _serverErrorMessage(responseData);
    if (serverMessage != null && serverMessage.isNotEmpty) {
      final normalized = serverMessage.toLowerCase();
      if (normalized.contains('anonymous') &&
          (normalized.contains('disabled') ||
              normalized.contains('not enabled'))) {
        return 'Anonymous sign-in is disabled in Supabase Auth settings.';
      }

      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        return 'Invalid Supabase anon key.';
      }

      return serverMessage;
    }

    if (error.response?.statusCode == 401 ||
        error.response?.statusCode == 403) {
      return 'Invalid Supabase anon key.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Network error while connecting to Supabase Auth.';
    }

    return error.message ?? 'Auth failed.';
  }

  String? _serverErrorMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      for (final key in ['msg', 'message', 'error_description', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return null;
  }

  Options _authOptions(SupabaseAuthSession session) {
    return Options(headers: {'Authorization': 'Bearer ${session.accessToken}'});
  }

  Options _mergeAuthOptions(SupabaseAuthSession session, Options? options) {
    final headers = <String, dynamic>{
      ...?options?.headers,
      'Authorization': 'Bearer ${session.accessToken}',
    };
    return (options ?? Options()).copyWith(headers: headers);
  }

  static void logDioException(DioException error, {Object? payload}) {
    final request = error.requestOptions;
    debugPrint('[Supabase HTTP] method: ${request.method}');
    debugPrint('[Supabase HTTP] url: ${request.uri}');
    debugPrint('[Supabase HTTP] status: ${error.response?.statusCode}');
    debugPrint('[Supabase HTTP] response.data: ${error.response?.data}');
    debugPrint(
      '[Supabase HTTP] response.headers: ${error.response?.headers.map}',
    );
    debugPrint(
      '[Supabase HTTP] request.headers: ${_safeHeaders(request.headers)}',
    );
    debugPrint(
      '[Supabase HTTP] payload.keys: ${_payloadKeys(payload ?? request.data)}',
    );
  }

  static Map<String, Object?> _safeHeaders(Map<String, dynamic> headers) {
    return {
      for (final entry in headers.entries)
        entry.key: _isSecretHeader(entry.key) ? '<redacted>' : entry.value,
    };
  }

  static bool _isSecretHeader(String key) {
    final normalized = key.toLowerCase();
    return normalized == 'apikey' || normalized == 'authorization';
  }

  static Object _payloadKeys(Object? payload) {
    if (payload == null) {
      return const [];
    }
    if (payload is Map) {
      return payload.keys.map((key) => key.toString()).toList();
    }
    if (payload is List<int>) {
      return 'bytes(length=${payload.length})';
    }
    if (payload is List) {
      final keys = <String>{};
      for (final item in payload) {
        if (item is Map) {
          keys.addAll(item.keys.map((key) => key.toString()));
        }
      }
      return keys.isEmpty ? 'list(length=${payload.length})' : keys.toList();
    }
    return payload.runtimeType.toString();
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw const SupabaseNotConfiguredException();
    }
  }
}

class SupabaseAuthSession {
  const SupabaseAuthSession({
    required this.userId,
    required this.email,
    required this.accessToken,
    required this.displayName,
    required this.isAnonymous,
    required this.projectUrl,
  });

  final String userId;
  final String? email;
  final String accessToken;
  final String displayName;
  final bool isAnonymous;
  final String projectUrl;

  factory SupabaseAuthSession.fromJson(
    Map<String, dynamic> json, {
    required String projectUrl,
  }) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final metadata = user['user_metadata'] is Map<String, dynamic>
        ? user['user_metadata'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final email = user['email'] as String?;
    final displayName =
        metadata['display_name'] as String? ??
        metadata['name'] as String? ??
        email ??
        'Supabase Collector';

    return SupabaseAuthSession(
      userId: user['id'] as String? ?? '',
      email: email,
      accessToken: json['access_token'] as String? ?? '',
      displayName: displayName,
      isAnonymous: email == null || email.isEmpty,
      projectUrl: projectUrl,
    );
  }

  factory SupabaseAuthSession.fromJsonString(String value) {
    final decoded = Uri.splitQueryString(value);
    return SupabaseAuthSession(
      userId: decoded['userId'] ?? '',
      email: decoded['email']?.isEmpty == true ? null : decoded['email'],
      accessToken: decoded['accessToken'] ?? '',
      displayName: decoded['displayName'] ?? 'Supabase Collector',
      isAnonymous: decoded['isAnonymous'] == 'true',
      projectUrl: decoded['projectUrl'] ?? '',
    );
  }

  String toJsonString() {
    return Uri(
      queryParameters: {
        'userId': userId,
        'email': email ?? '',
        'accessToken': accessToken,
        'displayName': displayName,
        'isAnonymous': isAnonymous.toString(),
        'projectUrl': projectUrl,
      },
    ).query;
  }
}

class SupabaseNotConfiguredException implements Exception {
  const SupabaseNotConfiguredException();

  @override
  String toString() {
    return 'Supabase is not configured. Provide SUPABASE_URL, '
        'SUPABASE_ANON_KEY, and SUPABASE_ENABLED=true.';
  }
}

class SupabaseAuthException implements Exception {
  const SupabaseAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
