import 'dart:io';

import 'package:collectiq_ai/core/network/api_constants.dart' as net;
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Real threaded support tickets, replacing the plain mailto "Contact
/// support" link. Same authenticated-Dio pattern as
/// CloudEntitlementRepository/DataRequestRepository -- the user's own
/// Supabase session bearer token, no separate auth scheme.
class SupportTicketRepository {
  SupportTicketRepository({
    required this.baseUrl,
    required this.supabaseService,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final String baseUrl;
  final SupabaseService supabaseService;
  final Dio _dio;

  static const _timeout = Duration(seconds: 15);

  Future<String> _requireAccessToken() async {
    final session = await supabaseService.currentSession();
    if (session == null ||
        session.accessToken.isEmpty ||
        session.isAnonymous) {
      throw StateError('Sign in required to use support.');
    }
    return session.accessToken;
  }

  Future<Map<String, dynamic>> createTicket({
    required String category,
    required String subject,
    required String message,
    String? referencedItemId,
  }) async {
    final token = await _requireAccessToken();
    final response = await _dio.post<Map<String, dynamic>>(
      '$baseUrl/support/tickets',
      data: {
        'category': category,
        'subject': subject,
        'message': message,
        if (referencedItemId != null) 'referencedItemId': referencedItemId,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        sendTimeout: _timeout,
        receiveTimeout: _timeout,
      ),
    );
    return response.data ?? {};
  }

  Future<List<Map<String, dynamic>>> listMyTickets() async {
    final token = await _requireAccessToken();
    final response = await _dio.get<Map<String, dynamic>>(
      '$baseUrl/support/tickets/mine',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        sendTimeout: _timeout,
        receiveTimeout: _timeout,
      ),
    );
    final tickets = response.data?['tickets'];
    if (tickets is List) {
      return tickets.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getTicketThread(String ticketId) async {
    final token = await _requireAccessToken();
    final response = await _dio.get<Map<String, dynamic>>(
      '$baseUrl/support/tickets/$ticketId',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        sendTimeout: _timeout,
        receiveTimeout: _timeout,
      ),
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> reply({
    required String ticketId,
    required String body,
  }) async {
    final token = await _requireAccessToken();
    final response = await _dio.post<Map<String, dynamic>>(
      '$baseUrl/support/tickets/$ticketId/reply',
      data: {'body': body},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        sendTimeout: _timeout,
        receiveTimeout: _timeout,
      ),
    );
    return response.data ?? {};
  }

  Future<void> uploadAttachment({
    required String messageId,
    required File file,
  }) async {
    final token = await _requireAccessToken();
    final fileName = file.path.split(Platform.pathSeparator).last;
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    await _dio.post<Map<String, dynamic>>(
      '$baseUrl/support/messages/$messageId/attachments',
      data: form,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        sendTimeout: _timeout,
        receiveTimeout: _timeout,
      ),
    );
  }
}

final supportTicketRepositoryProvider = Provider<SupportTicketRepository>((
  ref,
) {
  return SupportTicketRepository(
    baseUrl: net.EnvironmentConfig.fromEnvironment().baseUrl,
    supabaseService: ref.watch(supabaseServiceProvider),
  );
});
