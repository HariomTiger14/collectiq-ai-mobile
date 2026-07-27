import unittest

import httpx

from app.services.ai.base_recognition_service import RecognitionResult
from app.services.pricing.base_pricing_provider import (
    MarketComparableSale,
    PricingResult,
    utc_timestamp,
)
from app.services.pricing.pricecharting_catalog_provider import (
    PriceChartingCatalogPricingProvider,
)
from app.services.pricing.currency_conversion import CurrencyConversionCache
from app.services.pricing.pricing_engine import (
    MultiProviderPricingEngine,
    PricingProviderKey,
    ProviderRegistration,
    route_for_recognition,
)


class PriceChartingCatalogPricingProviderTest(unittest.TestCase):
    def test_catalog_provider_returns_pricecharting_csv_prices(self) -> None:
        requests: list[httpx.Request] = []

        def handler(request: httpx.Request) -> httpx.Response:
            requests.append(request)
            return httpx.Response(200, json=[_catalog_row()])

        provider = PriceChartingCatalogPricingProvider(
            supabase_url="https://example.supabase.co",
            service_role_key="service-role",
            client=httpx.Client(transport=httpx.MockTransport(handler)),
            cache_ttl_seconds=60,
        )

        pricing = provider.price(_recognition())

        self.assertEqual(pricing.valuationStatus, "market_estimated")
        self.assertEqual(pricing.valuationSource, "PriceCharting")
        self.assertEqual(pricing.currency, "USD")
        self.assertEqual(pricing.estimatedMarketValue, 387)
        self.assertEqual(pricing.lowEstimate, 161)
        self.assertEqual(pricing.highEstimate, 800)
        self.assertEqual(len(pricing.comparableSales), 3)
        self.assertEqual(pricing.providerDiagnostics["matchedProductId"], "999")
        self.assertIn("product_name.ilike", requests[0].url.params.get("or"))

    def test_catalog_provider_cache_hit_prevents_second_supabase_call(self) -> None:
        def handler(request: httpx.Request) -> httpx.Response:
            return httpx.Response(200, json=[_catalog_row()])

        provider = PriceChartingCatalogPricingProvider(
            supabase_url="https://example.supabase.co",
            service_role_key="service-role",
            client=httpx.Client(transport=httpx.MockTransport(handler)),
            cache_ttl_seconds=60,
        )

        first = provider.price(_recognition())
        second = provider.price(_recognition())

        self.assertEqual(first.cacheStatus, "miss")
        self.assertEqual(second.cacheStatus, "hit")


class MultiProviderPricingEngineTest(unittest.TestCase):
    def test_routes_pokemon_to_pricecharting_then_card_marketplaces(self) -> None:
        route = route_for_recognition(_recognition())

        self.assertEqual(route.category_key, "pokemon_cards")
        self.assertEqual(route.provider_keys[0], PricingProviderKey.PRICECHARTING_CATALOG)
        self.assertIn(PricingProviderKey.TCGPLAYER, route.provider_keys)

    def test_engine_returns_clean_unavailable_when_route_has_no_configured_provider(self) -> None:
        engine = MultiProviderPricingEngine(registry={})

        pricing = engine.price(_recognition())

        self.assertEqual(pricing.valuationStatus, "unavailable")
        self.assertEqual(pricing.estimatedMarketValue, 0)
        self.assertEqual(
            pricing.providerDiagnostics["reasonCode"],
            "PROVIDER_NOT_CONFIGURED",
        )
        self.assertEqual(pricing.providerDiagnostics["providerRoute"], "pokemon_cards")

    def test_engine_uses_configured_catalog_provider(self) -> None:
        provider = _StaticPricingProvider(
            "pricecharting_catalog",
            [_sale(161), _sale(200), _sale(800)],
            source="PriceCharting",
        )
        engine = MultiProviderPricingEngine(
            registry={
                PricingProviderKey.PRICECHARTING_CATALOG: _registration(
                    PricingProviderKey.PRICECHARTING_CATALOG,
                    provider,
                    minimum_comps=1,
                )
            }
        )

        pricing = engine.price(_recognition())

        self.assertEqual(pricing.valuationStatus, "market_estimated")
        self.assertEqual(pricing.valuationSource, "PriceCharting")
        self.assertEqual(pricing.providerDiagnostics["providerRoute"], "pokemon_cards")
        self.assertEqual(
            pricing.providerDiagnostics["attributionText"],
            "Pricing data powered by PriceCharting",
        )

    def test_engine_blocks_provider_result_when_minimum_comps_rule_fails(self) -> None:
        provider = _StaticPricingProvider(
            "ebay",
            [_sale(12)],
            source="eBay sold comps",
        )
        engine = MultiProviderPricingEngine(
            registry={
                PricingProviderKey.EBAY: _registration(
                    PricingProviderKey.EBAY,
                    provider,
                    display_name="eBay sold comps",
                    minimum_comps=3,
                )
            }
        )

        recognition = _recognition(title="Hot Wheels Porsche", category="toy")
        pricing = engine.price(recognition)

        self.assertEqual(pricing.valuationStatus, "unavailable")
        self.assertEqual(
            pricing.providerDiagnostics["reasonCode"],
            "INSUFFICIENT_TRUSTED_MARKET_DATA",
        )
        self.assertIn("requires at least 3", pricing.providerDiagnostics["fallbackReason"])

    def test_engine_converts_currency_when_trusted_rate_is_configured(self) -> None:
        provider = _StaticPricingProvider(
            "pricecharting_catalog",
            [_sale(100), _sale(200), _sale(300)],
            source="PriceCharting",
        )
        engine = MultiProviderPricingEngine(
            registry={
                PricingProviderKey.PRICECHARTING_CATALOG: _registration(
                    PricingProviderKey.PRICECHARTING_CATALOG,
                    provider,
                    minimum_comps=1,
                )
            },
            currency_converter=CurrencyConversionCache(
                target_currency="AUD",
                rates_json='{"USD_AUD": 1.5}',
            ),
        )

        pricing = engine.price(_recognition())

        self.assertEqual(pricing.currency, "AUD")
        self.assertEqual(pricing.estimatedMarketValue, 300)
        self.assertEqual(pricing.providerDiagnostics["originalPrice"], "200")
        self.assertEqual(pricing.providerDiagnostics["originalCurrency"], "USD")
        self.assertEqual(pricing.providerDiagnostics["exchangeRateUsed"], "1.5")


