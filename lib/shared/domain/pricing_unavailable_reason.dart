import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';

class PricingUnavailableCopy {
  const PricingUnavailableCopy({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.shortLabel,
  });

  final String title;
  final String message;
  final String actionLabel;
  final String shortLabel;
}

PricingUnavailableCopy pricingUnavailableCopy({
  String? reasonCode,
  ValuationStatus status = ValuationStatus.unavailable,
}) {
  final normalizedReason = reasonCode?.trim().toUpperCase();
  return switch (normalizedReason) {
    'NO_MARKET_MATCH' => const PricingUnavailableCopy(
      title: 'No trusted match yet',
      message:
          'PackLox could not match this identity to trusted catalog or sold-comps evidence.',
      actionLabel: 'Correct details and reprice',
      shortLabel: 'No trusted match',
    ),
    'PROVIDER_NOT_CONFIGURED' => const PricingUnavailableCopy(
      title: 'Provider coming soon',
      message:
          'PackLox does not have a connected pricing provider for this category yet.',
      actionLabel: 'Provider coming soon',
      shortLabel: 'Provider coming soon',
    ),
    'WEAK_IDENTITY_MATCH' => const PricingUnavailableCopy(
      title: 'Weak identity match',
      message:
          'The title, set, SKU, card number, or condition is not strong enough for a trusted valuation.',
      actionLabel: 'Correct details and reprice',
      shortLabel: 'Weak match',
    ),
    'INSUFFICIENT_TRUSTED_MARKET_DATA' => const PricingUnavailableCopy(
      title: 'Not enough market evidence',
      message: 'There are not enough trusted comps to show a reliable value.',
      actionLabel: 'Try again later',
      shortLabel: 'Insufficient data',
    ),
    'LOW_PRICING_CONFIDENCE' => const PricingUnavailableCopy(
      title: 'Pricing confidence too low',
      message:
          'PackLox found a possible match, but confidence is too low to show it as a trusted value.',
      actionLabel: 'Correct details and reprice',
      shortLabel: 'Low confidence',
    ),
    'SPECIALIST_SOURCE_NOT_CONNECTED' => const PricingUnavailableCopy(
      title: 'Specialist source not connected',
      message:
          'This category needs a specialist pricing source before PackLox can show a trusted value.',
      actionLabel: 'Provider coming soon',
      shortLabel: 'Specialist source needed',
    ),
    'LOOKUP_FAILED' => const PricingUnavailableCopy(
      title: 'Lookup did not complete',
      message:
          'The pricing lookup did not complete. Any previous trusted value is preserved.',
      actionLabel: 'Try again later',
      shortLabel: 'Lookup failed',
    ),
    'CATALOG_NO_PRICE' => const PricingUnavailableCopy(
      title: 'Catalog price unavailable',
      message:
          'This catalog result exists, but the provider did not include a trusted price for it yet.',
      actionLabel: 'Try again later',
      shortLabel: 'No catalog price',
    ),
    _ => _pricingUnavailableCopyForStatus(status),
  };
}

PricingUnavailableCopy _pricingUnavailableCopyForStatus(
  ValuationStatus status,
) {
  return switch (status) {
    ValuationStatus.providerNotConfigured => const PricingUnavailableCopy(
      title: 'Provider coming soon',
      message:
          'PackLox does not have a connected pricing provider for this category yet.',
      actionLabel: 'Provider coming soon',
      shortLabel: 'Provider coming soon',
    ),
    ValuationStatus.noMarketMatch => const PricingUnavailableCopy(
      title: 'No trusted match yet',
      message:
          'PackLox could not match this identity to trusted market evidence.',
      actionLabel: 'Correct details and reprice',
      shortLabel: 'No trusted match',
    ),
    ValuationStatus.lookupFailed => const PricingUnavailableCopy(
      title: 'Lookup did not complete',
      message:
          'The pricing lookup did not complete. Try again when the provider is available.',
      actionLabel: 'Try again later',
      shortLabel: 'Lookup failed',
    ),
    ValuationStatus.aiEstimated => const PricingUnavailableCopy(
      title: 'Needs market verification',
      message:
          'This value is AI-estimated only. PackLox needs trusted market data before calling it verified.',
      actionLabel: 'Correct details and reprice',
      shortLabel: 'Needs review',
    ),
    ValuationStatus.marketEstimated => const PricingUnavailableCopy(
      title: 'Trusted value unavailable',
      message:
          'PackLox expected a market value but the provider did not return a displayable amount.',
      actionLabel: 'Try again later',
      shortLabel: 'Unavailable',
    ),
    ValuationStatus.unavailable => const PricingUnavailableCopy(
      title: 'Trusted value unavailable',
      message:
          'PackLox is not showing a value because trusted market evidence is unavailable.',
      actionLabel: 'Add photos or correct details',
      shortLabel: 'Value unavailable',
    ),
  };
}
