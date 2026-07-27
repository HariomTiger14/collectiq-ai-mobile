from __future__ import annotations

import time
from dataclasses import dataclass, replace
from enum import Enum

from app.services.ai.base_recognition_service import RecognitionResult
from app.services.pricing.aggregation_service import PricingAggregationService
from app.services.pricing.base_pricing_provider import (
    EmptyMarketDataError,
    PricingProvider,
    PricingProviderError,
    PricingProviderRateLimitError,
    PricingProviderTimeoutError,
    PricingProviderUnavailableError,
    PricingResult,
    utc_timestamp,
)
from app.services.pricing.currency_conversion import CurrencyConversionCache


class PricingProviderKey(str, Enum):
    PRICECHARTING_CATALOG = "pricecharting_catalog"
    PRICECHARTING_API = "pricecharting"
    EBAY = "ebay"
    TCGPLAYER = "tcgplayer"
    KICKSDB = "kicksdb"
    WATCHCHARTS = "watchcharts"


@dataclass(frozen=True)
class ProviderRegistration:
    key: PricingProviderKey
    provider: PricingProvider | None
    display_name: str
    attribution_text: str
    configured: bool
    minimum_comps: int
    valuation_strategy: str
    planned: bool = False


@dataclass(frozen=True)
class PricingRoute:
    category_key: str
    provider_keys: tuple[PricingProviderKey, ...]
    reason: str


class MultiProviderPricingEngine(PricingProvider):
    provider_name = "multi_provider_engine"

    def __init__(
        self,
        *,
        registry: dict[PricingProviderKey, ProviderRegistration],
        minimum_confidence: int = 45,
        currency_converter: CurrencyConversionCache | None = None,
    ) -> None:
        self._registry = registry
        self._minimum_confidence = minimum_confidence
        self._currency_converter = currency_converter or CurrencyConversionCache()

    def price(self, recognition: RecognitionResult) -> PricingResult:
        started_at = time.perf_counter()
        route = route_for_recognition(recognition)
        selected: list[ProviderRegistration] = []
        skipped: list[str] = []

        for key in route.provider_keys:
            registration = self._registry.get(key)
            if registration is None:
                skipped.append(f"{key.value}: not_registered")
                continue
            if registration.planned:
                skipped.append(f"{key.value}: planned_not_connected")
                continue
            if not registration.configured or registration.provider is None:
                skipped.append(f"{key.value}: not_configured")
                continue
            selected.append(registration)

        if not selected:
            return unavailable_pricing_result(
                recognition,
                reason_code="PROVIDER_NOT_CONFIGURED",
                message=(
                    "No trusted pricing provider is connected for this category yet."
                ),
                route=route,
                skipped=skipped,
                response_time_ms=_elapsed_ms(started_at),
            )

        try:
            aggregate = PricingAggregationService(
                [registration.provider for registration in selected if registration.provider]
            ).price(recognition)
        except EmptyMarketDataError as exc:
            return unavailable_pricing_result(
                recognition,
                reason_code="NO_MARKET_MATCH",
                message=str(exc),
                route=route,
                skipped=skipped,
                selected=selected,
                response_time_ms=_elapsed_ms(started_at),
            )
        except (PricingProviderTimeoutError, PricingProviderRateLimitError) as exc:
            raise exc
        except (PricingProviderUnavailableError, PricingProviderError, ValueError) as exc:
            return unavailable_pricing_result(
                recognition,
                reason_code="LOOKUP_FAILED",
                message=str(exc),
                route=route,
                skipped=skipped,
                selected=selected,
                response_time_ms=_elapsed_ms(started_at),
            )

        evidence = _evidence_rule(selected, aggregate)
        if evidence is not None:
            return unavailable_pricing_result(
                recognition,
                reason_code=evidence[0],
                message=evidence[1],
                route=route,
                skipped=skipped,
                selected=selected,
                response_time_ms=_elapsed_ms(started_at),
            )

        if aggregate.pricingConfidence < self._minimum_confidence:
            return unavailable_pricing_result(
                recognition,
                reason_code="LOW_PRICING_CONFIDENCE",
                message=(
                    "Pricing confidence is below PackLox's trusted valuation threshold."
                ),
                route=route,
                skipped=skipped,
                selected=selected,
                response_time_ms=_elapsed_ms(started_at),
            )

        converted = _convert_pricing(aggregate, self._currency_converter)
        return _with_engine_diagnostics(
            converted,
            route=route,
            selected=selected,
            skipped=skipped,
            response_time_ms=_elapsed_ms(started_at),
        )


