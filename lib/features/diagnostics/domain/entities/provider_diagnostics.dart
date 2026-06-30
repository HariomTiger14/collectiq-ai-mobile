/// Snapshot of provider and scan-pipeline diagnostics for developer testing.
class ProviderDiagnostics {
  const ProviderDiagnostics({
    required this.aiProvider,
    required this.aiProviderStatus,
    required this.pricingProvider,
    required this.pricingProviderStatus,
    required this.backendEndpointConfigured,
    required this.backendEndpointValid,
    required this.backendEndpointReleaseSafe,
    required this.backendEndpointMessage,
    required this.aiBackendClientStatus,
    required this.httpBackendClientStatus,
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

  /// Whether the future backend AI endpoint URL is valid.
  final String backendEndpointValid;

  /// Whether the future backend AI endpoint is safe for release builds.
  final String backendEndpointReleaseSafe;

  /// Developer-safe backend endpoint message.
  final String backendEndpointMessage;

  /// Safe status label for the backend AI client skeleton.
  final String aiBackendClientStatus;

  /// Safe status label for the Dio-backed HTTP backend client.
  final String httpBackendClientStatus;

  /// Whether local mock mode is currently active.
  final String mockModeActive;

  /// Last known high-level scan pipeline state.
  final String lastScanPipelineStatus;

  /// Current app mode label for developer diagnostics.
  final String appMode;
}
