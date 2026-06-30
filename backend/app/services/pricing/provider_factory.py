from app.core.config import settings
from app.services.pricing.base_pricing_provider import (
    PricingProvider,
    PricingProviderUnavailableError,
)
from app.services.pricing.aggregation_service import PricingAggregationService
from app.services.pricing.external_pricing_providers import (
    EbayPricingProvider,
    PriceChartingPricingProvider,
    TCGPlayerPricingProvider,
)
from app.services.pricing.mock_pricing_provider import MockPricingProvider


_mock_provider = MockPricingProvider()
_ebay_provider = EbayPricingProvider()
_tcgplayer_provider = TCGPlayerPricingProvider()
_pricecharting_provider = PriceChartingPricingProvider()


def get_pricing_provider(provider_name: str | None = None) -> PricingProvider:
    selected_provider = (provider_name or settings.pricing_provider).strip().lower()

    if selected_provider == "mock":
        return PricingAggregationService([_mock_provider], fallback_provider=_mock_provider)

    if selected_provider == "ebay":
        return PricingAggregationService([_ebay_provider], fallback_provider=_mock_provider)

    if selected_provider == "tcgplayer":
        return PricingAggregationService([_tcgplayer_provider], fallback_provider=_mock_provider)

    if selected_provider == "pricecharting":
        return PricingAggregationService([_pricecharting_provider], fallback_provider=_mock_provider)

    if selected_provider == "aggregate":
        return PricingAggregationService(
            [_ebay_provider, _tcgplayer_provider, _pricecharting_provider],
            fallback_provider=_mock_provider,
        )

    raise PricingProviderUnavailableError(
        f"Unsupported PRICING_PROVIDER '{selected_provider}'. "
        "Supported providers: mock, ebay, tcgplayer, pricecharting, aggregate."
    )
