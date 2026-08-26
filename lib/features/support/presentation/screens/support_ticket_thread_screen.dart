import 'dart:io';

import 'package:collectiq_ai/features/support/data/repositories/support_ticket_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportTicketThreadScreen extends ConsumerStatefulWidget {
  const SupportTicketThreadScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  ConsumerState<SupportTicketThreadScreen> createState() =>
      _SupportTicketThreadScreenState();
}

class _SupportTicketThreadScreenState
    extends ConsumerState<SupportTicketThreadScreen> {
  Map<String, dynamic>? _ticket;
  String? _loadError;
  bool _isLoading = true;
  bool _isSending = false;
  File? _pendingAttachment;
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final ticket = await ref
          .read(supportTicketRepositoryProvider)
          .getTicketThread(widget.ticketId);
      if (!mounted) {
        return;
      }
      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = '$error';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAttachment() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (image == null) {
      return;
    }
    setState(() => _pendingAttachment = File(image.path));
  }

  Future<void> _send() async {
    final body = _replyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Write a message first.')));
      return;
    }
    setState(() => _isSending = true);
    try {
      final repository = ref.read(supportTicketRepositoryProvider);
      final result = await repository.reply(
        ticketId: widget.ticketId,
        body: body,
      );
      final messageId = result['lastMessageId'] as String?;
      if (_pendingAttachment != null && messageId != null) {
        await repository.uploadAttachment(
          messageId: messageId,
          file: _pendingAttachment!,
        );
      }
      _replyController.clear();
      setState(() => _pendingAttachment = null);
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send reply: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text((_ticket?['subject'] as String?) ?? 'Ticket'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(child: Text('Could not load ticket: $_loadError'))
            : Column(
                children: [
                  Expanded(child: _buildMessages(context)),
                  _buildComposer(context),
                ],
              ),
      ),
    );
  }

  Widget _buildMessages(BuildContext context) {
    final messages =
        (_ticket?['messages'] as List?)?.whereType<Map<String, dynamic>>() ??
        const [];
    if (messages.isEmpty) {
      return const Center(child: Text('No messages yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages.elementAt(index);
        final isAdmin = message['senderType'] == 'admin';
        return Align(
          alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: isAdmin
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAdmin
                          ? adminDisplayName(
                              message['senderLabel'] as String?,
                            )
                          : 'You',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Builder(
                      builder: (context) {
                        final timestamp = formatMessageTimestamp(
                          message['createdAt'] as String?,
                        );
                        if (timestamp == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            timestamp,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text((message['body'] as String?) ?? ''),
                for (final attachment
                    in (message['attachments'] as List?)
                            ?.whereType<Map<String, dynamic>>() ??
                        const <Map<String, dynamic>>[])
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: InkWell(
                      onTap: () {
                        final url = attachment['url'] as String?;
                        if (url != null) {
                          launchUrl(Uri.parse(url));
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              (attachment['fileName'] as String?) ?? 'file',
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer(BuildContext context) {
    final status = _ticket?['status'] as String?;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status == 'resolved')
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'This ticket is resolved — sending a reply reopens it.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          if (_pendingAttachment != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.image_outlined, size: 16),
                  const SizedBox(width: 6),
                  const Expanded(child: Text('1 image attached')),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _pendingAttachment = null),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _isSending ? null : _pickAttachment,
              ),
              Expanded(
                child: TextField(
                  controller: _replyController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Write a reply…',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: _isSending ? null : _send,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The backend's admin-reply endpoint authenticates with a single shared
/// admin token, not a per-person login, so it has no real identity to
/// attribute a reply to -- it stores the literal internal placeholder
/// "admin_token" as the sender label. Real bug found live: that internal
/// string leaked straight into the chat UI as if it were the replier's
/// name. Treat it (and a missing label) the same way: show the brand name
/// instead of either a null field or an implementation detail.
String adminDisplayName(String? senderLabel) {
  final label = senderLabel?.trim() ?? '';
  if (label.isEmpty || label == 'admin_token') {
    return 'PackLox Support';
  }
  return label;
}

const _monthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// Formats a message's ISO-8601 `createdAt` for display: just the time for
/// a message from today, "Yesterday" + time for yesterday, otherwise the
/// date and time -- no external `intl` dependency needed.
String? formatMessageTimestamp(String? iso) {
  if (iso == null || iso.isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) {
    return null;
  }
  final local = parsed.toLocal();
  final now = DateTime.now();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final period = local.hour < 12 ? 'AM' : 'PM';
  final time = '$hour12:${_twoDigits(local.minute)} $period';

  final isSameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (isSameDay) {
    return time;
  }

  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday =
      local.year == yesterday.year &&
      local.month == yesterday.month &&
      local.day == yesterday.day;
  if (isYesterday) {
    return 'Yesterday, $time';
  }

  return '${_monthAbbreviations[local.month - 1]} ${local.day}, $time';
}
