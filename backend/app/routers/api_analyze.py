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
from app.services.pricing.provider_factory import get_pricing_provider


router = APIRouter(prefix="/api", tags=["Analyze API"])

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

    try:
        provider = get_ai_recognition_provider()
        if hasattr(provider, "recognize_api_payload"):
            recognition = provider.recognize_api_payload(
                request_metadata=_model_to_dict(payload.request),
                image_payload=_model_to_dict(payload.image),
            )
        else:
            recognition = provider.recognize(Path(payload.image.localFilePath))
        pricing = get_pricing_provider("mock").price(recognition)
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

    comparable_sales = _mock_comparable_sales(
        title=recognition.title,
        condition=recognition.condition,
        pricing_source=pricing.pricingSource,
        value=pricing.estimatedMarketValue,
        currency=pricing.currency,
    )

    market_summary = ApiMarketSummaryResponse(
        averagePrice=pricing.estimatedMarketValue,
        medianPrice=pricing.estimatedMarketValue,
        lowPrice=pricing.lowEstimate,
        highPrice=pricing.highEstimate,
        salesCount=len(comparable_sales),
        trendLabel=_trend_for(recognition.category),
        confidence=pricing.pricingConfidence,
        lastUpdated=pricing.lastUpdated,
        sources=[pricing.pricingSource],
        comps=comparable_sales,
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
        marketTrend=market_summary.trendLabel,
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


def _mock_comparable_sales(
    *,
    title: str,
    condition: str,
    pricing_source: str,
    value: int,
    currency: str,
) -> list[ApiMarketCompResponse]:
    return [
        ApiMarketCompResponse(
            source=pricing_source,
            title=f"{title} comparable sale",
            soldPrice=max(1, value),
            currency=currency,
            soldDate="2026-06-30T00:00:00Z",
            condition=condition,
            url=None,
        )
    ]


def _trend_for(category: str) -> str:
    normalized = category.lower()
    if "pokemon" in normalized or "sports" in normalized:
        return "Rising"
    if "coin" in normalized:
        return "Stable"
    if "comic" in normalized:
        return "Watchlist"
    return "Stable"
