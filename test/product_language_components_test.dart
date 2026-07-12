import 'package:collectiq_ai/core/ui/product_language/packlox_button.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_entry_tile.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_header.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child, {double width = 390, double scale = 1}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );

  group('PackLoxHeader 1.0.1', () {
    for (final fixture in [
      (6, 'Good morning'),
      (13, 'Good afternoon'),
      (20, 'Good evening'),
    ]) {
      testWidgets('uses ${fixture.$2}', (tester) async {
        await tester.pumpWidget(
          app(
            PackLoxHeader(
              firstName: '',
              now: () => DateTime(2026, 7, 12, fixture.$1),
              onNotifications: () {},
            ),
          ),
        );
        expect(find.text(fixture.$2), findsOneWidget);
        expect(find.text('Collector'), findsOneWidget);
      });
    }
    testWidgets('supports long name, large text, unread badge and callback', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        app(
          PackLoxHeader(
            firstName: 'Alexandria-Cassandra',
            greetingText: 'Good morning',
            notificationUnreadCount: 3,
            onNotifications: () => taps++,
          ),
          width: 360,
          scale: 1.5,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('3'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('scan-hub-notifications-button')),
      );
      expect(taps, 1);
    });
  });

  testWidgets('scanner Hero wraps and exposes both actions', (tester) async {
    var primary = 0;
    var secondary = 0;
    await tester.pumpWidget(
      app(
        PackLoxHero(
          variant: PackLoxHeroVariant.scanner,
          eyebrow: 'PackLox Scanner',
          title: 'Ready when your exceptionally valuable item is.',
          subtitle:
              'Position one item in clear light. PackLox will guide the rest.',
          primaryActionLabel: 'Start scanning',
          onPrimaryAction: () => primary++,
          secondaryActionLabel: 'Enter details',
          onSecondaryAction: () => secondary++,
        ),
        width: 360,
        scale: 1.5,
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Start scanning'));
    await tester.tap(find.text('Enter details'));
    expect((primary, secondary), (1, 1));
  });

  testWidgets('scanner Hero micro-polish preserves typography and alignment', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const PackLoxHero(
          variant: PackLoxHeroVariant.scanner,
          eyebrow: 'PackLox Scanner',
          title: 'Ready when your item is.',
          subtitle:
              'Position one item in clear light. PackLox will guide the rest.',
          icon: Icons.center_focus_strong_outlined,
        ),
      ),
    );

    final hero = tester.widget<Container>(
      find.byKey(const ValueKey('scan-hub-hero-card')),
    );
    expect(hero.padding, const EdgeInsets.all(20));
    expect(
      tester.getSize(find.byKey(const ValueKey('packlox-hero-icon-container'))),
      const Size.square(42),
    );
    expect(
      tester
          .widget<Text>(find.text('Ready when your item is.'))
          .style
          ?.fontSize,
      30,
    );
    expect(
      tester
          .widget<Text>(
            find.text(
              'Position one item in clear light. PackLox will guide the rest.',
            ),
          )
          .style
          ?.fontSize,
      14,
    );
  });

  testWidgets('notification polish preserves touch target and semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        PackLoxHeader(
          firstName: 'Collector',
          notificationUnreadCount: 3,
          onNotifications: () {},
        ),
      ),
    );
    final button = find.byKey(const ValueKey('scan-hub-notifications-button'));
    expect(tester.getSize(button), const Size.square(48));
    expect(find.bySemanticsLabel('Notifications, 3 unread'), findsOneWidget);
    final iconButton = tester.widget<IconButton>(button);
    final side = iconButton.style?.side?.resolve(<WidgetState>{});
    expect(side?.color.a, closeTo(.95, .001));
    expect(side?.width, 1);
    semantics.dispose();
  });

  testWidgets('Entry Tile states preserve geometry and suppress activation', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      app(
        Column(
          children: PackLoxEntryTileState.values
              .map(
                (state) => PackLoxEntryTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Take a photo',
                  supportingText: 'Use your camera to scan an item',
                  state: state,
                  badge: 'NEW',
                  value: 'Ready',
                  onTap: () => taps++,
                ),
              )
              .toList(),
        ),
        width: 360,
        scale: 1.5,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      find.text('Take a photo'),
      findsNWidgets(PackLoxEntryTileState.values.length),
    );
    await tester.tap(find.text('Take a photo').first);
    expect(taps, 1);
  });

  testWidgets('Button variants, sizes, loading and disabled are controlled', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      app(
        Column(
          children: [
            for (final variant in PackLoxButtonVariant.values)
              PackLoxButton(
                label: variant.name,
                variant: variant,
                onPressed: () => taps++,
              ),
            const PackLoxButton(
              label: 'Loading',
              loading: true,
              onPressed: null,
            ),
            const PackLoxButton(label: 'Disabled', onPressed: null),
            PackLoxButton(
              label: 'Icon label',
              leadingIcon: Icons.camera_alt_outlined,
              size: PackLoxButtonSize.fullWidth,
              onPressed: () => taps++,
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(PackLoxButtonVariant.primary.name));
    expect(taps, 1);
  });
}