class _StaticPricingProvider:
    def __init__(
        self,
        provider_name: str,
        sales: list[MarketComparableSale],
        *,
        source: str,
    ) -> None:
        self.provider_name = provider_name
        self._sales = sales
        self._source = source

    def price(self, recognition) -> PricingResult:
        prices = [sale.soldPrice for sale in self._sales]
        return PricingResult(
            estimatedMarketValue=round(sum(prices) / len(prices)),
            lowEstimate=min(prices),
            highEstimate=max(prices),
            currency=self._sales[0].currency,
            pricingSource=self._source,
            pricingConfidence=82,
            lastUpdated=utc_timestamp(),
            valuationStatus="market_estimated",
            valuationSource=self._source,
            marketTrend="Stable",
            sourceCount=1,
            pricingAge="fresh",
            comparableSales=self._sales,
            cacheStatus="miss",
            providerDiagnostics={
                "provider": self.provider_name,
                "providers": self.provider_name,
                "responseLatencyMs": "1",
                "comparableCount": str(len(self._sales)),
            },
        )


def _registration(
    key: PricingProviderKey,
    provider,
    *,
    display_name: str = "PriceCharting",
    minimum_comps: int,
) -> ProviderRegistration:
    return ProviderRegistration(
        key=key,
        provider=provider,
        display_name=display_name,
        attribution_text=f"Pricing data powered by {display_name}",
        configured=True,
        minimum_comps=minimum_comps,
        valuation_strategy="sold_completed",
    )


def _recognition(
    *,
    title: str = "Charizard #4 Base Set",
    category: str = "Pokemon Cards",
) -> RecognitionResult:
    return RecognitionResult(
        title=title,
        category=category,
        confidence=86,
        estimatedValue=0,
        condition="Ungraded",
        recommendation="Save to portfolio.",
        description="Pokemon card.",
        detectedObjects=["card"],
        aiProvider="test",
        processingTimeMs=1,
        primaryMatch=title,
        alternativeMatches=[],
        confidenceExplanation="Clear identity.",
        detectionQuality="Good",
        aiReasoning="Matched visible card details.",
        setName="Base Set",
        cardNumber="4",
    )


def _catalog_row() -> dict:
    return {
        "pricecharting_id": "999",
        "product_name": "Charizard #4 Base Set",
        "console_name": "Pokemon Cards",
        "category": "Pokemon Cards",
        "upc": "",
        "loose_price_cents": 16100,
        "cib_price_cents": 20000,
        "new_price_cents": None,
        "graded_price_cents": 80000,
        "currency": "USD",
        "product_url": "https://www.pricecharting.com/game/pokemon/charizard",
        "source_file": "pokemon.csv",
        "source_downloaded_at": "2026-07-25T00:00:00Z",
        "updated_at": "2026-07-26T00:00:00Z",
        "normalized_identity": "charizard #4 base set pokemon cards",
    }


def _sale(price: int) -> MarketComparableSale:
    return MarketComparableSale(
        source="PriceCharting",
        title=f"Comparable sale {price}",
        soldPrice=price,
        currency="USD",
        soldDate="2026-07-26T00:00:00Z",
        condition="Ungraded",
        url=None,
    )


if __name__ == "__main__":
    unittest.main()
