import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/support/data/repositories/support_ticket_repository.dart';
import 'package:collectiq_ai/features/support/presentation/screens/my_support_tickets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'each ticket renders as a distinct card (not a plain flat row) with a '
    '"Updated" date, and an unread ticket is visually highlighted',
    (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportTicketRepositoryProvider.overrideWithValue(
              _FakeSupportTicketRepository([
                {
                  'id': 'ticket-1',
                  'subject': 'Test support ticket',
                  'category': 'bug',
                  'status': 'resolved',
                  'unreadByUser': false,
                  'createdAt': now
                      .subtract(const Duration(days: 3))
                      .toIso8601String(),
                  'updatedAt': now
                      .subtract(const Duration(hours: 2))
                      .toIso8601String(),
                },
                {
                  'id': 'ticket-2',
                  'subject': 'Pricing looks wrong',
                  'category': 'pricing',
                  'status': 'open',
                  'unreadByUser': true,
                  'createdAt': now
                      .subtract(const Duration(days: 1))
                      .toIso8601String(),
                  'updatedAt': now.toIso8601String(),
                },
              ]),
            ),
          ],
          child: const MaterialApp(home: MySupportTicketsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Both rows render inside their own Card -- a real visual card, not
      // a flat ListTile floating on the bare page background.
      expect(find.byType(Card), findsNWidgets(2));

      // Date details: each row shows "Updated <something>" using the
      // ticket's own most-recent-activity timestamp.
      expect(find.textContaining('Updated'), findsNWidgets(2));

      // The unread ticket's card is visually distinct from the read one --
      // different fill color and an actual border, not identical styling.
      final cards = tester.widgetList<Card>(find.byType(Card)).toList();
      final resolvedCard = cards[0];
      final unreadCard = cards[1];
      expect(resolvedCard.color, isNot(equals(unreadCard.color)));
      final unreadShape = unreadCard.shape as RoundedRectangleBorder;
      expect(unreadShape.side, isNot(BorderSide.none));
    },
  );
}

class _FakeSupportTicketRepository extends SupportTicketRepository {
  _FakeSupportTicketRepository(this._tickets)
    : super(
        baseUrl: 'https://example.test',
        supabaseService: SupabaseService.instance(
          config: const SupabaseConfig(url: '', anonKey: '', isEnabled: false),
        ),
      );

  final List<Map<String, dynamic>> _tickets;

  @override
  Future<List<Map<String, dynamic>>> listMyTickets() async => _tickets;
}
