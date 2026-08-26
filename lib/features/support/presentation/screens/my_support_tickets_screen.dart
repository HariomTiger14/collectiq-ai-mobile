import 'dart:async';

import 'package:collectiq_ai/features/support/data/repositories/support_ticket_repository.dart';
import 'package:collectiq_ai/features/support/presentation/screens/new_support_ticket_screen.dart';
import 'package:collectiq_ai/features/support/presentation/screens/support_ticket_thread_screen.dart'
    show SupportTicketThreadScreen, formatMessageTimestamp;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MySupportTicketsScreen extends ConsumerStatefulWidget {
  const MySupportTicketsScreen({super.key});

  @override
  ConsumerState<MySupportTicketsScreen> createState() =>
      _MySupportTicketsScreenState();
}

class _MySupportTicketsScreenState
    extends ConsumerState<MySupportTicketsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref.read(supportTicketRepositoryProvider).listMyTickets();
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => const NewSupportTicketScreen(),
            ),
          );
          if (created == true) {
            unawaited(_refresh());
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New ticket'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.error,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('Could not load your tickets: '
                        '${snapshot.error}'),
                  ),
                ],
              );
            }
            final tickets = snapshot.data ?? const [];
            if (tickets.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.chat_bubble_outline, size: 40),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      "No support tickets yet.\nTap \"New ticket\" to report "
                      'a bug, ask a question, or send feedback.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final status = (ticket['status'] as String?) ?? 'open';
                final unread = ticket['unreadByUser'] == true;
                // "Updated" reflects the most recent activity on the ticket
                // (e.g. a new admin reply) -- more useful to scan than the
                // creation date, which never changes once the ticket is old.
                final date = formatMessageTimestamp(
                  (ticket['updatedAt'] as String?) ??
                      (ticket['createdAt'] as String?),
                );
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  color: unread
                      ? colorScheme.primaryContainer.withValues(alpha: .55)
                      : colorScheme.surfaceContainerHighest,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: unread
                        ? BorderSide(
                            color: colorScheme.primary.withValues(alpha: .4),
                          )
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Icon(
                      status == 'resolved'
                          ? Icons.check_circle_outline
                          : Icons.chat_bubble_outline,
                      color: status == 'resolved'
                          ? Colors.green
                          : colorScheme.primary,
                    ),
                    title: Text(
                      (ticket['subject'] as String?) ?? 'Support ticket',
                      style: TextStyle(
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_categoryLabel(ticket['category'] as String?)),
                        if (date != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Updated $date',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                    trailing: unread
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SupportTicketThreadScreen(
                            ticketId: ticket['id'] as String,
                          ),
                        ),
                      );
                      unawaited(_refresh());
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

String _categoryLabel(String? category) {
  switch (category) {
    case 'bug':
      return 'Bug report';
    case 'pricing':
      return 'Pricing question';
    case 'question':
      return 'Question';
    case 'feedback':
      return 'Feedback';
    default:
      return 'Support';
  }
}
