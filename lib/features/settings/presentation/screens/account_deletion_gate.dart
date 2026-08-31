import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/settings/data/repositories/data_request_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The date a signed-in user's account is due to be erased, or null when no
/// deletion is pending.
///
/// Watches [authControllerProvider] rather than reading it once, so signing in
/// re-runs the check. That is the whole cancellation path: a user who
/// scheduled deletion signs back in, this refires, and the gate offers them
/// the cancel button.
final pendingAccountDeletionProvider = FutureProvider.autoDispose<DateTime?>((
  ref,
) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isSignedIn) {
    return null;
  }
  try {
    return await ref.read(dataRequestRepositoryProvider).pendingDeletionDate();
  } on StateError {
    // No usable session (signed out between the watch and the call, or
    // anonymous). Nothing to gate on.
    return null;
  }
});

/// Shows [child] normally, or a cancel-or-leave screen when the signed-in
/// account is scheduled for deletion.
///
/// Fails OPEN: while the status check is loading, and if it errors, the app
/// renders as usual. Blocking the entire app behind a backend call that might
/// be down would be a far worse failure than briefly letting someone use an
/// account that is scheduled for deletion -- and it would not preserve any
/// data either way, since the purge cron is what actually deletes and it runs
/// server-side regardless of what the app manages to display.
class AccountDeletionGate extends ConsumerWidget {
  const AccountDeletionGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingAccountDeletionProvider);
    return pending.maybeWhen(
      data: (scheduledFor) => scheduledFor == null
          ? child
          : _DeletionScheduledScreen(scheduledFor: scheduledFor),
      orElse: () => child,
    );
  }
}

class _DeletionScheduledScreen extends ConsumerStatefulWidget {
  const _DeletionScheduledScreen({required this.scheduledFor});

  final DateTime scheduledFor;

  @override
  ConsumerState<_DeletionScheduledScreen> createState() =>
      _DeletionScheduledScreenState();
}

class _DeletionScheduledScreenState
    extends ConsumerState<_DeletionScheduledScreen> {
  bool _busy = false;

  Future<void> _cancelDeletion() async {
    setState(() => _busy = true);
    try {
      await ref.read(dataRequestRepositoryProvider).cancelDeletion();
      // Re-runs the status check, which now reports nothing scheduled and
      // drops the gate, restoring the app exactly as it was.
      ref.invalidate(pendingAccountDeletionProvider);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel the deletion: $error')),
      );
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.delete_forever_outlined,
                  size: 56,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 20),
                Text(
                  'Your account is scheduled for deletion',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your account and everything in it will be permanently '
                  'deleted on ${formatDeletionDate(widget.scheduledFor)}.\n\n'
                  'Nothing has been deleted yet. Cancel now and your '
                  'portfolio, images and alerts are restored exactly as you '
                  'left them.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _busy ? null : _cancelDeletion,
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cancel deletion'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : _signOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "1 October 2026". Hand-rolled because the project has no intl dependency,
/// and a deletion date is the one string here that must never render as an
/// ISO timestamp.
String formatDeletionDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day} ${_monthNames[local.month - 1]} ${local.year}';
}
