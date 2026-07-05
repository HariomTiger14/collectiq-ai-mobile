import unittest
from pathlib import Path

from app.services.ai.base_recognition_service import AIRecognitionProvider, AiProvider
from app.services.ai.mock_recognition_service import (
    MOCK_COLLECTIBLES,
    MockAiProvider,
    MockRecognitionProvider,
    MockRecognitionService,
)
from app.services.ai.openai_recognition_provider import (
    OpenAIRecognitionProvider,
    OpenAiVisionProvider,
)
from app.services.ai.provider_factory import get_ai_recognition_provider


class MockRecognitionProviderTest(unittest.TestCase):
    def test_recognize_returns_complete_mock_result(self) -> None:
        result = MockRecognitionProvider().recognize(Path("uploads/card.png"))

        self.assertIn(result.title, {item.title for item in MOCK_COLLECTIBLES})
        self.assertIn(result.category, {item.category for item in MOCK_COLLECTIBLES})
        self.assertGreaterEqual(result.confidence, 0)
        self.assertLessEqual(result.confidence, 100)
        self.assertGreater(result.estimatedValue, 0)
        self.assertTrue(result.condition)
        self.assertTrue(result.recommendation)
        self.assertTrue(result.description)
        self.assertTrue(result.detectedObjects)
        self.assertEqual(result.aiProvider, "mock")
        self.assertGreater(result.processingTimeMs, 0)
        self.assertEqual(result.primaryMatch, result.title)
        self.assertEqual(len(result.alternativeMatches), 3)
        self.assertTrue(result.confidenceExplanation)
        self.assertTrue(result.detectionQuality)
        self.assertTrue(result.aiReasoning)
        self.assertTrue(
            any(
                [
                    result.year,
                    result.brand,
                    result.setName,
                    result.series,
                    result.cardNumber,
                    result.playerOrCharacter,
                    result.rarity,
                    result.estimatedGrade,
                    result.language,
                    result.edition,
                    result.country,
                    result.mint,
                    result.material,
                    result.notes,
                ]
            )
        )

    def test_recognize_returns_varied_mock_results(self) -> None:
        provider = MockRecognitionProvider()

        titles = {
            provider.recognize(Path(f"uploads/card-{index}.png")).title
            for index in range(12)
        }

        self.assertGreater(len(titles), 1)

    def test_mock_pool_has_required_category_coverage(self) -> None:
        categories = {item.category for item in MOCK_COLLECTIBLES}

        self.assertGreaterEqual(len(MOCK_COLLECTIBLES), 30)
        self.assertIn("Pokemon Card", categories)
        self.assertIn("Sports Card", categories)
        self.assertIn("Coin", categories)
        self.assertIn("Action Figure", categories)
        self.assertIn("Comic Book", categories)
        self.assertIn("Stamp", categories)
        self.assertIn("Retro Game", categories)
        self.assertIn("Trading Card", categories)
        self.assertIn("Vintage Toy", categories)
        self.assertIn(
            "1999 Pokemon Charizard Holo",
            {item.title for item in MOCK_COLLECTIBLES},
        )

    def test_api_payload_uses_image_signal_for_deterministic_variation(self) -> None:
        provider = MockRecognitionProvider()

        first = provider.recognize_api_payload(
            request_metadata={"imagePath": "/tmp/scan-a.jpg"},
            image_payload={"base64Image": "first-upload-bytes"},
        )
        second = provider.recognize_api_payload(
            request_metadata={"imagePath": "/tmp/scan-b.jpg"},
            image_payload={"base64Image": "second-upload-bytes"},
        )

        self.assertNotEqual(first.title, second.title)

    def test_backwards_compatible_mock_service_alias(self) -> None:
        self.assertIs(MockRecognitionService, MockRecognitionProvider)

    def test_product_provider_aliases(self) -> None:
        self.assertIs(AiProvider, AIRecognitionProvider)
        self.assertIs(MockAiProvider, MockRecognitionProvider)
        self.assertIs(OpenAiVisionProvider, OpenAIRecognitionProvider)


class ProviderFactoryTest(unittest.TestCase):
    def test_provider_factory_uses_mock_by_default(self) -> None:
        provider = get_ai_recognition_provider()

        self.assertIsInstance(provider, MockRecognitionProvider)

    def test_provider_factory_defaults_to_mock(self) -> None:
        provider = get_ai_recognition_provider("mock")

        self.assertIsInstance(provider, MockRecognitionProvider)

    def test_provider_factory_supports_openai_placeholder(self) -> None:
        provider = get_ai_recognition_provider("openai")

        self.assertIsInstance(provider, OpenAIRecognitionProvider)

    def test_provider_factory_rejects_unknown_provider(self) -> None:
        with self.assertRaises(ValueError):
            get_ai_recognition_provider("unknown")


if __name__ == "__main__":
    unittest.main()
