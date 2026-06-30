import 'package:collectiq_ai/features/ai/services/ai_providers.dart';
import 'package:collectiq_ai/features/diagnostics/domain/entities/provider_diagnostics.dart';
import 'package:collectiq_ai/features/diagnostics/domain/services/provider_diagnostics_service.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Developer-facing scan pipeline status labels.
class ScanPipelineDiagnostics {
  const ScanPipelineDiagnostics._();

  /// Initial state before a scan has completed.
  static const ready = 'Ready';

  /// Successful mock/local pipeline completion.
  static const completed = 'AI -> Pricing -> Result';

  /// Provider or enrichment failure.
  static const error = 'Error';
}

/// Stores the latest scan pipeline status for Settings diagnostics.
final scanPipelineStatusProvider =
    NotifierProvider<ScanPipelineStatusController, String>(
      ScanPipelineStatusController.new,
    );

/// Mutable diagnostics state for the latest scan pipeline.
class ScanPipelineStatusController extends Notifier<String> {
  @override
  String build() {
    return ScanPipelineDiagnostics.ready;
  }

  /// Marks the pipeline ready for a fresh scan.
  void markReady() {
    state = ScanPipelineDiagnostics.ready;
  }

  /// Marks the pipeline completed.
  void markCompleted() {
    state = ScanPipelineDiagnostics.completed;
  }

  /// Marks the pipeline errored.
  void markError() {
    state = ScanPipelineDiagnostics.error;
  }
}

/// Provides the diagnostics service.
final providerDiagnosticsServiceProvider = Provider<ProviderDiagnosticsService>(
  (ref) {
    return const ProviderDiagnosticsService();
  },
);

/// Provides the current diagnostics snapshot.
final providerDiagnosticsProvider = Provider<ProviderDiagnostics>((ref) {
  return ref
      .watch(providerDiagnosticsServiceProvider)
      .build(
        aiConfig: ref.watch(aiAnalysisProviderConfigProvider),
        pricingProviderType: ref.watch(marketPricingProviderTypeProvider),
        lastScanPipelineStatus: ref.watch(scanPipelineStatusProvider),
      );
});
