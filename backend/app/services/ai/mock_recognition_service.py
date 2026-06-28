from pathlib import Path
from random import Random
from threading import Lock

from app.services.ai.base_recognition_service import (
    AIRecognitionService,
    RecognitionResult,
)


_MOCK_RESULTS = [
    RecognitionResult(
        title="1999 Pokemon Charizard Holo",
        category="Trading Card",
        confidence=94,
        estimatedValue=1850,
        condition="Near Mint",
        recommendation="Consider grading before selling.",
        description="Likely a Base Set Charizard holo with strong collector demand.",
        detectedObjects=["Card", "Pokemon", "Charizard"],
        aiProvider="mock",
        processingTimeMs=125,
    ),
    RecognitionResult(
        title="1986 Fleer Michael Jordan Rookie",
        category="Sports Card",
        confidence=91,
        estimatedValue=4200,
        condition="Excellent",
        recommendation="Authenticate and grade before listing.",
        description="Basketball rookie card style with high-value vintage market signals.",
        detectedObjects=["Card", "Basketball", "Rookie"],
        aiProvider="mock",
        processingTimeMs=148,
    ),
    RecognitionResult(
        title="American Silver Eagle Proof Coin",
        category="Coin",
        confidence=88,
        estimatedValue=165,
        condition="Proof",
        recommendation="Store in a capsule and verify mint year.",
        description="Bullion collectible with proof-like finish and numismatic appeal.",
        detectedObjects=["Coin", "Silver", "Eagle"],
        aiProvider="mock",
        processingTimeMs=132,
    ),
    RecognitionResult(
        title="Amazing Spider-Man #300",
        category="Comic",
        confidence=89,
        estimatedValue=950,
        condition="Very Fine",
        recommendation="Bag, board, and consider professional pressing.",
        description="Key comic issue associated with the first full Venom appearance.",
        detectedObjects=["Comic", "Spider-Man", "Venom"],
        aiProvider="mock",
        processingTimeMs=156,
    ),
    RecognitionResult(
        title="Star Wars Kenner Boba Fett Figure",
        category="Toy/Figure",
        confidence=86,
        estimatedValue=320,
        condition="Good",
        recommendation="Check accessories and production markings.",
        description="Vintage action figure style with collectible character demand.",
        detectedObjects=["Figure", "Star Wars", "Boba Fett"],
        aiProvider="mock",
        processingTimeMs=141,
    ),
    RecognitionResult(
        title="1993 Magic: The Gathering Shivan Dragon",
        category="Trading Card",
        confidence=87,
        estimatedValue=240,
        condition="Lightly Played",
        recommendation="Sleeve immediately and verify set symbol.",
        description="Classic fantasy trading card with strong early-era appeal.",
        detectedObjects=["Card", "Magic", "Dragon"],
        aiProvider="mock",
        processingTimeMs=137,
    ),
    RecognitionResult(
        title="Topps Chrome Shohei Ohtani Rookie",
        category="Sports Card",
        confidence=90,
        estimatedValue=780,
        condition="Near Mint",
        recommendation="Inspect corners and submit if surface is clean.",
        description="Modern baseball rookie card with strong player-demand signals.",
        detectedObjects=["Card", "Baseball", "Rookie"],
        aiProvider="mock",
        processingTimeMs=129,
    ),
    RecognitionResult(
        title="Transformers G1 Optimus Prime",
        category="Toy/Figure",
        confidence=84,
        estimatedValue=510,
        condition="Good",
        recommendation="Confirm trailer, fists, and accessories are present.",
        description="Vintage transforming robot toy with broad collector recognition.",
        detectedObjects=["Toy", "Robot", "Optimus Prime"],
        aiProvider="mock",
        processingTimeMs=151,
    ),
]

_random = Random()
_result_lock = Lock()
_remaining_results: list[RecognitionResult] = []
_last_result_title: str | None = None


def _next_mock_result() -> RecognitionResult:
    global _last_result_title

    with _result_lock:
        if not _remaining_results:
            _remaining_results.extend(_MOCK_RESULTS)
            _random.shuffle(_remaining_results)

            if (
                _last_result_title is not None
                and len(_remaining_results) > 1
                and _remaining_results[-1].title == _last_result_title
            ):
                _remaining_results[0], _remaining_results[-1] = (
                    _remaining_results[-1],
                    _remaining_results[0],
                )

        result = _remaining_results.pop()
        _last_result_title = result.title
        return result


class MockRecognitionService(AIRecognitionService):
    def recognize(self, image_path: Path) -> RecognitionResult:
        return _next_mock_result()