def route_for_recognition(recognition: RecognitionResult) -> PricingRoute:
    text = _recognition_text(recognition)
    if any(value in text for value in ["pokemon", "pokémon"]):
        return PricingRoute(
            category_key="pokemon_cards",
            provider_keys=(
                PricingProviderKey.PRICECHARTING_CATALOG,
                PricingProviderKey.TCGPLAYER,
                PricingProviderKey.EBAY,
            ),
            reason="Pokemon card pricing is routed to catalog data first, then card marketplaces and sold comps.",
        )
    if any(value in text for value in ["magic", "mtg", "yugioh", "yu-gi-oh", "one piece"]):
        return PricingRoute(
            category_key="trading_cards",
            provider_keys=(
                PricingProviderKey.PRICECHARTING_CATALOG,
                PricingProviderKey.TCGPLAYER,
                PricingProviderKey.EBAY,
            ),
            reason="Trading cards are routed to catalog data first, then specialist card pricing.",
        )
    if any(
        value in text
        for value in ["video game", "game cartridge", "nintendo", "playstation", "xbox"]
    ):
        return PricingRoute(
            category_key="video_games",
            provider_keys=(
                PricingProviderKey.PRICECHARTING_CATALOG,
                PricingProviderKey.PRICECHARTING_API,
                PricingProviderKey.EBAY,
            ),
            reason="Video games are routed to PriceCharting catalog and guide data first.",
        )
    if any(value in text for value in ["sneaker", "shoe", "nike", "adidas", "jordan"]):
        return PricingRoute(
            category_key="sneakers",
            provider_keys=(PricingProviderKey.KICKSDB, PricingProviderKey.EBAY),
            reason="Sneakers require specialist marketplace data, then sold-comps fallback.",
        )
    if any(value in text for value in ["watch", "rolex", "omega", "jewelry", "jewellery"]):
        return PricingRoute(
            category_key="specialist_luxury",
            provider_keys=(PricingProviderKey.WATCHCHARTS,),
            reason="Luxury categories need specialist valuation sources before PackLox shows a value.",
        )
    return PricingRoute(
        category_key="general_collectibles",
        provider_keys=(PricingProviderKey.EBAY, PricingProviderKey.PRICECHARTING_CATALOG),
        reason="General collectibles require sold-comps first, then catalog guide data where available.",
    )


def unavailable_pricing_result(
    recognition: RecognitionResult,
    *,
    reason_code: str,
    message: str,
    route: PricingRoute,
    skipped: list[str] | None = None,
    selected: list[ProviderRegistration] | None = None,
    response_time_ms: int = 0,
) -> PricingResult:
    providers = selected or []
    skipped_providers = skipped or []
    source = _source_label(providers) or route.category_key
    return PricingResult(
        estimatedMarketValue=0,
        lowEstimate=0,
        highEstimate=0,
        currency="AUD",
        pricingSource=source,
        pricingConfidence=0,
        lastUpdated=utc_timestamp(),
        valuationStatus="unavailable",
        valuationSource=source,
        aiEstimatedValue=recognition.estimatedValue
        if recognition.estimatedValue > 0
        else None,
        marketTrend="Unknown",
        sourceCount=len(providers),
        pricingAge="unavailable",
        comparableSales=[],
        fallbackUsed=False,
        cacheStatus="unavailable",
        providerDiagnostics={
            "providerCount": str(len(providers)),
            "providers": source,
            "providerRegistry": ", ".join(reg.key.value for reg in providers),
            "providerRoute": route.category_key,
            "providerRouteReason": route.reason,
            "providersSkipped": " | ".join(skipped_providers),
            "fallbackUsed": "false",
            "fallbackReason": message,
            "reasonCode": reason_code,
            "cacheStatus": "unavailable",
            "responseTimeMs": str(response_time_ms),
            "comparableCount": "0",
            "confidenceCalculation": message,
            "priceExplanation": message,
            "valuationStrategy": "unavailable",
            "attributionText": "",
            "minimumSoldCompsRule": _minimum_rule_label(providers),
            "currencyConversion": "not_applied",
        },
    )


