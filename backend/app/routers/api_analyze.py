import logging
import statistics
import time
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, HTTPException, status

from app.core.config import ALLOWED_CONTENT_TYPES, ALLOWED_EXTENSIONS, MAX_IMAGE_BYTES
from app.schemas.api_analysis import (
    ApiAlternativeMatchResponse,
    ApiAnalyzeRequest,
    ApiAnalyzeResponse,
    ApiMarketCompResponse,
    ApiMarketSummaryResponse,
    ApiReviewResponse,
)
from app.services.ai.openai_recognition_provider import (
    AIProviderNotConfiguredError,
    OpenAIInvalidResponseError,
    OpenAIProviderError,
    OpenAITimeoutError,
)
from app.services.ai.provider_factory import get_ai_recognition_provider
from app.services.pricing.base_pricing_provider import (
    EmptyMarketDataError,
    PricingProviderError,
    PricingProviderRateLimitError,
    PricingProviderTimeoutError,
    PricingProviderUnavailableError,
)
from app.services.pricing.provider_factory import get_pricing_provider


router = APIRouter(prefix="/api", tags=["Analyze API"])
logger = logging.getLogger("collectiq.api.analyze")

SUPPORTED_CATEGORIES = {
    "pokemon",
    "pokemon card",
    "tcg",
    "tcg card",
    "trading card",
    "sports card",
    "coin",
    "comic",
    "memorabilia",
    "toy",
    "figure",
    "other",
}


@router.post(
    "/analyze",
    response_model=ApiAnalyzeResponse,
    summary="Analyze a collectible image from the Flutter backend contract",
)
async def analyze_collectible(payload: ApiAnalyzeRequest) -> ApiAnalyzeResponse:
    _validate_contract(payload)
    started_at = time.perf_counter()

    try:
        provider = get_ai_recognition_provider()
        if hasattr(provider, "recognize_api_payload"):
            recognition = provider.recognize_api_payload(
                request_metadata=_model_to_dict(payload.request),
                image_payload=_model_to_dict(payload.image),
            )
        else:
            recognition = provider.recognize(Path(payload.image.localFilePath))
        pricing = get_pricing_provider().price(recognition)
    except AIProviderNotConfiguredError as exc:
        raise _api_error(
            status.HTTP_501_NOT_IMPLEMENTED,
            "ai_provider_not_configured",
            str(exc),
            retryable=False,
        ) from exc
    except OpenAITimeoutError as exc:
        raise _api_error(
            status.HTTP_504_GATEWAY_TIMEOUT,
            "ai_provider_timeout",
            str(exc),
            retryable=True,
        ) from exc
    except OpenAIInvalidResponseError as exc:
        raise _api_error(
            status.HTTP_502_BAD_GATEWAY,
            "ai_provider_invalid_response",
            str(exc),
            retryable=True,
        ) from exc
    except OpenAIProviderError as exc:
        raise _api_error(
            status.HTTP_502_BAD_GATEWAY,
            "ai_provider_error",
            str(exc),
            retryable=True,
        ) from exc
    except PricingProviderTimeoutError as exc:
        raise _api_error(
            status.HTTP_504_GATEWAY_TIMEOUT,
            "pricing_provider_timeout",
            str(exc),
            retryable=True,
        ) from exc
    except PricingProviderRateLimitError as exc:
        raise _api_error(
            status.HTTP_429_TOO_MANY_REQUESTS,
            "pricing_provider_rate_limited",
            str(exc),
            retryable=True,
        ) from exc
    except PricingProviderUnavailableError as exc:
        raise _api_error(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "pricing_provider_unavailable",
            str(exc),
            retryable=True,
        ) from exc
    except EmptyMarketDataError as exc:
        raise _api_error(
            status.HTTP_502_BAD_GATEWAY,
            "pricing_provider_empty_market_data",
            str(exc),
            retryable=True,
        ) from exc
    except PricingProviderError as exc:
        raise _api_error(
            status.HTTP_502_BAD_GATEWAY,
            "pricing_provider_error",
            str(exc),
            retryable=True,
        ) from exc
    except ValueError as exc:
        raise _api_error(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            "unsupported_ai_provider",
            str(exc),
            retryable=False,
        ) from exc
    except HTTPException:
        raise
    except Exception as exc:
        raise _api_error(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            "server_error",
            "Unable to analyze collectible right now.",
            retryable=True,
        ) from exc

    comparable_sales = _comparable_sales_from_pricing(pricing)

    market_summary = ApiMarketSummaryResponse(
        averagePrice=_average_price(comparable_sales, pricing.estimatedMarketValue),
        medianPrice=_median_price(comparable_sales, pricing.estimatedMarketValue),
        lowPrice=pricing.lowEstimate,
        highPrice=pricing.highEstimate,
        salesCount=len(comparable_sales),
        trendLabel=pricing.marketTrend,
        confidence=pricing.pricingConfidence,
        lastUpdated=pricing.lastUpdated,
        sources=_market_sources(pricing),
        comps=comparable_sales,
    )

    total_processing_time_ms = int((time.perf_counter() - started_at) * 1000)
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug(
            "Analyze completed provider=%s model=%s latencyMs=%s "
            "overallProcessingTimeMs=%s pricingProvider=%s pricingResponseTimeMs=%s "
            "pricingProviderCount=%s pricingFallbackUsed=%s pricingCacheStatus=%s "
            "pricingFreshness=%s pricingFallbackReason=%s",
            getattr(provider, "provider_name", "unknown"),
            getattr(provider, "_model", "mock"),
            getattr(recognition, "processingTimeMs", total_processing_time_ms),
            total_processing_time_ms,
            pricing.providerDiagnostics.get("providers", pricing.pricingSource),
            pricing.providerDiagnostics.get("responseTimeMs", "0"),
            pricing.providerDiagnostics.get("providerCount", str(pricing.sourceCount)),
            pricing.fallbackUsed,
            pricing.cacheStatus,
            pricing.pricingAge,
            pricing.providerDiagnostics.get("fallbackReason", ""),
        )

    return ApiAnalyzeResponse(
        id=f"backend-{uuid4()}",
        itemName=recognition.title,
        category=recognition.category,
        estimatedValue=pricing.estimatedMarketValue,
        lowEstimate=pricing.lowEstimate,
        highEstimate=pricing.highEstimate,
        confidence=recognition.confidence,
        condition=recognition.condition,
        marketTrend=pricing.marketTrend,
        keyAttributes=_key_attributes(recognition),
        aiReview=ApiReviewResponse(
            primaryMatch=recognition.primaryMatch,
            confidenceExplanation=recognition.confidenceExplanation,
            detectionQuality=recognition.detectionQuality,
            reasoning=recognition.aiReasoning,
        ),
        alternatives=[
            ApiAlternativeMatchResponse(
                title=match.title,
                category=match.category,
                confidence=match.confidence,
                reason=match.reason,
            )
            for match in recognition.alternativeMatches
        ],
        recommendation=recognition.recommendation,
        marketSummary=market_summary,
        comparableSales=comparable_sales,
        imageUrl=None,
        timestamp=payload.request.timestamp,
        fieldConfidence=_field_confidence(recognition),
        confidenceLevel=_confidence_level(recognition.confidence),
        lowConfidenceReasons=(
            recognition.lowConfidenceReasons
            or _low_confidence_reasons(recognition.confidence, recognition.detectionQuality)
        ),
        imageQualityIssues=(
            recognition.imageQualityIssues
            or _image_quality_issues(recognition.detectionQuality)
        ),
        scanRecommendations=(
            recognition.scanRecommendations
            or _scan_recommendations(recognition.confidence, recognition.detectionQuality)
        ),
    )


