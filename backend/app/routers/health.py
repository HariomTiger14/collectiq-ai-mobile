from fastapi import APIRouter

from app.core.config import settings


router = APIRouter(tags=["System"])


@router.get("/health")
async def health() -> dict[str, str]:
    return {
        "status": "ok",
        "environment": settings.environment,
        "ai_provider": settings.ai_provider,
        "pricing_provider": settings.pricing_provider,
        "version": settings.version,
    }


@router.get("/version")
async def version() -> dict[str, str]:
    return {
        "version": settings.version,
        "environment": settings.environment,
    }
