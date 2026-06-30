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
  }) {
    final mockModeActive =
        aiConfig.type == AiAnalysisProviderType.mock &&
        pricingProviderType == MarketPricingProviderType.mock;

    return ProviderDiagnostics(
      aiProvider: aiConfig.type.displayName,
      aiProviderStatus: _aiProviderStatus(aiConfig),
      pricingProvider: _pricingProviderName(pricingProviderType),
      pricingProviderStatus: _pricingProviderStatus(pricingProviderType),
      backendEndpointConfigured: aiConfig.hasBackendAnalysisEndpoint
          ? 'Ready'
          : 'Not configured',
      aiBackendClientStatus: aiConfig.hasBackendAnalysisEndpoint
          ? 'Ready'
          : 'Not configured',
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
