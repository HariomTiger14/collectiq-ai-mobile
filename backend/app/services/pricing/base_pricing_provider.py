from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Protocol

from app.services.ai.base_recognition_service import RecognitionResult


@dataclass(frozen=True)
class PricingResult:
    estimatedMarketValue: int
    lowEstimate: int
    highEstimate: int
    currency: str
    pricingSource: str
    pricingConfidence: int
    lastUpdated: str


class PricingProvider(Protocol):
    provider_name: str

    def price(self, recognition: RecognitionResult) -> PricingResult:
        """Estimate market pricing for a recognized collectible."""
        ...


def utc_timestamp() -> str:
    return datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")