def _validate_contract(payload: ApiAnalyzeRequest) -> None:
    request = payload.request
    image = payload.image

    if not request.imagePath.strip() or not image.localFilePath.strip():
        raise _api_error(
            status.HTTP_400_BAD_REQUEST,
            "missing_image",
            "Image metadata is required.",
            retryable=False,
        )

    extension = Path(image.fileName).suffix.lower()
    if (
        extension not in ALLOWED_EXTENSIONS
        or image.mimeType not in ALLOWED_CONTENT_TYPES
        or image.sizeBytes <= 0
        or image.sizeBytes > MAX_IMAGE_BYTES
    ):
        raise _api_error(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            "invalid_payload",
            "Image payload is invalid or unsupported.",
            retryable=False,
            details={
                "supportedExtensions": sorted(ALLOWED_EXTENSIONS),
                "supportedMimeTypes": sorted(ALLOWED_CONTENT_TYPES),
                "maxImageBytes": MAX_IMAGE_BYTES,
            },
        )

    requested_category = (request.requestedCategory or "").strip().lower()
    if requested_category and requested_category not in SUPPORTED_CATEGORIES:
        raise _api_error(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            "unsupported_category",
            "Requested category is not supported for v1 analysis.",
            retryable=False,
            details={"requestedCategory": request.requestedCategory},
        )


def _model_to_dict(model) -> dict:
    if hasattr(model, "model_dump"):
        return model.model_dump()
    return model.dict()


def _api_error(
    status_code: int,
    code: str,
    message: str,
    *,
    retryable: bool,
    details: dict | None = None,
) -> HTTPException:
    return HTTPException(
        status_code=status_code,
        detail={
            "code": code,
            "message": message,
            "retryable": retryable,
            "details": details or {},
        },
    )