def _with_engine_diagnostics(
    pricing: PricingResult,
    *,
    route: PricingRoute,
    selected: list[ProviderRegistration],
    skipped: list[str],
    response_time_ms: int,
) -> PricingResult:
    attribution = " + ".join(reg.attribution_text for reg in selected if reg.attribution_text)
    diagnostics = {
        **pricing.providerDiagnostics,
        "providerRoute": route.category_key,
        "providerRouteReason": route.reason,
        "providerRegistry": ", ".join(reg.key.value for reg in selected),
        "providersSkipped": " | ".join(skipped),
        "providerCount": str(len(selected)),
        "providers": _source_label(selected) or pricing.valuationSource,
        "responseTimeMs": str(response_time_ms),
        "valuationStrategy": selected[0].valuation_strategy
        if selected
        else "sold_completed",
        "attributionText": attribution,
        "minimumSoldCompsRule": _minimum_rule_label(selected),
        "currencyConversion": pricing.providerDiagnostics.get(
            "currencyConversion",
            "not_applied",
        ),
    }
    return PricingResult(
        **{
            **pricing.__dict__,
            "providerDiagnostics": diagnostics,
            "valuationSource": _source_label(selected) or pricing.valuationSource,
        }
    )


def _convert_pricing(
    pricing: PricingResult,
    converter: CurrencyConversionCache,
) -> PricingResult:
    value = converter.convert(pricing.estimatedMarketValue, pricing.currency)
    low = converter.convert(pricing.lowEstimate, pricing.currency)
    high = converter.convert(pricing.highEstimate, pricing.currency)
    if not value.converted:
        return replace(
            pricing,
            providerDiagnostics={
                **pricing.providerDiagnostics,
                "originalPrice": str(value.original_amount),
                "originalCurrency": value.original_currency,
                "exchangeRateUsed": str(value.exchange_rate_used),
                "exchangeRateDate": value.exchange_rate_date,
                "currencyConversion": value.reason,
                "targetCurrency": converter.target_currency,
            },
        )
    return replace(
        pricing,
        estimatedMarketValue=value.amount,
        lowEstimate=low.amount,
        highEstimate=high.amount,
        currency=value.currency,
        providerDiagnostics={
            **pricing.providerDiagnostics,
            "originalPrice": str(value.original_amount),
            "originalCurrency": value.original_currency,
            "exchangeRateUsed": str(value.exchange_rate_used),
            "exchangeRateDate": value.exchange_rate_date,
            "currencyConversion": value.reason,
            "targetCurrency": converter.target_currency,
        },
    )


def _evidence_rule(
    selected: list[ProviderRegistration],
    pricing: PricingResult,
) -> tuple[str, str] | None:
    comparable_count = len(pricing.comparableSales)
    for registration in selected:
        if comparable_count < registration.minimum_comps:
            return (
                "INSUFFICIENT_TRUSTED_MARKET_DATA",
                (
                    f"{registration.display_name} returned {comparable_count} usable "
                    f"comps; PackLox requires at least {registration.minimum_comps}."
                ),
            )
    return None


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


def _source_label(registrations: list[ProviderRegistration]) -> str:
    return ", ".join(reg.display_name for reg in registrations if reg.display_name)


def _minimum_rule_label(registrations: list[ProviderRegistration]) -> str:
    if not registrations:
        return ""
    return ", ".join(
        f"{reg.display_name}: {reg.minimum_comps}" for reg in registrations
    )


def _elapsed_ms(started_at: float) -> int:
    return int((time.perf_counter() - started_at) * 1000)
