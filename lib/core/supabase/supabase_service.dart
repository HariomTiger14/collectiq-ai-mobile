import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      );

  static SupabaseService? _instance;

  final SupabaseConfig config;
  final Dio _dio;

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

  Future<SupabaseAuthSession> signInAnonymously() async {
    _ensureConfigured();
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/v1/signup',
      data: const {
        'data': {'auth_mode': 'anonymous'},
      },
    );

    return SupabaseAuthSession.fromJson(response.data ?? {});
  }

  Future<SupabaseAuthSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _ensureConfigured();
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/v1/token',
      queryParameters: const {'grant_type': 'password'},
      data: {'email': email, 'password': password},
    );

    return SupabaseAuthSession.fromJson(response.data ?? {});
  }

  Future<void> signOut(String accessToken) async {
    _ensureConfigured();
    await _dio.post<void>(
      '/auth/v1/logout',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
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
  });

  final String userId;
  final String? email;
  final String accessToken;
  final String displayName;
  final bool isAnonymous;

  factory SupabaseAuthSession.fromJson(Map<String, dynamic> json) {
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
    );
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
