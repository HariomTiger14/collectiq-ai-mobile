import 'package:collectiq_ai/features/subscription/domain/entities/plan_limits.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/features/subscription/presentation/widgets/upgrade_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'collectionFull headline reads the real cap, not a hardcoded number '
    '(real bug: the copy hardcoded "10 free collectibles" regardless of '
    'kFreeMaxCollectibles/PlanLimits.maxPortfolioItems, so tuning the cap '
    'via its dart-define would have silently left the paywall showing a '
    'stale number)',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activePlanLimitsProvider.overrideWithValue(
              PlanLimits(
                plan: SubscriptionPlan.free,
                scanLimit: const UsageLimit(monthlyFreeScanLimit: 10),
                maxPortfolioItems: 15,
                maxPhotosPerItem: 2,
                maxActivePriceAlerts: 1,
                monthlyPriceRefreshes: 10,
                canUseFullValueHistory: false,
                canExportPortfolio: false,
                canUseAdvancedFilters: false,
                canBulkRefreshValues: false,
                canUsePortfolioIntelligence: false,
              ),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => showUpgradeSheet(
                    context,
                    reason: PaywallReason.collectionFull,
                  ),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text("You've reached your 15 free collectibles"),
        findsOneWidget,
      );
      expect(
        find.text("You've reached your 10 free collectibles"),
        findsNothing,
      );
    },
  );
}
