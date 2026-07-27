from __future__ import annotations

import json
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any


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
        self._cached_at_iso = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace(
            "+00:00",
            "Z",
        )
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
            exchange_rate_date=self._cached_at_iso
            or datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace(
                "+00:00",
                "Z",
            ),
            converted=converted,
            reason=reason,
        )


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
