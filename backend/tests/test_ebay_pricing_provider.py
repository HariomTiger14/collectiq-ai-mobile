import time
import unittest

import httpx

from app.services.ai.mock_recognition_service import MockRecognitionProvider
from app.services.pricing.aggregation_service import PricingAggregationService
from app.services.pricing.base_pricing_provider import (
    EmptyMarketDataError,
    PricingProviderRateLimitError,
    PricingProviderTimeoutError,
    PricingProviderUnavailableError,
)
from app.services.pricing.ebay_pricing_provider import EbayPricingProvider
from app.services.pricing.mock_pricing_provider import MockPricingProvider


class EbayPricingProviderTest(unittest.TestCase):
    def setUp(self) -> None:
        self.recognition = MockRecognitionProvider().recognize("uploads/card.png")

    def test_successful_provider_response_normalizes_comparable_sales(self) -> None:
        client = _FakeHttpClient(response=_FakeResponse(body=_ebay_payload()))
        provider = _provider(client=client)

        pricing = provider.price(self.recognition)

        self.assertEqual(client.call_count, 1)
        self.assertEqual(pricing.pricingSource, "eBay sold listings")
        self.assertEqual(pricing.pricingAge, "live")
        self.assertEqual(pricing.cacheStatus, "miss")
        self.assertEqual(len(pricing.comparableSales), 3)
        self.assertEqual(pricing.providerDiagnostics["valuationStrategy"], "sold_completed")
        self.assertEqual(
            pricing.providerDiagnostics["attributionText"],
            "Pricing source: eBay sold listings",
        )
        self.assertGreater(pricing.estimatedMarketValue, 0)
        self.assertGreaterEqual(pricing.highEstimate, pricing.lowEstimate)
        self.assertEqual(client.last_request["headers"]["X-EBAY-C-MARKETPLACE-ID"], "EBAY_AU")
        self.assertEqual(client.last_request["params"]["sold_only"], "true")

    def test_provider_is_disabled_without_sold_comps_endpoint(self) -> None:
        provider = _provider(sold_comps_api_url="")

        with self.assertRaises(PricingProviderUnavailableError) as context:
            provider.price(self.recognition)

        self.assertIn("EBAY_SOLD_COMPS_API_URL", str(context.exception))

    def test_active_browse_listings_are_rejected(self) -> None:
        provider = _provider(
            client=_FakeHttpClient(response=_FakeResponse(body=_active_listing_payload())),
        )

        with self.assertRaises(EmptyMarketDataError) as context:
            provider.price(self.recognition)

        self.assertIn("trust filters", str(context.exception))

    def test_requires_minimum_trusted_sold_comps(self) -> None:
        provider = _provider(
            client=_FakeHttpClient(response=_FakeResponse(body=_single_sold_comp_payload())),
            min_sold_comps=3,
        )

        with self.assertRaises(EmptyMarketDataError) as context:
            provider.price(self.recognition)

        self.assertIn("requires at least 3", str(context.exception))

    def test_filters_weak_title_matches(self) -> None:
        provider = _provider(
            client=_FakeHttpClient(response=_FakeResponse(body=_weak_match_payload())),
        )

        with self.assertRaises(EmptyMarketDataError):
            provider.price(self.recognition)

    def test_trims_top_and_bottom_outliers(self) -> None:
        provider = _provider(
            client=_FakeHttpClient(response=_FakeResponse(body=_outlier_payload())),
            min_sold_comps=3,
        )

        pricing = provider.price(self.recognition)

        prices = [sale.soldPrice for sale in pricing.comparableSales]
        self.assertNotIn(1, prices)
        self.assertNotIn(9999, prices)

    def test_timeout_maps_to_pricing_timeout(self) -> None:
        provider = _provider(
            client=_FakeHttpClient(exception=httpx.TimeoutException("slow")),
        )

        with self.assertRaises(PricingProviderTimeoutError):
            provider.price(self.recognition)

    def test_rate_limit_maps_to_pricing_rate_limit(self) -> None:
        provider = _provider(client=_FakeHttpClient(response=_FakeResponse(status_code=429)))

        with self.assertRaises(PricingProviderRateLimitError):
            provider.price(self.recognition)

    def test_cache_hit_prevents_repeated_provider_request(self) -> None:
        client = _FakeHttpClient(response=_FakeResponse(body=_ebay_payload()))
        provider = _provider(client=client, cache_ttl_seconds=60)

        first = provider.price(self.recognition)
        second = provider.price(self.recognition)

        self.assertEqual(client.call_count, 1)
        self.assertEqual(first.cacheStatus, "miss")
        self.assertEqual(second.cacheStatus, "hit")

    def test_cache_expiry_allows_refresh(self) -> None:
        client = _FakeHttpClient(response=_FakeResponse(body=_ebay_payload()))
        provider = _provider(
            client=client,
            cache_ttl_seconds=1,
            min_interval_ms=0,
        )

        provider.price(self.recognition)
        time.sleep(1.05)
        provider.price(self.recognition)

        self.assertEqual(client.call_count, 2)

    def test_aggregator_falls_back_to_mock_when_ebay_unavailable(self) -> None:
        provider = _provider(access_token="", client=_FakeHttpClient())

        pricing = PricingAggregationService(
            [provider],
            fallback_provider=MockPricingProvider(),
        ).price(self.recognition)

        self.assertTrue(pricing.fallbackUsed)
        self.assertEqual(pricing.cacheStatus, "fallback")
        self.assertIn("EBAY_ACCESS_TOKEN", pricing.providerDiagnostics["fallbackReason"])
        self.assertGreater(pricing.estimatedMarketValue, 0)


