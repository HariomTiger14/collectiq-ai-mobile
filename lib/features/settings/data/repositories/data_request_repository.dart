import 'package:collectiq_ai/core/network/api_constants.dart' as net;
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Files GDPR/CCPA-style "export my data" / "delete my account" requests
/// against the backend's `data_requests` queue. This only ever CREATES a
/// request -- it never performs the export or the deletion itself. Both are
/// processed by an admin from the admin console's Data requests page (a
/// deliberate human-in-the-loop step, matching how every other irreversible
/// action in this system requires a typed confirmation before it runs live).
class DataRequestRepository {
  DataRequestRepository({
    required this.baseUrl,
    required this.supabaseService,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final String baseUrl;
  final SupabaseService supabaseService;
  final Dio _dio;

  static const _timeout = Duration(seconds: 12);

  Future<String> _requireAccessToken() async {
    final session = await supabaseService.currentSession();
    if (session == null ||
        session.accessToken.isEmpty ||
        session.isAnonymous) {
      throw StateError('Sign in required to file a data request.');
    }
    return session.accessToken;
  }

  Future<void> requestExport() => _create('export');

  Future<void> requestDeletion() => _create('deletion');

  Future<void> _create(String type) async {
    final token = await _requireAccessToken();
    try {
      await _dio.post<Map<String, dynamic>>(
        '$baseUrl/data-requests',
        queryParameters: {'type': type},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) {
        throw StateError(
          'A ${type == 'export' ? 'data export' : 'account deletion'} '
          'request is already open for this account.',
        );
      }
      rethrow;
    }
  }
}

/// A signed-in user's privacy right to request an export/deletion is not
/// gated behind the cloud-sync feature flag the way portfolio sync is --
/// it's a compliance capability, not a sync feature.
final dataRequestRepositoryProvider = Provider<DataRequestRepository>((ref) {
  return DataRequestRepository(
    baseUrl: net.EnvironmentConfig.fromEnvironment().baseUrl,
    supabaseService: ref.watch(supabaseServiceProvider),
  );
});