def _key_attributes(recognition) -> dict[str, str]:
    attributes = {
        "year": recognition.year,
        "brand": recognition.brand,
        "setName": recognition.setName,
        "series": recognition.series,
        "cardNumber": recognition.cardNumber,
        "playerOrCharacter": recognition.playerOrCharacter,
        "rarity": recognition.rarity,
        "estimatedGrade": recognition.estimatedGrade,
        "language": recognition.language,
        "edition": recognition.edition,
        "country": recognition.country,
        "mint": recognition.mint,
        "material": recognition.material,
        "notes": recognition.notes,
    }
    return {
        key: value.strip()
        for key, value in attributes.items()
        if isinstance(value, str) and value.strip()
    }


def _field_confidence(recognition) -> dict[str, int]:
    if recognition.fieldConfidence:
        return {
            key: _clamp_confidence(value)
            for key, value in recognition.fieldConfidence.items()
        }

    return {
        "itemName": _clamp_confidence(recognition.confidence),
        "category": _clamp_confidence(recognition.confidence),
        "brand": _clamp_confidence(recognition.confidence - 5),
        "setName": _clamp_confidence(recognition.confidence - 10),
        "year": _clamp_confidence(recognition.confidence - 12),
        "cardNumber": _clamp_confidence(recognition.confidence - 15),
        "condition": _clamp_confidence(recognition.confidence - 20),
        "estimatedGrade": _clamp_confidence(recognition.confidence - 25),
        "language": _clamp_confidence(recognition.confidence - 20),
        "edition": _clamp_confidence(recognition.confidence - 20),
    }


def _confidence_level(confidence: int) -> str:
    if confidence >= 90:
        return "High"
    if confidence >= 70:
        return "Medium"
    return "Low"


def _low_confidence_reasons(confidence: int, detection_quality: str) -> list[str]:
    reasons: list[str] = []
    if confidence < 90:
        reasons.append("Some collectible details could not be verified from the image.")
    normalized_quality = detection_quality.lower()
    if any(term in normalized_quality for term in ["fair", "blurry", "glare", "dark"]):
        reasons.append(detection_quality)
    if confidence < 70:
        reasons.append("Important identifiers such as set, number, or edition may be missing.")
    return reasons


def _image_quality_issues(detection_quality: str) -> list[str]:
    normalized = detection_quality.lower()
    issues: list[str] = []
    checks = {
        "blurry": "blurry image",
        "glare": "glare/reflections",
        "reflection": "glare/reflections",
        "cropped": "cropped edges",
        "dark": "dark image",
        "low resolution": "low resolution",
        "multiple": "multiple collectibles in one photo",
        "fair": "fine details may be hard to read",
    }
    for needle, label in checks.items():
        if needle in normalized and label not in issues:
            issues.append(label)
    return issues


def _scan_recommendations(confidence: int, detection_quality: str) -> list[str]:
    recommendations = [
        "Use bright, even lighting.",
        "Keep the collectible flat and fully inside the frame.",
    ]
    if confidence < 90 or _image_quality_issues(detection_quality):
        recommendations.append("Retake the image closer and avoid glare.")
        recommendations.append("Capture small text such as set name, date, card number, or mint mark.")
    return recommendations


def _clamp_confidence(value: int) -> int:
    return max(0, min(100, int(value)))


def _comparable_sales_from_pricing(pricing) -> list[ApiMarketCompResponse]:
    if not pricing.comparableSales:
        return [
            ApiMarketCompResponse(
                source=pricing.pricingSource,
                title="Market pricing reference",
                soldPrice=max(1, pricing.estimatedMarketValue),
                currency=pricing.currency,
                soldDate=pricing.lastUpdated,
                condition="Unknown",
                url=None,
            )
        ]

    return [
        ApiMarketCompResponse(
            source=sale.source,
            title=sale.title,
            soldPrice=max(1, sale.soldPrice),
            currency=sale.currency,
            soldDate=sale.soldDate,
            condition=sale.condition,
            url=sale.url,
        )
        for sale in pricing.comparableSales
    ]


def _average_price(
    comparable_sales: list[ApiMarketCompResponse],
    fallback: int,
) -> int:
    if not comparable_sales:
        return fallback
    return max(1, round(statistics.mean(sale.soldPrice for sale in comparable_sales)))


def _median_price(
    comparable_sales: list[ApiMarketCompResponse],
    fallback: int,
) -> int:
    if not comparable_sales:
        return fallback
    return max(1, round(statistics.median(sale.soldPrice for sale in comparable_sales)))


def _market_sources(pricing) -> list[str]:
    sources = [
        source.strip()
        for source in pricing.pricingSource.split(",")
        if source.strip()
    ]
    return sources or [pricing.pricingSource]
