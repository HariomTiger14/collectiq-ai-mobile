from app.core.config import settings
from app.services.pricing.base_pricing_provider import PricingProvider
from app.services.pricing.mock_pricing_provider import MockPricingProvider


_mock_provider = MockPricingProvider()


def get_pricing_provider(provider_name: str | None = None) -> PricingProvider:
    selected_provider = (provider_name or settings.pricing_provider).strip().lower()

    if selected_provider == "mock":
        return _mock_provider

    if selected_provider in {"ebay", "tcgplayer", "pricecharting", "psa", "custom"}:
        raise ValueError(
            f"Pricing provider '{selected_provider}' is not implemented yet. "
            "Use PRICING_PROVIDER=mock."
        )

    raise ValueError(
        f"Unsupported PRICING_PROVIDER '{selected_provider}'. "
        "Supported providers: mock, ebay, tcgplayer, pricecharting, psa, custom."
    )