def _provider(
    *,
    access_token: str = "test-token",
    sold_comps_api_url: str = "https://api.ebay.test/sold-comps",
    client=None,
    cache_ttl_seconds: int = 900,
    min_interval_ms: int = 0,
    min_sold_comps: int = 3,
) -> EbayPricingProvider:
    return EbayPricingProvider(
        access_token=access_token,
        sold_comps_api_url=sold_comps_api_url,
        browse_api_url="https://api.ebay.com/buy/browse/v1/item_summary/search",
        marketplace_id="EBAY_AU",
        timeout_seconds=1,
        cache_ttl_seconds=cache_ttl_seconds,
        min_interval_ms=min_interval_ms,
        min_sold_comps=min_sold_comps,
        client=client,
    )


def _ebay_payload() -> dict:
    return {
        "itemSummaries": [
            {
                "title": "1999 Pokemon Charizard Holo PSA 8",
                "price": {"value": "1800.00", "currency": "AUD"},
                "condition": "Graded",
                "itemEndDate": "2026-06-25T00:00:00Z",
                "itemWebUrl": "https://example.test/item/1",
                "categoryName": "Collectible Card Games",
            },
            {
                "title": "Pokemon Charizard Base Set Holo",
                "price": {"value": "1950.00", "currency": "AUD"},
                "condition": "Near Mint",
                "itemEndDate": "2026-06-26T00:00:00Z",
                "itemWebUrl": "https://example.test/item/2",
                "categoryName": "Collectible Card Games",
            },
            {
                "title": "Charizard Holo Pokemon Card",
                "price": {"value": "2100.00", "currency": "AUD"},
                "condition": "Excellent",
                "itemEndDate": "2026-06-27T00:00:00Z",
                "itemWebUrl": "https://example.test/item/3",
                "categoryName": "Collectible Card Games",
            },
        ]
    }


def _active_listing_payload() -> dict:
    payload = _ebay_payload()
    for item in payload["itemSummaries"]:
        item.pop("itemEndDate", None)
        item["itemCreationDate"] = "2026-06-27T00:00:00Z"
    return payload


def _single_sold_comp_payload() -> dict:
    return {"itemSummaries": [_ebay_payload()["itemSummaries"][0]]}


def _weak_match_payload() -> dict:
    return {
        "itemSummaries": [
            {
                "title": "Vintage Nintendo Controller",
                "price": {"value": "120.00", "currency": "AUD"},
                "condition": "Used",
                "itemEndDate": "2026-06-25T00:00:00Z",
                "categoryName": "Video Games",
            },
            {
                "title": "Football signed poster",
                "price": {"value": "80.00", "currency": "AUD"},
                "condition": "Used",
                "itemEndDate": "2026-06-26T00:00:00Z",
                "categoryName": "Sports Memorabilia",
            },
            {
                "title": "Toy car storage case",
                "price": {"value": "20.00", "currency": "AUD"},
                "condition": "Used",
                "itemEndDate": "2026-06-27T00:00:00Z",
                "categoryName": "Toys",
            },
        ]
    }


def _outlier_payload() -> dict:
    values = [1, 1600, 1700, 1750, 1800, 1850, 1900, 1950, 2000, 9999]
    return {
        "itemSummaries": [
            {
                "title": "Pokemon Charizard Base Set Holo",
                "price": {"value": str(value), "currency": "AUD"},
                "condition": "Near Mint",
                "itemEndDate": f"2026-06-{10 + index:02d}T00:00:00Z",
                "categoryName": "Collectible Card Games",
            }
            for index, value in enumerate(values)
        ]
    }


class _FakeResponse:
    def __init__(self, *, status_code: int = 200, body: dict | None = None) -> None:
        self.status_code = status_code
        self._body = body or {}

    def json(self) -> dict:
        return self._body


class _FakeHttpClient:
    def __init__(
        self,
        *,
        response: _FakeResponse | None = None,
        exception: Exception | None = None,
    ) -> None:
        self.response = response or _FakeResponse()
        self.exception = exception
        self.call_count = 0
        self.last_request: dict | None = None

    def get(self, url: str, **kwargs) -> _FakeResponse:
        self.call_count += 1
        self.last_request = {"url": url, **kwargs}
        if self.exception is not None:
            raise self.exception
        return self.response


if __name__ == "__main__":
    unittest.main()
