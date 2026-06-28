from dataclasses import dataclass
from pathlib import Path
from typing import Protocol


@dataclass(frozen=True)
class AlternativeMatch:
    title: str
    category: str
    confidence: int
    reason: str


@dataclass(frozen=True)
class RecognitionResult:
    title: str
    category: str
    confidence: int
    estimatedValue: int
    condition: str
    recommendation: str
    description: str
    detectedObjects: list[str]
    aiProvider: str
    processingTimeMs: int
    primaryMatch: str
    alternativeMatches: list[AlternativeMatch]
    confidenceExplanation: str
    detectionQuality: str
    aiReasoning: str


class AIRecognitionProvider(Protocol):
    def recognize(self, image_path: Path) -> RecognitionResult:
        """Recognize a collectible from an uploaded image path."""
        ...


# Backwards-compatible alias for older imports while the backend moves to the
# provider naming used by the real AI foundation.
AIRecognitionService = AIRecognitionProvider
