import random
from pathlib import Path

from app.services.ai.base_recognition_service import (
    AIRecognitionProvider,
    RecognitionResult,
)


MOCK_COLLECTIBLES = [
    RecognitionResult(
        title="1999 Pokemon Charizard Holo",
        category="Pokemon Card",
        confidence=94,
        estimatedValue=1850,
        condition="Near Mint",
        recommendation="Consider professional grading before selling.",
        description="Likely a Base Set Charizard holographic card with strong collector demand.",
        detectedObjects=["Card", "Pokemon", "Charizard", "Holographic"],
        aiProvider="mock",
        processingTimeMs=132,
    ),
    RecognitionResult(
        title="1986 Fleer Michael Jordan Rookie",
        category="Sports Card",
        confidence=89,
        estimatedValue=4200,
        condition="Excellent",
        recommendation="Protect in a rigid sleeve and verify centering with a grader.",
        description="Basketball rookie card style match with high resale interest.",
        detectedObjects=["Card", "Basketball", "Rookie", "Chicago"],
        aiProvider="mock",
        processingTimeMs=148,
    ),
    RecognitionResult(
        title="1921 Morgan Silver Dollar",
        category="Coin",
        confidence=87,
        estimatedValue=145,
        condition="Very Fine",
        recommendation="Store in a non-PVC coin flip and avoid cleaning the surface.",
        description="Classic US silver dollar with visible Morgan profile and eagle reverse cues.",
        detectedObjects=["Coin", "Silver", "Morgan Dollar"],
        aiProvider="mock",
        processingTimeMs=118,
    ),
    RecognitionResult(
        title="Amazing Spider-Man #300",
        category="Comic",
        confidence=91,
        estimatedValue=900,
        condition="Fine",
        recommendation="Bag, board, and inspect spine ticks before submitting for grading.",
        description="Comic cover appears consistent with the first full Venom appearance.",
        detectedObjects=["Comic", "Spider-Man", "Venom", "Cover"],
        aiProvider="mock",
        processingTimeMs=156,
    ),
    RecognitionResult(
        title="Transformers Optimus Prime G1 Figure",
        category="Toy/Figure",
        confidence=84,
        estimatedValue=260,
        condition="Good",
        recommendation="Check for original accessories to improve resale value.",
        description="Vintage transforming robot figure with recognizable red cab styling.",
        detectedObjects=["Toy", "Figure", "Robot", "Optimus Prime"],
        aiProvider="mock",
        processingTimeMs=140,
    ),
    RecognitionResult(
        title="Magic: The Gathering Black Lotus Reprint",
        category="Trading Card",
        confidence=82,
        estimatedValue=75,
        condition="Lightly Played",
        recommendation="Verify set symbol and authenticity before listing.",
        description="Fantasy trading card layout resembles a premium MTG collectible.",
        detectedObjects=["Card", "Trading Card", "Fantasy", "Lotus"],
        aiProvider="mock",
        processingTimeMs=128,
    ),
]


class MockRecognitionProvider(AIRecognitionProvider):
    _last_index: int | None = None

    def recognize(self, image_path: Path) -> RecognitionResult:
        if len(MOCK_COLLECTIBLES) == 1:
            return MOCK_COLLECTIBLES[0]

        available_indexes = [
            index
            for index in range(len(MOCK_COLLECTIBLES))
            if index != self.__class__._last_index
        ]
        selected_index = random.choice(available_indexes)
        self.__class__._last_index = selected_index

        return MOCK_COLLECTIBLES[selected_index]


# Backwards-compatible alias for existing tests/imports.
MockRecognitionService = MockRecognitionProvider
