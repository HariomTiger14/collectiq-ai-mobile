import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/capture_role_guide.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/scan_goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scanner goal and role guide widgets render', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ScanGoalCard(
                goal: ScanGoal.identifyValue,
                selected: true,
                onTap: () => tapped = true,
              ),
              const CaptureRoleGuide(role: ScanCaptureRole.angledReflective),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Identify & Value'), findsOneWidget);
    expect(find.text('Fast ID and valuation'), findsOneWidget);
    expect(find.textContaining('Tilt slightly'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('scan-goal-identifyValue')));
    expect(tapped, isTrue);
  });
}
