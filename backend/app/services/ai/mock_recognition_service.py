from pathlib import Path

from app.services.ai.base_recognition_service import (
    AIRecognitionService,
    RecognitionResult,
)


class MockRecognitionService(AIRecognitionService):
    def recognize(self, image_path: Path) -> RecognitionResult:
        return RecognitionResult(
            title="1999 Pokémon Charizard",
            category="Trading Card",
            confidence=94,
            estimatedValue=1850,
            condition="Near Mint",
            recommendation="Consider grading before selling.",
            description="Likely a Pokémon Base Set Charizard.",
            detectedObjects=["Card", "Pokémon", "Charizard"],
            aiProvider="mock",
            processingTimeMs=125,
        )
