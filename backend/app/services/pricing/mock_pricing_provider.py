from app.services.ai.base_recognition_service import RecognitionResult
from app.services.pricing.base_pricing_provider import PricingProvider, PricingResult, utc_timestamp


class MockPricingProvider(PricingProvider):
    provider_name = "mock"

    def price(self, recognition: RecognitionResult) -> PricingResult:
        value = max(1, int(recognition.estimatedValue))
        spread = self._spread_for(recognition.category)
        low_estimate = max(1, round(value * (1 - spread)))
        high_estimate = max(low_estimate, round(value * (1 + spread)))

        return PricingResult(
            estimatedMarketValue=value,
            lowEstimate=low_estimate,
            highEstimate=high_estimate,
            currency="AUD",
            pricingSource=self._source_for(recognition.category),
            pricingConfidence=self._confidence_for(recognition.confidence),
            lastUpdated=utc_timestamp(),
        )

    def _spread_for(self, category: str) -> float:
        normalized = category.lower()
        if "coin" in normalized:
            return 0.18
        if "comic" in normalized:
            return 0.28
        if "toy" in normalized or "figure" in normalized:
            return 0.25
        return 0.22

    def _source_for(self, category: str) -> str:
        normalized = category.lower()
        if "pokemon" in normalized or "trading card" in normalized:
            return "Mock market blend: TCGplayer + eBay comps"
        if "sports" in normalized:
            return "Mock market blend: eBay comps + PSA guide"
        if "coin" in normalized:
            return "Mock market blend: auction comps + coin guide"
        if "comic" in normalized:
            return "Mock market blend: comic guide + eBay comps"
        return "Mock market blend"

    def _confidence_for(self, recognition_confidence: int) -> int:
        return max(45, min(95, round(recognition_confidence * 0.9)))
