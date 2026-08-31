import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/support/data/repositories/support_ticket_repository.dart';
import 'package:collectiq_ai/features/support/presentation/screens/support_ticket_thread_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('adminDisplayName', () {
    test(
      'shows the brand name instead of the internal "admin_token" '
      'placeholder (real bug found live: the admin-reply endpoint '
      'authenticates with a single shared token, not a per-person login, '
      'so it has no real identity to attribute a reply to -- it stored '
      'the literal string "admin_token" as sender_label, and that leaked '
      'straight into the chat UI as if it were the replier\'s name)',
      () {
        expect(adminDisplayName('admin_token'), 'PackLox Support');
      },
    );

    test('shows the brand name for a missing/blank label too', () {
      expect(adminDisplayName(null), 'PackLox Support');
      expect(adminDisplayName(''), 'PackLox Support');
      expect(adminDisplayName('   '), 'PackLox Support');
    });

    test('shows a real name as-is when one is actually set', () {
      expect(adminDisplayName('support@packlox.com'), 'support@packlox.com');
    });
  });

  group('formatMessageTimestamp', () {
    test('returns null for a missing timestamp', () {
      expect(formatMessageTimestamp(null), isNull);
      expect(formatMessageTimestamp(''), isNull);
    });

    // A fixed reference point, so these relative labels do not depend on what
    // time of day the suite happens to run. The "today" case previously used
    // DateTime.now() minus an hour, which is yesterday between midnight and
    // 01:00 -- the test failed for one hour every night.
    final now = DateTime(2026, 3, 15, 14, 30);

    test('shows just the time for a message from today', () {
      final today = DateTime(2026, 3, 15, 13, 5);
      expect(
        formatMessageTimestamp(today.toIso8601String(), now: now),
        '1:05 PM',
      );
    });

    test('shows just the time for a message from earlier this morning', () {
      final earlyToday = DateTime(2026, 3, 15, 0, 18);
      expect(
        formatMessageTimestamp(earlyToday.toIso8601String(), now: now),
        '12:18 AM',
      );
    });

    test('prefixes "Yesterday" for a message from yesterday', () {
      final yesterday = DateTime(2026, 3, 14, 23, 18);
      expect(
        formatMessageTimestamp(yesterday.toIso8601String(), now: now),
        'Yesterday, 11:18 PM',
      );
    });

    test('shows the month and day for an older message', () {
      final older = DateTime(2026, 3, 5, 9, 5);
      expect(
        formatMessageTimestamp(older.toIso8601String(), now: now),
        'Mar 5, 9:05 AM',
      );
    });

    test('falls back to the wall clock when no reference time is given', () {
      // The production call site passes no `now`; a timestamp of "right now"
      // is today at any hour, so this stays deterministic.
      final result = formatMessageTimestamp(DateTime.now().toIso8601String());
      expect(result, matches(RegExp(r'^\d{1,2}:\d{2} (AM|PM)$')));
    });
  });

  testWidgets(
    'the thread screen shows "PackLox Support" (not "admin_token") for an '
    'admin reply with no real sender label, and a timestamp next to it',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportTicketRepositoryProvider.overrideWithValue(
              _FakeSupportTicketRepository(),
            ),
          ],
          child: const MaterialApp(
            home: SupportTicketThreadScreen(ticketId: 'ticket-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('admin_token'), findsNothing);
      expect(find.text('PackLox Support'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      // A timestamp renders next to both bubbles -- today's message, so a
      // bare "h:mm AM/PM" string (exact clock time isn't asserted, just
      // that something renders where nothing did before).
      expect(find.textContaining(RegExp(r'\d{1,2}:\d{2} (AM|PM)')), findsWidgets);
    },
  );
}

class _FakeSupportTicketRepository extends SupportTicketRepository {
  _FakeSupportTicketRepository()
    : super(
        baseUrl: 'https://example.test',
        supabaseService: SupabaseService.instance(
          config: const SupabaseConfig(url: '', anonKey: '', isEnabled: false),
        ),
      );

  @override
  Future<Map<String, dynamic>> getTicketThread(String ticketId) async {
    final now = DateTime.now();
    return {
      'id': ticketId,
      'subject': 'Test support ticket',
      'status': 'open',
      'messages': [
        {
          'id': 'message-1',
          'senderType': 'user',
          'senderLabel': null,
          'body': 'This is a test support ticket from hariomritesh@gmail.com',
          'createdAt': now.subtract(const Duration(minutes: 5)).toIso8601String(),
          'attachments': const [],
        },
        {
          'id': 'message-2',
          'senderType': 'admin',
          'senderLabel': 'admin_token',
          'body': 'Yeah I got this, thanks',
          'createdAt': now.toIso8601String(),
          'attachments': const [],
        },
      ],
    };
  }
}
