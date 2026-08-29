import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/features/home/presentation/pages/home_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/portfolio_screen.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/scan_hub_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tablet (iPad Air 11-inch portrait) layout coverage: the shell tabs must
/// keep their content centered at a readable width instead of stretching
/// edge to edge, and must lay out without overflow at tablet dimensions.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tabletSize = Size(820, 1180);

  void useTabletViewport(WidgetTester tester) {
    tester.view.physicalSize = tabletSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: child,
      ),
    );
  }

  testWidgets('home renders at tablet width without overflow', (tester) async {
    useTabletViewport(tester);
    await tester.pumpWidget(
      wrap(const HomePage(previewScenario: HomePreviewScenario.defaultData)),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey('home-title')), findsOneWidget);
  });

  testWidgets('portfolio renders at tablet width without overflow', (
    tester,
  ) async {
    useTabletViewport(tester);
    await tester.pumpWidget(
      wrap(
        const PortfolioScreen(
          previewScenario: PortfolioPreviewScenario.defaultData,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(
      find.byKey(const ValueKey('portfolio-screen-scaffold')),
      findsOneWidget,
    );
  });

  testWidgets('scan hub tiles stay readable at tablet width', (tester) async {
    useTabletViewport(tester);
    const cameraKey = ValueKey('tablet-test-camera-tile');
    await tester.pumpWidget(
      wrap(
        const ScannerPageScaffold(
          cameraTile: SizedBox(key: cameraKey, height: 72),
          galleryTile: SizedBox(height: 72),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    final tile = find.byKey(cameraKey);
    expect(tile, findsOneWidget);
    expect(tester.getSize(tile).width, lessThanOrEqualTo(600));
    expect(tester.getCenter(tile).dx, moreOrLessEquals(tabletSize.width / 2));
  });

  testWidgets('bottom navigation pill stays phone-sized on tablets', (
    tester,
  ) async {
    useTabletViewport(tester);
    await tester.pumpWidget(
      wrap(
        Scaffold(
          bottomNavigationBar: GlassBottomNavBar(
            currentIndex: 0,
            onTap: (_) {},
            items: const [
              NavBarItem(
                icon: Icons.home_outlined,
                label: 'Home',
                isActive: true,
              ),
              NavBarItem(
                icon: Icons.camera_alt_outlined,
                label: 'Scan',
                isActive: false,
              ),
              NavBarItem(
                icon: Icons.inventory_2_outlined,
                label: 'Portfolio',
                isActive: false,
              ),
              NavBarItem(
                icon: Icons.search_outlined,
                label: 'Search',
                isActive: false,
              ),
              NavBarItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                isActive: false,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final pill = find.descendant(
      of: find.byKey(const ValueKey('bottom-navigation-safe-area-surface')),
      matching: find.byType(ClipRRect),
    );
    expect(pill, findsOneWidget);
    expect(tester.getSize(pill).width, lessThanOrEqualTo(560));
    expect(tester.getCenter(pill).dx, moreOrLessEquals(tabletSize.width / 2));
  });
}
