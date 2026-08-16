import 'package:collectiq_ai/features/support/data/repositories/support_ticket_repository.dart';
import 'package:collectiq_ai/features/support/presentation/screens/support_ticket_thread_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewSupportTicketScreen extends ConsumerStatefulWidget {
  const NewSupportTicketScreen({super.key});

  @override
  ConsumerState<NewSupportTicketScreen> createState() =>
      _NewSupportTicketScreenState();
}

class _NewSupportTicketScreenState
    extends ConsumerState<NewSupportTicketScreen> {
  static const _categories = {
    'bug': 'Bug',
    'pricing': 'Pricing',
    'question': 'Question',
    'feedback': 'Feedback',
  };

  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _category = 'bug';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject and message are both required.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final ticket = await ref
          .read(supportTicketRepositoryProvider)
          .createTicket(
            category: _category,
            subject: subject,
            message: message,
          );
      if (!mounted) {
        return;
      }
      final ticketId = ticket['id'] as String?;
      if (ticketId != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => SupportTicketThreadScreen(ticketId: ticketId),
          ),
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit ticket: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New ticket')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories.entries
                    .map(
                      (entry) => ChoiceChip(
                        label: Text(entry.value),
                        selected: _category == entry.key,
                        onSelected: (_) =>
                            setState(() => _category = entry.key),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit ticket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
