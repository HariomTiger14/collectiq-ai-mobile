import 'package:collectiq_ai/features/settings/data/repositories/data_request_repository.dart';
import 'package:collectiq_ai/features/settings/presentation/screens/account_deletion_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDataRequestRepository implements DataRequestRepository {
  _FakeDataRequestRepository({this.pending, this.throwOnStatus = false});

  DateTime? pending;
  bool throwOnStatus;
  int cancelCalls = 0;

  @override
  Future<DateTime?> pendingDeletionDate() async {
    if (throwOnStatus) {
      throw StateError('backend unavailable');
    }
    return pending;
  }

  @override
  Future<void> cancelDeletion() async {
    cancelCalls += 1;
    pending = null;
  }

  @override
  Future<DateTime?> scheduleDeletion() async {
    pending = DateTime(2026, 10, 1);
    return pending;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _harness(_FakeDataRequestRepository repository, {DateTime? pending}) {
  return ProviderScope(
    overrides: [
      dataRequestRepositoryProvider.overrideWithValue(repository),
      // The gate's own provider is overridden so these tests exercise the
      // gate's rendering decisions without standing up auth.
      pendingAccountDeletionProvider.overrideWith((ref) async => pending),
    ],
    child: const MaterialApp(
      home: AccountDeletionGate(child: Text('app-content')),
    ),
  );
}

void main() {
  group('formatDeletionDate', () {
    test('renders a human date, never an ISO timestamp', () {
      expect(formatDeletionDate(DateTime(2026, 10, 1)), '1 October 2026');
      expect(formatDeletionDate(DateTime(2026, 1, 31)), '31 January 2026');
      expect(formatDeletionDate(DateTime(2026, 12, 9)), '9 December 2026');
    });
  });

  group('AccountDeletionGate', () {
    testWidgets('shows the app when no deletion is pending', (tester) async {
      await tester.pumpWidget(_harness(_FakeDataRequestRepository()));
      await tester.pumpAndSettle();

      expect(find.text('app-content'), findsOneWidget);
      expect(find.text('Cancel deletion'), findsNothing);
    });

    testWidgets('blocks the app and shows the date when one is pending', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(_FakeDataRequestRepository(), pending: DateTime(2026, 10, 1)),
      );
      await tester.pumpAndSettle();

      expect(find.text('app-content'), findsNothing);
      expect(
        find.textContaining('permanently deleted on 1 October 2026'),
        findsOneWidget,
      );
      expect(find.text('Cancel deletion'), findsOneWidget);
    });

    testWidgets('cancelling restores the app', (tester) async {
      final repository = _FakeDataRequestRepository(
        pending: DateTime(2026, 10, 1),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dataRequestRepositoryProvider.overrideWithValue(repository),
            pendingAccountDeletionProvider.overrideWith(
              (ref) async => repository.pendingDeletionDate(),
            ),
          ],
          child: const MaterialApp(
            home: AccountDeletionGate(child: Text('app-content')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cancel deletion'), findsOneWidget);

      await tester.tap(find.text('Cancel deletion'));
      await tester.pumpAndSettle();

      expect(repository.cancelCalls, 1);
      expect(find.text('app-content'), findsOneWidget);
    });

    testWidgets('fails open: a status error still renders the app', (
      tester,
    ) async {
      // Blocking the whole app behind a backend call that might be down is a
      // worse failure than briefly letting a scheduled account in -- the purge
      // cron deletes server-side regardless of what the app shows.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dataRequestRepositoryProvider.overrideWithValue(
              _FakeDataRequestRepository(throwOnStatus: true),
            ),
            pendingAccountDeletionProvider.overrideWith(
              (ref) async => throw StateError('backend unavailable'),
            ),
          ],
          child: const MaterialApp(
            home: AccountDeletionGate(child: Text('app-content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('app-content'), findsOneWidget);
    });

    testWidgets('fails open while the check is still loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dataRequestRepositoryProvider.overrideWithValue(
              _FakeDataRequestRepository(),
            ),
            pendingAccountDeletionProvider.overrideWith((ref) async {
              await Future<void>.delayed(const Duration(seconds: 1));
              return null;
            }),
          ],
          child: const MaterialApp(
            home: AccountDeletionGate(child: Text('app-content')),
          ),
        ),
      );
      // Deliberately not settled: this is the first frame.
      await tester.pump();

      expect(find.text('app-content'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });
  });
}
