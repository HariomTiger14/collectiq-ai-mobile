import 'package:collectiq_ai/features/subscription/presentation/widgets/free_collectible_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FreeCollectibleCounter', () {
    testWidgets('below cap shows remaining count, not a lock', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          FreeCollectibleCounter(
            savedCount: 9,
            cap: 10,
            onUpgrade: () {},
          ),
        ),
      );

      expect(find.text('9 of 10 free collectibles saved'), findsOneWidget);
      expect(find.text('Free collection full — upgrade to save more'), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('at cap shows the full/upgrade message and a lock icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          FreeCollectibleCounter(
            savedCount: 10,
            cap: 10,
            onUpgrade: () {},
          ),
        ),
      );

      expect(
        find.text('Free collection full — upgrade to save more'),
        findsOneWidget,
      );
      expect(find.text('9 of 10 free collectibles saved'), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);
    });

    testWidgets('tapping the counter invokes onUpgrade', (tester) async {
      var upgradeTapped = false;
      await tester.pumpWidget(
        _harness(
          FreeCollectibleCounter(
            savedCount: 5,
            cap: 10,
            onUpgrade: () => upgradeTapped = true,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('free-collectible-counter')));
      await tester.pump();

      expect(upgradeTapped, isTrue);
    });

    testWidgets('compact mode renders the same copy in a quieter row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          FreeCollectibleCounter(
            savedCount: 3,
            cap: 10,
            compact: true,
            onUpgrade: () {},
          ),
        ),
      );

      expect(find.text('3 of 10 free collectibles saved'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('free-collectible-counter-compact')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('free-collectible-counter')), findsNothing);
    });

    testWidgets('compact mode at cap invokes onUpgrade on tap', (
      tester,
    ) async {
      var upgradeTapped = false;
      await tester.pumpWidget(
        _harness(
          FreeCollectibleCounter(
            savedCount: 10,
            cap: 10,
            compact: true,
            onUpgrade: () => upgradeTapped = true,
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('free-collectible-counter-compact')),
      );
      await tester.pump();

      expect(upgradeTapped, isTrue);
    });
  });
}

Widget _harness(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}
