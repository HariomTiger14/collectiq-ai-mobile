import unittest
from pathlib import Path

from app.services.ai.mock_recognition_service import MockRecognitionService


class MockRecognitionServiceTest(unittest.TestCase):
    def test_recognize_returns_complete_mock_result(self) -> None:
        result = MockRecognitionService().recognize(Path("uploads/card.png"))

        self.assertEqual(result.title, "1999 Pokémon Charizard")
        self.assertEqual(result.category, "Trading Card")
        self.assertEqual(result.confidence, 94)
        self.assertEqual(result.estimatedValue, 1850)
        self.assertEqual(result.condition, "Near Mint")
        self.assertEqual(result.recommendation, "Consider grading before selling.")
        self.assertEqual(result.description, "Likely a Pokémon Base Set Charizard.")
        self.assertEqual(result.detectedObjects, ["Card", "Pokémon", "Charizard"])
        self.assertEqual(result.aiProvider, "mock")
        self.assertEqual(result.processingTimeMs, 125)


if __name__ == "__main__":
    unittest.main()
