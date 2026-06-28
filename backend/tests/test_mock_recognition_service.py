import unittest
from pathlib import Path

from app.services.ai.mock_recognition_service import MockRecognitionService


class MockRecognitionServiceTest(unittest.TestCase):
    def test_recognize_returns_complete_mock_result(self) -> None:
        result = MockRecognitionService().recognize(Path("uploads/card.png"))

        self.assertTrue(result.title)
        self.assertTrue(result.category)
        self.assertGreaterEqual(result.confidence, 80)
        self.assertGreater(result.estimatedValue, 0)
        self.assertTrue(result.condition)
        self.assertTrue(result.recommendation)
        self.assertTrue(result.description)
        self.assertGreaterEqual(len(result.detectedObjects), 3)
        self.assertEqual(result.aiProvider, "mock")
        self.assertGreater(result.processingTimeMs, 0)

    def test_recognize_varies_results_across_upload_paths(self) -> None:
        service = MockRecognitionService()

        results = [
            service.recognize(Path(f"uploads/mock-upload-{index}.png"))
            for index in range(20)
        ]

        titles = {result.title for result in results}
        categories = {result.category for result in results}
        values = {result.estimatedValue for result in results}

        self.assertGreaterEqual(len(titles), 5)
        self.assertGreaterEqual(len(categories), 4)
        self.assertGreaterEqual(len(values), 5)

    def test_recognize_does_not_repeat_adjacent_results(self) -> None:
        service = MockRecognitionService()

        results = [
            service.recognize(Path(f"uploads/adjacent-{index}.png"))
            for index in range(20)
        ]

        for previous, current in zip(results, results[1:]):
            self.assertNotEqual(previous.title, current.title)


if __name__ == "__main__":
    unittest.main()
