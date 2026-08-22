import 'dart:ui';

import 'package:collectiq_ai/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('SIT_TEST_EMAIL');
  const password = String.fromEnvironment('SIT_TEST_PASSWORD');

  testWidgets('SIT catalog add and portfolio reprice smoke test', (
    tester,
  ) async {
    expect(
      email,
      isNotEmpty,
      reason: 'Provide SIT_TEST_EMAIL as a local dart-define.',
    );
    expect(
      password,
      isNotEmpty,
      reason: 'Provide SIT_TEST_PASSWORD as a local dart-define.',
    );

    final originalFlutterOnError = FlutterError.onError;
    final originalPlatformOnError = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = originalFlutterOnError;
      PlatformDispatcher.instance.onError = originalPlatformOnError;
    });

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    FlutterError.onError = originalFlutterOnError;
    PlatformDispatcher.instance.onError = originalPlatformOnError;

    await _signInIfNeeded(tester, email: email, password: password);
    await _completeOnboardingIfNeeded(tester);
    await _waitFor(tester, find.byKey(const ValueKey('app-shell')));

    await tester.tap(find.byKey(const ValueKey('nav-search')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      'Charizard',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _waitFor(tester, find.text('Catalog matches'));

    final firstCatalogResult = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'discover-catalog-result-',
          ),
      description: 'first catalog result card',
    );
    await _waitFor(tester, firstCatalogResult);
    await tester.tap(firstCatalogResult.first);
    await _waitFor(
      tester,
      find.byKey(const ValueKey('catalog-result-detail-screen')),
    );

    await _ensureVisible(
      tester,
      find.byKey(const ValueKey('catalog-detail-add-to-portfolio')),
    );
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -160),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('catalog-detail-add-to-portfolio')),
    );
    await _waitForDetailOrSaveFailure(tester);

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('collectible-detail-refresh-value-action')),
    );
    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-refresh-value-action')),
    );
    await _waitForAny(tester, [
      find.text('Portfolio value refreshed'),
      find.text('Value unavailable from trusted sources'),
      find.text('Unable to refresh value'),
    ]);

    expect(
      find.byKey(const ValueKey('collectible-detail-packlox-surface')),
      findsOneWidget,
    );
  });
}

Future<void> _completeOnboardingIfNeeded(WidgetTester tester) async {
  for (var attempt = 0; attempt < 80; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.byKey(const ValueKey('app-shell')).evaluate().isNotEmpty) {
      return;
    }
    if (find.byKey(const ValueKey('onboarding-screen')).evaluate().isNotEmpty) {
      break;
    }
  }

  if (find.byKey(const ValueKey('onboarding-screen')).evaluate().isEmpty) {
    return;
  }

  await tester.pumpAndSettle();
  for (var step = 0; step < 3; step += 1) {
    await _ensureVisible(tester, find.byKey(const ValueKey('onboarding-next')));
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
  }

  await _ensureVisible(
    tester,
    find.byKey(const ValueKey('onboarding-explore-dashboard')),
  );
  await tester.tap(find.byKey(const ValueKey('onboarding-explore-dashboard')));
}

Future<void> _signInIfNeeded(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  if (find.byKey(const ValueKey('app-shell')).evaluate().isNotEmpty) {
    return;
  }

  await _waitFor(tester, find.byKey(const ValueKey('auth-welcome-screen')));
  await tester.tap(find.byKey(const ValueKey('auth-welcome-sign-in')));
  await _waitFor(tester, find.byKey(const ValueKey('auth-sign-in-screen')));
  await tester.enterText(
    find.byKey(const ValueKey('auth-sign-in-email-field')),
    email,
  );
  await tester.enterText(
    find.byKey(const ValueKey('auth-sign-in-password-field')),
    password,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('auth-sign-in-submit')));
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 240; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  expect(finder, findsWidgets);
}

Future<void> _waitForAny(WidgetTester tester, List<Finder> finders) async {
  for (var attempt = 0; attempt < 240; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finders.any((finder) => finder.evaluate().isNotEmpty)) {
      return;
    }
  }
  fail('None of the expected states appeared.');
}

Future<void> _waitForDetailOrSaveFailure(WidgetTester tester) async {
  final detail = find.byKey(
    const ValueKey('collectible-detail-packlox-surface'),
  );
  final saveFailure = find.text('Unable to save catalog item');

  for (var attempt = 0; attempt < 240; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 250));
    if (detail.evaluate().isNotEmpty) {
      return;
    }
    if (saveFailure.evaluate().isNotEmpty) {
      fail('Catalog item save failed before opening portfolio detail.');
    }
  }

  expect(detail, findsWidgets);
}

Future<void> _ensureVisible(WidgetTester tester, Finder finder) async {
  await _waitFor(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _scrollUntilVisible(
  WidgetTester tester,
  Finder finder,
) async {
  final surface = find.byKey(
    const ValueKey('collectible-detail-packlox-surface'),
  );
  for (var attempt = 0; attempt < 20; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder.first);
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(surface, const Offset(0, -300), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  expect(finder, findsWidgets);
}
