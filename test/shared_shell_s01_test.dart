import 'dart:ui' as ui;

import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const items = <NavBarItem>[
    NavBarItem(icon: Icons.home, label: 'Home', isActive: false),
    NavBarItem(icon: Icons.inventory_2, label: 'Portfolio', isActive: false),
    NavBarItem(icon: Icons.camera_alt, label: 'Scan', isActive: false),
    NavBarItem(icon: Icons.settings, label: 'Settings', isActive: false),
  ];

  testWidgets('dark navigation owns and paints its bottom SafeArea', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          bottomNavigationBar: GlassBottomNavBar(
            currentIndex: 2,
            onTap: (_) {},
            items: items,
          ),
        ),
      ),
    );

    final safeArea = tester.widget<SafeArea>(
      find.byKey(const ValueKey('bottom-navigation-safe-area-surface')),
    );
    expect(safeArea.top, isFalse);
    expect(safeArea.minimum.bottom, 12);
  });

  testWidgets('Scan selected semantics and navigation taps are preserved', (
    tester,
  ) async {
    var selected = 2;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          bottomNavigationBar: GlassBottomNavBar(
            currentIndex: selected,
            onTap: (value) => selected = value,
            items: items,
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.bySemanticsLabel('Scan'));
    expect(semantics.flagsCollection.isSelected, ui.Tristate.isTrue);
    await tester.tap(find.bySemanticsLabel('Home'));
    expect(selected, 0);
  });
}
