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
                Text(
                  isAdmin
                      ? ((message['senderLabel'] as String?) ??
                            'PackLox Support')
                      : 'You',
                  style: Theme.of(context).textTheme.labelSmall,
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
