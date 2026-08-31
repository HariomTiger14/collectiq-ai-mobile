import 'package:collectiq_ai/core/network/api_constants.dart' as net;
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// GDPR/CCPA-style "export my data" and "delete my account".
///
/// Export still files a request for an admin to process from the console.
///
/// Deletion does NOT: Apple's guideline 5.1.1(v) requires an account to be
/// deletable from inside the app without a human approving it, so
/// [scheduleDeletion] starts a 30-day grace period server-side and a backend
/// cron carries it out when the window closes. Nothing is deleted at the
/// moment the user confirms -- until then [cancelDeletion] fully restores the
/// account, which is what signing back in offers.
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

  /// Starts the grace period. Returns the date the account will be erased.
  ///
  /// Idempotent server-side: confirming twice returns the deletion already
  /// scheduled rather than moving the date.
  Future<DateTime?> scheduleDeletion() async {
    final token = await _requireAccessToken();
    final response = await _dio.post<Map<String, dynamic>>(
      '$baseUrl/data-requests/deletion/schedule',
      options: _authOptions(token),
    );
    return _parseScheduledFor(response.data?['request']);
  }

  /// Cancels a pending deletion. Nothing was deleted, so this fully restores
  /// the account.
  Future<void> cancelDeletion() async {
    final token = await _requireAccessToken();
    try {
      await _dio.post<Map<String, dynamic>>(
        '$baseUrl/data-requests/deletion/cancel',
        options: _authOptions(token),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        // Already cancelled or already purged -- either way there is nothing
        // pending, which is the state the caller wanted.
        return;
      }
      rethrow;
    }
  }

  /// When the account is due to be erased, or null if no deletion is pending.
  ///
  /// Read at launch to decide whether to show the deletion gate. Network
  /// failures deliberately surface to the caller rather than being swallowed
  /// as "nothing scheduled" -- see AccountDeletionGate for why that direction
  /// of failure is the safe one.
  Future<DateTime?> pendingDeletionDate() async {
    final token = await _requireAccessToken();
    final response = await _dio.get<Map<String, dynamic>>(
      '$baseUrl/data-requests/deletion/status',
      options: _authOptions(token),
    );
    final data = response.data;
    if (data == null || data['scheduled'] != true) {
      return null;
    }
    return _parseDate(data['scheduledFor']);
  }

  Options _authOptions(String token) => Options(
    headers: {'Authorization': 'Bearer $token'},
    sendTimeout: _timeout,
    receiveTimeout: _timeout,
  );

  DateTime? _parseScheduledFor(Object? request) {
    if (request is Map) {
      return _parseDate(request['scheduledFor'] ?? request['scheduled_for']);
    }
    return null;
  }

  DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }

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
