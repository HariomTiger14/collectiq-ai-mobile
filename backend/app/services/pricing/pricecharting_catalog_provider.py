from __future__ import annotations

import time
from dataclasses import replace
from typing import Any

import httpx

from app.core.config import settings
from app.services.ai.base_recognition_service import RecognitionResult
from app.services.pricing.base_pricing_provider import (
    EmptyMarketDataError,
    MarketComparableSale,
    PricingProvider,
    PricingProviderUnavailableError,
    PricingResult,
    utc_timestamp,
)
from app.services.pricing.cache import InMemoryPricingCache
from app.services.pricing.catalog_search_service import (
    CatalogSearchError,
    _normalize_query,
    _postgrest_ilike_pattern,
)


class PriceChartingCatalogPricingProvider(PricingProvider):
    provider_name = "pricecharting_catalog"

    def __init__(
        self,
        *,
        supabase_url: str | None = None,
        service_role_key: str | None = None,
        timeout_seconds: float = 5,
        cache_ttl_seconds: int = 900,
        client: httpx.Client | None = None,
        cache: InMemoryPricingCache | None = None,
    ) -> None:
        self._supabase_url = (
            supabase_url if supabase_url is not None else settings.supabase_url
        ).strip().rstrip("/")
        self._service_role_key = (
            service_role_key
            if service_role_key is not None
            else settings.supabase_service_role_key
        ).strip()
        self._timeout_seconds = timeout_seconds
        self._client = client
        self._cache = cache or InMemoryPricingCache(cache_ttl_seconds)

    @property
    def is_configured(self) -> bool:
        return bool(self._supabase_url and self._service_role_key)

    def price(self, recognition: RecognitionResult) -> PricingResult:
        if not self.is_configured:
            raise PricingProviderUnavailableError(
                "PriceCharting catalog lookup requires SUPABASE_URL and "
                "SUPABASE_SERVICE_ROLE_KEY."
            )

        query = self._query_for(recognition)
        cache_key = self._cache_key(recognition, query)
        cached = self._cache.get(cache_key)
        if isinstance(cached, PricingResult):
            return replace(
                cached,
                cacheStatus="hit",
                providerDiagnostics={
                    **cached.providerDiagnostics,
                    "cacheStatus": "hit",
                    "provider": self.provider_name,
                },
            )

        started_at = time.perf_counter()
        rows = self._fetch_rows(query)
        latency_ms = int((time.perf_counter() - started_at) * 1000)
        if not rows:
            raise EmptyMarketDataError("PriceCharting catalog returned no matching products.")

        ranked = sorted(
            rows,
            key=lambda row: self._match_score(row, recognition, query),
            reverse=True,
        )
        best = ranked[0]
        score = self._match_score(best, recognition, query)
        if score < 40:
            raise EmptyMarketDataError(
                "PriceCharting catalog did not produce a trusted identity match."
            )

        comparable_sales = self._sales_from_row(best, recognition)
        if not comparable_sales:
            raise EmptyMarketDataError(
                "PriceCharting catalog match has no usable pricing fields."
            )

        prices = [sale.soldPrice for sale in comparable_sales]
        confidence = self._confidence(recognition, score, comparable_sales)
        result = PricingResult(
            estimatedMarketValue=max(1, round(sum(prices) / len(prices))),
            lowEstimate=max(1, min(prices)),
            highEstimate=max(1, max(prices)),
            currency=comparable_sales[0].currency,
            pricingSource="PriceCharting CSV catalog",
            pricingConfidence=confidence,
            lastUpdated=utc_timestamp(),
            valuationStatus="market_estimated",
            valuationSource="PriceCharting",
            marketTrend="Stable",
            sourceCount=1,
            pricingAge="daily_catalog",
            comparableSales=comparable_sales,
            cacheStatus="miss",
            providerDiagnostics={
                "provider": self.provider_name,
                "cacheStatus": "miss",
                "responseLatencyMs": str(latency_ms),
                "pricingFreshness": "daily_catalog",
                "fallbackReason": "",
                "sourceConfidence": str(confidence),
                "resultCount": str(len(comparable_sales)),
                "matchedProductId": str(best.get("pricecharting_id") or ""),
                "matchedProductName": str(best.get("product_name") or ""),
                "matchedSourceFile": str(best.get("source_file") or ""),
                "matchScore": str(score),
            },
        )
        self._cache.set(cache_key, result)
        return result

    def _fetch_rows(self, query: str) -> list[dict[str, Any]]:
        pattern = _postgrest_ilike_pattern(query)
        params = {
            "select": (
                "pricecharting_id,product_name,console_name,category,upc,"
                "loose_price_cents,cib_price_cents,new_price_cents,"
                "graded_price_cents,currency,product_url,source_file,"
                "source_downloaded_at,updated_at,normalized_identity"
            ),
            "or": (
                f"(product_name.ilike.{pattern},"
                f"console_name.ilike.{pattern},"
                f"category.ilike.{pattern},"
                f"upc.ilike.{pattern},"
                f"normalized_identity.ilike.{pattern})"
            ),
            "limit": "25",
        }
        payload = self._request("GET", "/rest/v1/pricecharting_catalog", params=params)
        if not isinstance(payload, list):
            return []
        return [row for row in payload if isinstance(row, dict)]

    def _request(
        self,
        method: str,
        path: str,
        *,
        params: dict[str, str] | None = None,
    ) -> Any:
        headers = {
            "apikey": self._service_role_key,
            "Authorization": f"Bearer {self._service_role_key}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        }
        client = self._client or httpx.Client(timeout=self._timeout_seconds)
        should_close = self._client is None
        try:
            response = client.request(
                method,
                f"{self._supabase_url}{path}",
                headers=headers,
                params=params,
            )
            response.raise_for_status()
            if not response.content:
                return None
            return response.json()
        except (httpx.HTTPError, ValueError) as error:
            raise CatalogSearchError("PriceCharting catalog pricing request failed.") from error
        finally:
            if should_close:
                client.close()

    def _sales_from_row(
        self,
        row: dict[str, Any],
        recognition: RecognitionResult,
    ) -> list[MarketComparableSale]:
        product_name = str(row.get("product_name") or recognition.title)
        fields = [
            ("loose_price_cents", "Loose"),
            ("cib_price_cents", "Complete in Box"),
            ("new_price_cents", "New"),
            ("graded_price_cents", "Graded"),
        ]
        sales: list[MarketComparableSale] = []
        for key, condition in fields:
            price = _cents_to_units(row.get(key))
            if price is None:
                continue
            sales.append(
                MarketComparableSale(
                    source="PriceCharting",
                    title=f"{product_name} {condition}",
                    soldPrice=price,
                    currency=str(row.get("currency") or "USD").upper(),
                    soldDate=str(
                        row.get("source_downloaded_at")
                        or row.get("updated_at")
                        or utc_timestamp()
                    ),
                    condition=condition,
                    url=row.get("product_url"),
                )
            )
        return sales

    def _query_for(self, recognition: RecognitionResult) -> str:
        parts = [
            recognition.title,
            recognition.setName,
            recognition.cardNumber,
            recognition.series,
            recognition.brand,
            recognition.year,
        ]
        query = _normalize_query(
            " ".join(
                str(part).strip()
                for part in parts
                if isinstance(part, str) and part.strip()
            )
        )
        return query or _normalize_query(recognition.category or "collectible")

    def _cache_key(self, recognition: RecognitionResult, query: str) -> str:
        identity = "|".join(
            [
                self.provider_name,
                query,
                recognition.category,
                recognition.condition,
            ]
        )
        return " ".join(identity.lower().split())

    def _match_score(
        self,
        row: dict[str, Any],
        recognition: RecognitionResult,
        query: str,
    ) -> int:
        product = str(row.get("product_name") or "").lower()
        console = str(row.get("console_name") or "").lower()
        category = str(row.get("category") or "").lower()
        upc = str(row.get("upc") or "").lower()
        identity = str(row.get("normalized_identity") or "").lower()
        haystack = " ".join([product, console, category, upc, identity])
        score = 0
        if query and (query == product or query == upc):
            score += 110
        elif query and product.startswith(query):
            score += 92
        elif query and query in product:
            score += 78
        elif query and query in identity:
            score += 65
        elif query and (query in console or query in category):
            score += 45

        for value, weight in [
            (recognition.title, 18),
            (recognition.setName, 12),
            (recognition.cardNumber, 12),
            (recognition.series, 8),
            (recognition.brand, 6),
            (recognition.year, 5),
        ]:
            normalized = str(value or "").strip().lower()
            if normalized and normalized in haystack:
                score += weight
        return min(score, 130)

    def _confidence(
        self,
        recognition: RecognitionResult,
        match_score: int,
        comparable_sales: list[MarketComparableSale],
    ) -> int:
        recognition_score = max(20, min(90, recognition.confidence))
        match_component = min(32, round(match_score * 0.25))
        comp_component = min(12, len(comparable_sales) * 3)
        confidence = round((recognition_score * 0.55) + match_component + comp_component)
        return max(45, min(92, confidence))


def _cents_to_units(value: Any) -> int | None:
    try:
        if value is None:
            return None
        cents = int(value)
    except (TypeError, ValueError):
        return None
    if cents <= 0:
        return None
    return max(1, round(cents / 100))
