from app.core.config import settings
from app.services.ai.base_recognition_service import RecognitionResult
from app.services.pricing.base_pricing_provider import (
    PricingProvider,
    PricingProviderUnavailableError,
)
from app.services.pricing.aggregation_service import PricingAggregationService
from app.services.pricing.ebay_pricing_provider import EbayPricingProvider
from app.services.pricing.mock_pricing_provider import MockPricingProvider
from app.services.pricing.pricecharting_pricing_provider import (
    PriceChartingPricingProvider,
)
from app.services.pricing.pricecharting_catalog_provider import (
    PriceChartingCatalogPricingProvider,
)
from app.services.pricing.currency_conversion import CurrencyConversionCache
from app.services.pricing.pricing_engine import (
    MultiProviderPricingEngine,
    PricingProviderKey,
    ProviderRegistration,
)
from app.services.pricing.tcgplayer_pricing_provider import TCGPlayerPricingProvider


_mock_provider = MockPricingProvider()
_ebay_provider = EbayPricingProvider(
    access_token=settings.ebay_access_token,
    browse_api_url=settings.ebay_browse_api_url,
    marketplace_id=settings.ebay_marketplace_id,
    timeout_seconds=settings.ebay_timeout_seconds,
    cache_ttl_seconds=settings.pricing_cache_ttl_seconds,
    min_interval_ms=settings.pricing_provider_min_interval_ms,
)
_tcgplayer_provider = TCGPlayerPricingProvider(
    client_id=settings.tcgplayer_client_id,
    client_secret=settings.tcgplayer_client_secret,
    api_base=settings.tcgplayer_api_base,
    timeout_seconds=settings.tcgplayer_timeout_seconds,
    cache_ttl_seconds=settings.pricing_cache_ttl_seconds,
    min_interval_ms=settings.pricing_provider_min_interval_ms,
)
_pricecharting_provider = PriceChartingPricingProvider(
    api_key=settings.pricecharting_api_key,
    api_base=settings.pricecharting_api_base,
    timeout_seconds=settings.pricecharting_timeout_seconds,
    cache_ttl_seconds=settings.pricing_cache_ttl_seconds,
    min_interval_ms=settings.pricing_provider_min_interval_ms,
)
_pricecharting_catalog_provider = PriceChartingCatalogPricingProvider(
    timeout_seconds=settings.pricecharting_timeout_seconds,
    cache_ttl_seconds=settings.pricing_cache_ttl_seconds,
)


class AutoPricingProvider(PricingProvider):
    provider_name = "auto"

    def price(self, recognition: RecognitionResult):
        return MultiProviderPricingEngine(
            registry=_provider_registry(),
            currency_converter=CurrencyConversionCache(
                target_currency=settings.pricing_target_currency,
                rates_json=settings.pricing_currency_rates_json,
                ttl_seconds=settings.pricing_currency_cache_ttl_seconds,
            ),
        ).price(recognition)


_auto_provider = AutoPricingProvider()


def get_pricing_provider(provider_name: str | None = None) -> PricingProvider:
    selected_provider = (provider_name or settings.pricing_provider).strip().lower()

    if selected_provider in {"auto", "real", "engine", "multi_provider"}:
        return _auto_provider

    if selected_provider == "mock":
        return PricingAggregationService([_mock_provider], fallback_provider=_mock_provider)

    if selected_provider == "ebay":
        return _ebay_provider

    if selected_provider == "tcgplayer":
        return _tcgplayer_provider

    if selected_provider == "pricecharting":
        return _pricecharting_provider

    if selected_provider in {"pricecharting_catalog", "catalog"}:
        return _pricecharting_catalog_provider

    if selected_provider == "aggregate":
        providers = _configured_providers(
            [_ebay_provider, _tcgplayer_provider, _pricecharting_provider]
        )
        if not providers:
            raise PricingProviderUnavailableError(
                "PRICING_PROVIDER=aggregate requires at least one configured "
                "real pricing provider."
            )
        return PricingAggregationService(providers)

    raise PricingProviderUnavailableError(
        f"Unsupported PRICING_PROVIDER '{selected_provider}'. "
        "Supported providers: auto, mock, ebay, tcgplayer, pricecharting, "
        "pricecharting_catalog, aggregate."
    )


