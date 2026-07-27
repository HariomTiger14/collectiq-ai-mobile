import logging
import math
import re
import statistics
import time
from dataclasses import replace
from urllib.parse import urlparse

import httpx

from app.services.ai.base_recognition_service import RecognitionResult
from app.services.pricing.base_pricing_provider import (
    EmptyMarketDataError,
    MarketComparableSale,
    PricingProvider,
    PricingProviderError,
    PricingProviderRateLimitError,
    PricingProviderTimeoutError,
    PricingProviderUnavailableError,
    PricingResult,
    utc_timestamp,
)
from app.services.pricing.cache import InMemoryPricingCache, ProviderThrottle


logger = logging.getLogger("collectiq.pricing.ebay")


class EbayPricingProvider(PricingProvider):
    provider_name = "ebay"

    def __init__(
        self,
        *,
        access_token: str,
        sold_comps_api_url: str = "",
        browse_api_url: str = "",
        marketplace_id: str,
        timeout_seconds: float,
        cache_ttl_seconds: int,
        min_interval_ms: int,
        min_sold_comps: int = 3,
        title_similarity_threshold: float = 0.45,
        outlier_trim_ratio: float = 0.10,
        client=None,
        cache: InMemoryPricingCache | None = None,
        throttle: ProviderThrottle | None = None,
    ) -> None:
        self._access_token = access_token.strip()
        self._sold_comps_api_url = sold_comps_api_url.strip()
        self._browse_api_url = browse_api_url.strip()
        self._marketplace_id = marketplace_id.strip() or "EBAY_AU"
        self._timeout_seconds = timeout_seconds
        self._min_sold_comps = max(1, min_sold_comps)
        self._title_similarity_threshold = max(
            0.0,
            min(1.0, title_similarity_threshold),
        )
        self._outlier_trim_ratio = max(0.0, min(0.45, outlier_trim_ratio))
        self._client = client
        self._cache = cache or InMemoryPricingCache(cache_ttl_seconds)
        self._throttle = throttle or ProviderThrottle(min_interval_ms)

    @property
    def is_configured(self) -> bool:
        return bool(self._access_token) and self._is_valid_url(self._sold_comps_api_url)

    def price(self, recognition: RecognitionResult) -> PricingResult:
        if not self._access_token:
            raise PricingProviderUnavailableError(
                "EBAY_ACCESS_TOKEN is not configured on the backend."
            )
        if not self._is_valid_url(self._sold_comps_api_url):
            raise PricingProviderUnavailableError(
                "EBAY_SOLD_COMPS_API_URL is not configured. PackLox does not "
                "use active eBay Browse listings as valuation evidence."
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

        self._throttle.acquire(self.provider_name)
        started_at = time.perf_counter()
        response = self._request(query)
        latency_ms = int((time.perf_counter() - started_at) * 1000)
        result = self._parse_response(
            recognition=recognition,
            payload=response,
            latency_ms=latency_ms,
        )
        self._cache.set(cache_key, result)
        return result

    def _request(self, query: str) -> dict:
        headers = {
            "Authorization": f"Bearer {self._access_token}",
            "Accept": "application/json",
            "X-EBAY-C-MARKETPLACE-ID": self._marketplace_id,
        }
        params = {
            "q": query,
            "limit": "50",
            "sold_only": "true",
            "completed_only": "true",
        }

        try:
            if self._client is not None:
                response = self._client.get(
                    self._sold_comps_api_url,
                    headers=headers,
                    params=params,
                    timeout=self._timeout_seconds,
                )
            else:
                with httpx.Client(timeout=self._timeout_seconds) as client:
                    response = client.get(
                        self._sold_comps_api_url,
                        headers=headers,
                        params=params,
                    )
        except httpx.TimeoutException as exc:
            raise PricingProviderTimeoutError("eBay pricing request timed out.") from exc
        except httpx.RequestError as exc:
            raise PricingProviderUnavailableError(
                "eBay pricing request failed before receiving a response."
            ) from exc

        status_code = getattr(response, "status_code", 0)
        if status_code == 429:
            raise PricingProviderRateLimitError("eBay pricing rate limit reached.")
        if status_code >= 500:
            raise PricingProviderUnavailableError(
                f"eBay pricing service returned HTTP {status_code}."
            )
        if status_code >= 400:
            raise PricingProviderError(
                f"eBay pricing request failed with HTTP {status_code}."
            )

        try:
            payload = response.json()
        except ValueError as exc:
            raise PricingProviderError("eBay pricing response was not valid JSON.") from exc
        if not isinstance(payload, dict):
            raise PricingProviderError("eBay pricing response shape was invalid.")
        return payload

    def _parse_response(
        self,
        *,
        recognition: RecognitionResult,
        payload: dict,
        latency_ms: int,
    ) -> PricingResult:
        items = payload.get("itemSummaries") or payload.get("items") or []
        if not isinstance(items, list) or not items:
            raise EmptyMarketDataError("eBay returned no pricing results.")

        comparable_sales: list[MarketComparableSale] = []
        rejected = {
            "not_sold": 0,
            "price": 0,
            "title": 0,
            "category": 0,
            "condition": 0,
        }
        for item in items:
            if not isinstance(item, dict):
                continue
            sale, reason = self._sale_from_item(item, recognition)
            if sale is not None:
                comparable_sales.append(sale)
            elif reason:
                rejected[reason] = rejected.get(reason, 0) + 1

        if not comparable_sales:
            raise EmptyMarketDataError(
                "eBay returned no usable sold-comps after PackLox trust filters."
            )

        comparable_sales = self._trim_outliers(comparable_sales)

        if len(comparable_sales) < self._min_sold_comps:
            raise EmptyMarketDataError(
                f"eBay returned {len(comparable_sales)} trusted sold comps; "
                f"PackLox requires at least {self._min_sold_comps}."
            )

        prices = [sale.soldPrice for sale in comparable_sales]
        estimated_value = round(statistics.median(prices))
        low_estimate = min(prices)
        high_estimate = max(prices)
        confidence = self._confidence(recognition, len(comparable_sales))

        return PricingResult(
            estimatedMarketValue=max(1, estimated_value),
            lowEstimate=max(1, low_estimate),
            highEstimate=max(1, high_estimate),
            currency=comparable_sales[0].currency,
            pricingSource="eBay sold listings",
            pricingConfidence=confidence,
            lastUpdated=utc_timestamp(),
            marketTrend=self._trend(comparable_sales),
            sourceCount=1,
            pricingAge="live",
            comparableSales=comparable_sales,
            cacheStatus="miss",
            providerDiagnostics={
                "provider": self.provider_name,
                "cacheStatus": "miss",
                "responseLatencyMs": str(latency_ms),
                "pricingFreshness": "live",
                "fallbackReason": "",
                "resultCount": str(len(comparable_sales)),
                "rawResultCount": str(len(items)),
                "rejectedNotSold": str(rejected.get("not_sold", 0)),
                "rejectedPrice": str(rejected.get("price", 0)),
                "rejectedTitle": str(rejected.get("title", 0)),
                "rejectedCategory": str(rejected.get("category", 0)),
                "rejectedCondition": str(rejected.get("condition", 0)),
                "minimumSoldCompsRequired": str(self._min_sold_comps),
                "valuationStrategy": "sold_completed",
                "attributionText": "Pricing source: eBay sold listings",
                "confidenceCalculation": (
                    "Median of trusted sold listings after title, category, "
                    "condition and outlier filters."
                ),
            },
        )

    def _sale_from_item(
        self,
        item: dict,
        recognition: RecognitionResult,
    ) -> tuple[MarketComparableSale | None, str]:
        if not self._is_sold_listing(item):
            return None, "not_sold"

        price_payload = item.get("price") or item.get("currentBidPrice") or {}
        if not isinstance(price_payload, dict):
            return None, "price"
        try:
            price = round(float(price_payload.get("value")))
        except (TypeError, ValueError):
            return None, "price"
        if price <= 0:
            return None, "price"

        title = str(item.get("title") or "")
        condition = str(item.get("condition") or "")
        if not self._title_is_relevant(title, recognition):
            return None, "title"
        if not self._category_is_relevant(item, recognition):
            return None, "category"
        if not self._condition_is_compatible(title, condition, recognition):
            return None, "condition"

        sold_date = self._sold_date(item)
        currency = str(price_payload.get("currency") or "AUD").upper()
        return (
            MarketComparableSale(
                source="eBay sold listings",
                title=title or recognition.title,
                soldPrice=price,
                currency=currency,
                soldDate=sold_date or utc_timestamp(),
                condition=condition or recognition.condition or "Unknown",
                url=item.get("itemWebUrl"),
            ),
            "",
        )

    def _query_for(self, recognition: RecognitionResult) -> str:
        parts = [
            recognition.title,
            recognition.brand,
            recognition.setName,
            recognition.series,
            recognition.cardNumber,
            recognition.year,
            recognition.edition,
            recognition.language,
            recognition.condition,
        ]
        query = " ".join(
            str(part).strip()
            for part in parts
            if isinstance(part, str) and part.strip()
        )
        return query or recognition.category or "collectible"

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

    def _confidence(self, recognition: RecognitionResult, comparable_count: int) -> int:
        comp_bonus = min(24, comparable_count * 3)
        base = min(78, max(42, round(recognition.confidence * 0.70)))
        return max(45, min(90, base + comp_bonus))

    def _trend(self, comparable_sales: list[MarketComparableSale]) -> str:
        if len(comparable_sales) < 3:
            return "Stable"
        ordered = sorted(comparable_sales, key=lambda sale: sale.soldDate)
        first = ordered[0].soldPrice
        last = ordered[-1].soldPrice
        if last >= first * 1.08:
            return "Rising"
        if last <= first * 0.92:
            return "Cooling"
        return "Stable"

    def _is_valid_url(self, value: str) -> bool:
        parsed = urlparse(value)
        return parsed.scheme in {"http", "https"} and bool(parsed.netloc)

    def _is_sold_listing(self, item: dict) -> bool:
        if self._sold_date(item):
            return True
        status = " ".join(
            str(item.get(key) or "")
            for key in [
                "itemStatus",
                "listingStatus",
                "status",
                "listing_state",
                "saleStatus",
            ]
        ).lower()
        return any(value in status for value in ["sold", "completed", "ended"])

    def _sold_date(self, item: dict) -> str:
        for key in [
            "soldDate",
            "itemEndDate",
            "endDate",
            "transactionDate",
            "lastSoldDate",
            "dateSold",
        ]:
            value = item.get(key)
            if value:
                return str(value)
        return ""

    def _title_is_relevant(
        self,
        title: str,
        recognition: RecognitionResult,
    ) -> bool:
        query_tokens = self._identity_tokens(recognition)
        if not query_tokens:
            return True
        title_tokens = _tokens(title)
        if not title_tokens:
            return False
        hard_identity = _tokens(str(recognition.brand or ""))
        if hard_identity and not hard_identity.intersection(title_tokens):
            return False
        overlap = len(query_tokens.intersection(title_tokens))
        ratio = overlap / max(1, min(len(query_tokens), len(title_tokens)))
        return ratio >= self._title_similarity_threshold

    def _category_is_relevant(self, item: dict, recognition: RecognitionResult) -> bool:
        category_text = " ".join(
            str(value or "")
            for value in [
                item.get("category"),
                item.get("categoryName"),
                item.get("leafCategoryIds"),
                item.get("categories"),
            ]
        ).lower()
        recognition_category = str(recognition.category or "").lower()
        recognition_text = self._query_for(recognition).lower()

        if not category_text:
            return True
        if any(value in recognition_text for value in ["hot wheels", "diecast"]):
            return any(value in category_text for value in ["toy", "diecast", "vehicle"])
        if any(
            value in recognition_text
            for value in ["pokemon", "pokémon", "mtg", "magic", "yugioh", "one piece"]
        ):
            return any(value in category_text for value in ["card", "collectible"])
        category_tokens = _tokens(recognition_category)
        if not category_tokens:
            return True
        return bool(category_tokens.intersection(_tokens(category_text)))

    def _condition_is_compatible(
        self,
        title: str,
        condition: str,
        recognition: RecognitionResult,
    ) -> bool:
        target = str(recognition.condition or "").lower()
        if not target:
            return True
        candidate = f"{title} {condition}".lower()
        if any(value in target for value in ["psa", "bgs", "cgc", "graded", "grade"]):
            return any(value in candidate for value in ["psa", "bgs", "cgc", "graded"])
        damaged_terms = {"damaged", "poor", "played", "heavily"}
        if damaged_terms.intersection(_tokens(candidate)):
            return any(value in target for value in damaged_terms)
        return True

    def _trim_outliers(
        self,
        comparable_sales: list[MarketComparableSale],
    ) -> list[MarketComparableSale]:
        if len(comparable_sales) < 10 or self._outlier_trim_ratio <= 0:
            return comparable_sales
        ordered = sorted(comparable_sales, key=lambda sale: sale.soldPrice)
        trim_count = math.floor(len(ordered) * self._outlier_trim_ratio)
        if trim_count <= 0:
            return ordered
        trimmed = ordered[trim_count:-trim_count]
        return trimmed or ordered

    def _identity_tokens(self, recognition: RecognitionResult) -> set[str]:
        values = [
            recognition.title,
            recognition.brand,
            recognition.setName,
            recognition.series,
            recognition.cardNumber,
            recognition.playerOrCharacter,
            recognition.year,
            recognition.edition,
        ]
        return _tokens(" ".join(str(value) for value in values if value))


def _tokens(value: str) -> set[str]:
    stopwords = {
        "a",
        "an",
        "and",
        "card",
        "cards",
        "collectible",
        "for",
        "in",
        "new",
        "of",
        "the",
        "with",
    }
    return {
        token
        for token in re.findall(r"[a-z0-9]+", value.lower())
        if len(token) > 1 and token not in stopwords
    }
