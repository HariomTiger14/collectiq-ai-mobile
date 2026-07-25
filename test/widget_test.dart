import 'package:collectiq_ai/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_guest_mode_chosen_v1': true,
      'onboarding_completed_v1': true,
    });
  });

  testWidgets('PackLox launches to the Home shell', (tester) async {
    await tester.pumpPackLoxApp();

    expect(find.byKey(const ValueKey('app-shell')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('shell-destination-home')),
      findsOneWidget,
    );
    expect(find.text('Your collection is waiting'), findsOneWidget);
  });

  testWidgets('bottom navigation exposes the current five destinations', (
    tester,
  ) async {
    await tester.pumpPackLoxApp();

    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-scan')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-portfolio')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-settings')), findsOneWidget);
  });

  testWidgets('bottom navigation opens scan portfolio search and settings', (
    tester,
  ) async {
    await tester.pumpPackLoxApp();

    await tester.tap(find.byKey(const ValueKey('nav-scan')));
    await tester.pumpTabSwitch();
    expect(
      find.byKey(const ValueKey('shell-destination-scan')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('scan-hub-capture-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('nav-portfolio')));
    await tester.pumpTabSwitch();
    expect(
      find.byKey(const ValueKey('shell-destination-portfolio')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('nav-search')));
    await tester.pumpTabSwitch();
    expect(
      find.byKey(const ValueKey('shell-destination-search')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('nav-settings')));
    await tester.pumpTabSwitch();
    expect(
      find.byKey(const ValueKey('shell-destination-settings')),
      findsOneWidget,
    );
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Price Alerts'), findsOneWidget);
  });

  testWidgets('home primary scan action opens the scan hub', (tester) async {
    await tester.pumpPackLoxApp();

    await tester.ensureVisible(find.byKey(const ValueKey('home-primary-scan')));
    await tester.tap(find.byKey(const ValueKey('home-primary-scan')));
    await tester.pumpTabSwitch();

    expect(
      find.byKey(const ValueKey('shell-destination-scan')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('scan-hub-capture-button')),
      findsOneWidget,
    );
  });
}

extension on WidgetTester {
  Future<void> pumpPackLoxApp() async {
    await pumpWidget(const ProviderScope(child: CollectIqApp()));
    await pump();
    await pump(const Duration(milliseconds: 120));
  }

  Future<void> pumpTabSwitch() async {
    await pump();
    await pump(const Duration(milliseconds: 240));
  }
}