def _provider_registry() -> dict[PricingProviderKey, ProviderRegistration]:
    return {
        PricingProviderKey.PRICECHARTING_CATALOG: ProviderRegistration(
            key=PricingProviderKey.PRICECHARTING_CATALOG,
            provider=_pricecharting_catalog_provider,
            display_name="PriceCharting",
            attribution_text="Pricing data powered by PriceCharting",
            configured=_pricecharting_catalog_provider.is_configured,
            minimum_comps=1,
            valuation_strategy="catalog_guide",
        ),
        PricingProviderKey.PRICECHARTING_API: ProviderRegistration(
            key=PricingProviderKey.PRICECHARTING_API,
            provider=_pricecharting_provider,
            display_name="PriceCharting",
            attribution_text="Pricing data powered by PriceCharting",
            configured=bool(_provider_value(_pricecharting_provider, "_api_key")),
            minimum_comps=1,
            valuation_strategy="catalog_guide",
        ),
        PricingProviderKey.EBAY: ProviderRegistration(
            key=PricingProviderKey.EBAY,
            provider=_ebay_provider,
            display_name="eBay sold comps",
            attribution_text="Market data powered by eBay",
            configured=bool(_provider_value(_ebay_provider, "_access_token")),
            minimum_comps=3,
            valuation_strategy="sold_completed",
        ),
        PricingProviderKey.TCGPLAYER: ProviderRegistration(
            key=PricingProviderKey.TCGPLAYER,
            provider=_tcgplayer_provider,
            display_name="TCGplayer",
            attribution_text="Market data powered by TCGplayer",
            configured=bool(
                _provider_value(_tcgplayer_provider, "_client_id")
                and _provider_value(_tcgplayer_provider, "_client_secret")
            ),
            minimum_comps=1,
            valuation_strategy="market_price",
        ),
        PricingProviderKey.KICKSDB: ProviderRegistration(
            key=PricingProviderKey.KICKSDB,
            provider=None,
            display_name="KicksDB",
            attribution_text="Market data powered by KicksDB",
            configured=False,
            minimum_comps=3,
            valuation_strategy="sold_completed",
            planned=True,
        ),
        PricingProviderKey.WATCHCHARTS: ProviderRegistration(
            key=PricingProviderKey.WATCHCHARTS,
            provider=None,
            display_name="WatchCharts",
            attribution_text="Market data powered by WatchCharts",
            configured=False,
            minimum_comps=3,
            valuation_strategy="specialist_appraisal",
            planned=True,
        ),
    }


def _providers_for_recognition(recognition: RecognitionResult) -> list[PricingProvider]:
    text = _recognition_text(recognition)
    preferred: list[PricingProvider] = []

    if _looks_like_trading_card(text):
        preferred.extend([_tcgplayer_provider, _pricecharting_provider, _ebay_provider])
    elif _looks_like_video_game_or_comic(text):
        preferred.extend([_pricecharting_provider, _ebay_provider])
    else:
        preferred.extend([_ebay_provider, _pricecharting_provider])

    return _configured_providers(preferred)


def _configured_providers(providers: list[PricingProvider]) -> list[PricingProvider]:
    configured: list[PricingProvider] = []
    for provider in providers:
        if provider.provider_name == "ebay" and _provider_value(provider, "_access_token"):
            configured.append(provider)
        elif (
            provider.provider_name == "tcgplayer"
            and _provider_value(provider, "_client_id")
            and _provider_value(provider, "_client_secret")
        ):
            configured.append(provider)
        elif (
            provider.provider_name == "pricecharting"
            and _provider_value(provider, "_api_key")
        ):
            configured.append(provider)
    seen: set[str] = set()
    unique: list[PricingProvider] = []
    for provider in configured:
        if provider.provider_name in seen:
            continue
        seen.add(provider.provider_name)
        unique.append(provider)
    return unique


def _provider_value(provider: PricingProvider, attribute: str) -> str:
    return str(getattr(provider, attribute, "") or "").strip()


def _recognition_text(recognition: RecognitionResult) -> str:
    values = [
        recognition.title,
        recognition.category,
        recognition.brand,
        recognition.setName,
        recognition.series,
        recognition.cardNumber,
        recognition.playerOrCharacter,
        recognition.rarity,
        recognition.edition,
        recognition.notes,
    ]
    return " ".join(str(value).lower() for value in values if value)


def _looks_like_trading_card(text: str) -> bool:
    keywords = {
        "trading card",
        "pokemon",
        "pokémon",
        "magic",
        "mtg",
        "yugioh",
        "yu-gi-oh",
        "sports card",
        "rookie card",
        "card number",
        "holo",
        "foil",
        "psa",
        "bgs",
        "cgc",
    }
    return any(keyword in text for keyword in keywords)


def _looks_like_video_game_or_comic(text: str) -> bool:
    keywords = {
        "video game",
        "game cartridge",
        "nintendo",
        "playstation",
        "xbox",
        "comic",
        "comic book",
        "manga",
    }
    return any(keyword in text for keyword in keywords)
