from __future__ import annotations

import json
import time
from dataclasses import dataclass, replace
from datetime import datetime, timezone
from typing import Any

from app.core.config import settings
from app.services.pricing.base_pricing_provider import MarketComparableSale, PricingResult


SUPPORTED_DISPLAY_CURRENCIES = {"AUD", "CAD", "GBP", "USD"}


@dataclass(frozen=True)
class CurrencyConversionResult:
    amount: int
    currency: str
    original_amount: int
    original_currency: str
    exchange_rate_used: float
    exchange_rate_date: str
    converted: bool
    reason: str


class CurrencyConversionCache:
    def __init__(
        self,
        *,
        target_currency: str = "AUD",
        rates_json: str = "",
        ttl_seconds: int = 12 * 60 * 60,
    ) -> None:
        self._target_currency = target_currency.strip().upper() or "AUD"
        self._ttl_seconds = ttl_seconds
        self._rates_json = rates_json
        self._cached_rates: dict[str, float] | None = None
        self._cached_at_monotonic: float = 0
        self._cached_at_iso: str = ""

    @property
    def target_currency(self) -> str:
        return self._target_currency

    def convert(self, amount: int, currency: str) -> CurrencyConversionResult:
        original_currency = (currency or self._target_currency).strip().upper()
        original_amount = max(0, int(round(float(amount or 0))))
        if original_amount <= 0:
            return self._result(
                amount=0,
                currency=original_currency,
                original_amount=original_amount,
                original_currency=original_currency,
                rate=1,
                converted=False,
                reason="zero_amount",
            )
        if original_currency == self._target_currency:
            return self._result(
                amount=original_amount,
                currency=original_currency,
                original_amount=original_amount,
                original_currency=original_currency,
                rate=1,
                converted=False,
                reason="already_target_currency",
            )

        rates = self._rates()
        key = f"{original_currency}_{self._target_currency}"
        rate = rates.get(key)
        if rate is None or rate <= 0:
            return self._result(
                amount=original_amount,
                currency=original_currency,
                original_amount=original_amount,
                original_currency=original_currency,
                rate=1,
                converted=False,
                reason=f"missing_rate_{key}",
            )

        return self._result(
            amount=max(1, round(original_amount * rate)),
            currency=self._target_currency,
            original_amount=original_amount,
            original_currency=original_currency,
            rate=rate,
            converted=True,
            reason="configured_rate",
        )

    def _rates(self) -> dict[str, float]:
        now = time.monotonic()
        if self._cached_rates is not None and now - self._cached_at_monotonic < self._ttl_seconds:
            return self._cached_rates
        parsed = _parse_rates(self._rates_json)
        self._cached_rates = parsed
        self._cached_at_monotonic = now
        self._cached_at_iso = _utc_timestamp()
        return parsed

    def _result(
        self,
        *,
        amount: int,
        currency: str,
        original_amount: int,
        original_currency: str,
        rate: float,
        converted: bool,
        reason: str,
    ) -> CurrencyConversionResult:
        return CurrencyConversionResult(
            amount=amount,
            currency=currency,
            original_amount=original_amount,
            original_currency=original_currency,
            exchange_rate_used=rate,
            exchange_rate_date=self._cached_at_iso or _utc_timestamp(),
            converted=converted,
            reason=reason,
        )


def normalize_display_currency(value: str | None) -> str:
    currency = (value or getattr(settings, "default_display_currency", "AUD") or "AUD").strip().upper()
    if currency in SUPPORTED_DISPLAY_CURRENCIES:
        return currency
    return "AUD"


def convert_pricing_result(
    pricing: PricingResult,
    *,
    target_currency: str,
) -> PricingResult:
    display_currency = normalize_display_currency(target_currency)
    source_currency = (pricing.currency or display_currency).strip().upper()
    rate = _exchange_rate(source_currency, display_currency)
    diagnostics = dict(pricing.providerDiagnostics)
    diagnostics.setdefault("originalPrice", str(pricing.estimatedMarketValue))
    diagnostics.setdefault("originalLowEstimate", str(pricing.lowEstimate))
    diagnostics.setdefault("originalHighEstimate", str(pricing.highEstimate))
    diagnostics.setdefault("originalCurrency", source_currency)
    diagnostics["exchangeRateUsed"] = str(rate)
    diagnostics["exchangeRateDate"] = pricing.lastUpdated
    diagnostics["displayCurrency"] = display_currency

    if pricing.valuationStatus != "market_estimated":
        return replace(
            pricing,
            currency=display_currency,
            originalCurrency=source_currency,
            exchangeRateUsed=rate,
            exchangeRateDate=pricing.lastUpdated,
            providerDiagnostics=diagnostics,
        )

    return replace(
        pricing,
        estimatedMarketValue=_convert_amount(pricing.estimatedMarketValue, rate),
        lowEstimate=_convert_amount(pricing.lowEstimate, rate),
        highEstimate=_convert_amount(pricing.highEstimate, rate),
        currency=display_currency,
        comparableSales=[
            _convert_sale(sale, target_currency=display_currency)
            for sale in pricing.comparableSales
        ],
        originalMarketValue=pricing.originalMarketValue or pricing.estimatedMarketValue,
        originalLowEstimate=pricing.originalLowEstimate or pricing.lowEstimate,
        originalHighEstimate=pricing.originalHighEstimate or pricing.highEstimate,
        originalCurrency=pricing.originalCurrency or source_currency,
        exchangeRateUsed=rate,
        exchangeRateDate=pricing.lastUpdated,
        providerDiagnostics=diagnostics,
    )


def _convert_sale(
    sale: MarketComparableSale,
    *,
    target_currency: str,
) -> MarketComparableSale:
    source_currency = (sale.currency or target_currency).strip().upper()
    rate = _exchange_rate(source_currency, target_currency)
    return replace(
        sale,
        soldPrice=_convert_amount(sale.soldPrice, rate),
        currency=target_currency,
    )


def _convert_amount(value: int, rate: float) -> int:
    if value <= 0:
        return 0
    return max(1, round(value * rate))


def _exchange_rate(source_currency: str, target_currency: str) -> float:
    source = normalize_display_currency(source_currency)
    target = normalize_display_currency(target_currency)
    if source == target:
        return 1
    usd_to_target = _usd_rate(target)
    usd_to_source = _usd_rate(source)
    return usd_to_target / usd_to_source


def _usd_rate(currency: str) -> float:
    normalized = normalize_display_currency(currency)
    if normalized == "AUD":
        return getattr(settings, "fx_usd_to_aud", 1.5)
    if normalized == "CAD":
        return getattr(settings, "fx_usd_to_cad", 1.35)
    if normalized == "GBP":
        return getattr(settings, "fx_usd_to_gbp", 0.8)
    return 1


def _parse_rates(raw_value: str) -> dict[str, float]:
    if not raw_value.strip():
        return {}
    try:
        payload: Any = json.loads(raw_value)
    except ValueError:
        return {}
    if not isinstance(payload, dict):
        return {}

    rates: dict[str, float] = {}
    for key, value in payload.items():
        try:
            rate = float(value)
        except (TypeError, ValueError):
            continue
        normalized_key = str(key).strip().upper().replace(":", "_").replace("/", "_")
        if normalized_key and rate > 0:
            rates[normalized_key] = rate
    return rates


def _utc_timestamp() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace(
        "+00:00",
        "Z",
    )
