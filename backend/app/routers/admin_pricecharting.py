from fastapi import APIRouter, Header, HTTPException, status

from app.core.config import settings
from app.services.pricing.pricecharting_status_service import (
    PriceChartingStatusError,
    PriceChartingStatusService,
)


router = APIRouter(prefix="/admin/pricecharting", tags=["Admin PriceCharting"])


@router.get("/status")
async def pricecharting_status(
    x_admin_token: str = Header("", alias="X-Admin-Token"),
) -> dict:
    if not settings.admin_job_token or x_admin_token != settings.admin_job_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "code": "admin_token_required",
                "message": "A valid admin token is required.",
                "retryable": False,
            },
        )

    try:
        return PriceChartingStatusService().status()
    except PriceChartingStatusError as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "code": "pricecharting_status_unavailable",
                "message": str(error),
                "retryable": True,
            },
        ) from error
