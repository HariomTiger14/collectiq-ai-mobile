import 'package:collectiq_ai/features/ai/data/models/ai_backend_contract_validation.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/features/diagnostics/domain/entities/provider_diagnostics.dart';
import 'package:collectiq_ai/features/market/data/providers/market_pricing_provider_factory.dart';

/// Builds developer-safe diagnostics from provider configuration.
class ProviderDiagnosticsService {
  /// Creates a provider diagnostics service.
  const ProviderDiagnosticsService();

  /// Creates the current diagnostics snapshot.
  ProviderDiagnostics build({
    required AiAnalysisProviderConfig aiConfig,
    required MarketPricingProviderType pricingProviderType,
    required String lastScanPipelineStatus,
    bool isReleaseMode = false,
  }) {
    final endpointReadiness = const AiBackendEndpointReadinessChecker().check(
      endpointUrl: aiConfig.backendAnalysisEndpointUrl,
      isReleaseMode: isReleaseMode,
    );
    final mockModeActive =
        aiConfig.type == AiAnalysisProviderType.mock &&
        pricingProviderType == MarketPricingProviderType.mock;

    return ProviderDiagnostics(
      aiProvider: aiConfig.type.displayName,
      aiProviderStatus: _aiProviderStatus(aiConfig),
      pricingProvider: _pricingProviderName(pricingProviderType),
      pricingProviderStatus: _pricingProviderStatus(pricingProviderType),
      backendEndpointConfigured: endpointReadiness.configuredLabel,
      backendEndpointValid: endpointReadiness.validityLabel,
      backendEndpointReleaseSafe: endpointReadiness.releaseSafeLabel,
      backendEndpointMessage: endpointReadiness.message,
      aiBackendClientStatus:
          endpointReadiness.isConfigured && endpointReadiness.isValid
          ? 'Ready'
          : 'Not configured',
      httpBackendClientStatus: _httpBackendStatus(aiConfig, endpointReadiness),
      mockModeActive: mockModeActive ? 'Active' : 'Not configured',
      lastScanPipelineStatus: lastScanPipelineStatus,
      appMode: mockModeActive ? 'development/mock' : 'development',
    );
  }

  String _aiProviderStatus(AiAnalysisProviderConfig config) {
    return switch (config.type) {
      AiAnalysisProviderType.mock => 'Mock',
      AiAnalysisProviderType.openAiVision ||
      AiAnalysisProviderType.geminiVision => 'Coming soon',
    };
  }

  String _httpBackendStatus(
    AiAnalysisProviderConfig config,
    AiBackendEndpointReadiness readiness,
  ) {
    if (config.type == AiAnalysisProviderType.mock) {
      return 'Disabled (mock)';
    }
    if (config.type == AiAnalysisProviderType.geminiVision) {
      return 'Coming soon';
    }
    if (!readiness.isConfigured) {
      return 'Not configured';
    }
    if (!readiness.isValid) {
      return 'Invalid endpoint';
    }
    if (!readiness.isReleaseSafe) {
      return 'Blocked';
    }
    return 'HTTP ready';
  }

  String _pricingProviderStatus(MarketPricingProviderType type) {
    return switch (type) {
      MarketPricingProviderType.mock => 'Mock',
      MarketPricingProviderType.ebayCompletedSales ||
      MarketPricingProviderType.tcgplayer ||
      MarketPricingProviderType.priceCharting ||
      MarketPricingProviderType.customBackend => 'Coming soon',
    };
  }

  String _pricingProviderName(MarketPricingProviderType type) {
    return switch (type) {
      MarketPricingProviderType.mock => 'Mock Pricing',
      MarketPricingProviderType.ebayCompletedSales => 'eBay Completed Sales',
      MarketPricingProviderType.tcgplayer => 'TCGplayer',
      MarketPricingProviderType.priceCharting => 'PriceCharting',
      MarketPricingProviderType.customBackend => 'Custom Backend Pricing',
    };
  }
}
