/// Snapshot of provider and scan-pipeline diagnostics for developer testing.
class ProviderDiagnostics {
  const ProviderDiagnostics({
    required this.aiProvider,
    required this.aiProviderStatus,
    required this.pricingProvider,
    required this.pricingProviderStatus,
    required this.backendEndpointConfigured,
    required this.aiBackendClientStatus,
    required this.mockModeActive,
    required this.lastScanPipelineStatus,
    required this.appMode,
  });

  /// Human-readable active AI provider name.
  final String aiProvider;

  /// Safe status label for the active AI provider.
  final String aiProviderStatus;

  /// Human-readable active pricing provider name.
  final String pricingProvider;

  /// Safe status label for the active pricing provider.
  final String pricingProviderStatus;

  /// Whether the future backend AI endpoint is configured.
  final String backendEndpointConfigured;

  /// Safe status label for the backend AI client skeleton.
  final String aiBackendClientStatus;

  /// Whether local mock mode is currently active.
  final String mockModeActive;

  /// Last known high-level scan pipeline state.
  final String lastScanPipelineStatus;

  /// Current app mode label for developer diagnostics.
  final String appMode;
}
