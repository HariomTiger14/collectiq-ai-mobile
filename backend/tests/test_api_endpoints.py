import unittest
from unittest.mock import patch

from fastapi.testclient import TestClient

from app.main import app


class ApiEndpointsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)

    def test_health(self) -> None:
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "ok"})

    def test_scanner_analyze_happy_path(self) -> None:
        response = self.client.post(
            "/scanner/analyze",
            files={"image": ("card.png", b"image-bytes", "image/png")},
        )

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertTrue(payload["success"])
        self.assertTrue(payload["filename"].endswith(".png"))
        self.assertIn("/uploads/", payload["imageUrl"])
        self.assertTrue(payload["title"])
        self.assertIn(
            payload["category"],
            [
                "Pokemon Card",
                "Sports Card",
                "Trading Card",
                "Coin",
                "Comic",
                "Toy/Figure",
            ],
        )
        self.assertGreaterEqual(payload["confidence"], 0)
        self.assertLessEqual(payload["confidence"], 100)
        self.assertGreater(payload["estimatedValue"], 0)
        self.assertTrue(payload["condition"])
        self.assertTrue(payload["recommendation"])
        self.assertTrue(payload["description"])
        self.assertTrue(payload["detectedObjects"])
        self.assertEqual(payload["aiProvider"], "mock")
        self.assertGreater(payload["processingTimeMs"], 0)
        self.assertTrue(payload["primaryMatch"])
        self.assertEqual(len(payload["alternativeMatches"]), 3)
        self.assertTrue(payload["confidenceExplanation"])
        self.assertTrue(payload["detectionQuality"])
        self.assertTrue(payload["aiReasoning"])
        self.assertIn("year", payload)
        self.assertIn("brand", payload)
        self.assertIn("setName", payload)
        self.assertIn("playerOrCharacter", payload)
        self.assertIn("material", payload)
        self.assertIn("notes", payload)
        self.assertIn("pricing", payload)
        pricing = payload["pricing"]
        self.assertEqual(payload["estimatedValue"], pricing["estimatedMarketValue"])
        self.assertGreater(pricing["lowEstimate"], 0)
        self.assertGreaterEqual(
            pricing["highEstimate"],
            pricing["estimatedMarketValue"],
        )
        self.assertEqual(pricing["currency"], "AUD")
        self.assertTrue(pricing["pricingSource"])
        self.assertGreaterEqual(pricing["pricingConfidence"], 0)
        self.assertLessEqual(pricing["pricingConfidence"], 100)
        self.assertTrue(pricing["lastUpdated"])

    def test_api_analyze_happy_path(self) -> None:
        response = self.client.post("/api/analyze", json=_api_analyze_payload())

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertTrue(payload["id"].startswith("backend-"))
        self.assertTrue(payload["itemName"])
        self.assertTrue(payload["category"])
        self.assertGreater(payload["estimatedValue"], 0)
        self.assertGreater(payload["lowEstimate"], 0)
        self.assertGreaterEqual(payload["highEstimate"], payload["estimatedValue"])
        self.assertGreaterEqual(payload["confidence"], 0)
        self.assertLessEqual(payload["confidence"], 100)
        self.assertTrue(payload["condition"])
        self.assertTrue(payload["marketTrend"])
        self.assertIsInstance(payload["keyAttributes"], dict)
        self.assertTrue(payload["aiReview"]["primaryMatch"])
        self.assertTrue(payload["aiReview"]["confidenceExplanation"])
        self.assertEqual(len(payload["alternatives"]), 3)
        self.assertTrue(payload["recommendation"])
        self.assertIn("marketSummary", payload)
        self.assertEqual(payload["marketSummary"]["salesCount"], 1)
        self.assertEqual(len(payload["comparableSales"]), 1)
        self.assertEqual(payload["timestamp"], "2026-06-30T09:00:00Z")

    def test_api_analyze_missing_image(self) -> None:
        payload = _api_analyze_payload()
        payload["request"]["imagePath"] = ""

        response = self.client.post("/api/analyze", json=payload)

        self.assertEqual(response.status_code, 400)
        error = response.json()["error"]
        self.assertEqual(error["code"], "missing_image")
        self.assertFalse(error["retryable"])

    def test_api_analyze_invalid_payload(self) -> None:
        payload = _api_analyze_payload()
        payload["image"]["fileName"] = "card.gif"
        payload["image"]["mimeType"] = "image/gif"

        response = self.client.post("/api/analyze", json=payload)

        self.assertEqual(response.status_code, 422)
        error = response.json()["error"]
        self.assertEqual(error["code"], "invalid_payload")
        self.assertFalse(error["retryable"])

    def test_api_analyze_unsupported_category(self) -> None:
        payload = _api_analyze_payload()
        payload["request"]["requestedCategory"] = "Fine Art"

        response = self.client.post("/api/analyze", json=payload)

        self.assertEqual(response.status_code, 422)
        error = response.json()["error"]
        self.assertEqual(error["code"], "unsupported_category")
        self.assertFalse(error["retryable"])

    def test_api_analyze_server_error(self) -> None:
        with patch(
            "app.routers.api_analyze.get_ai_recognition_provider",
            side_effect=RuntimeError("provider failed"),
        ):
            response = self.client.post(
                "/api/analyze",
                json=_api_analyze_payload(),
            )

        self.assertEqual(response.status_code, 500)
        error = response.json()["error"]
        self.assertEqual(error["code"], "server_error")
        self.assertTrue(error["retryable"])

    def test_scanner_analyze_invalid_extension(self) -> None:
        response = self.client.post(
            "/scanner/analyze",
            files={"image": ("card.gif", b"image-bytes", "image/gif")},
        )

        self.assertEqual(response.status_code, 415)
        self.assertFalse(response.json()["success"])

    def test_scanner_analyze_oversized_image(self) -> None:
        response = self.client.post(
            "/scanner/analyze",
            files={
                "image": (
                    "large.png",
                    b"0" * (10 * 1024 * 1024 + 1),
                    "image/png",
                )
            },
        )

        self.assertEqual(response.status_code, 413)
        self.assertFalse(response.json()["success"])

    def test_get_portfolio(self) -> None:
        response = self.client.get("/portfolio")

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()["success"])
        self.assertIsInstance(response.json()["items"], list)

    def test_post_portfolio(self) -> None:
        response = self.client.post(
            "/portfolio",
            json={"id": "test-item", "data": {"title": "Test Card"}},
        )

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertTrue(payload["success"])
        self.assertEqual(payload["item"]["id"], "test-item")
        self.assertEqual(payload["item"]["data"]["title"], "Test Card")

    def test_delete_portfolio(self) -> None:
        self.client.post(
            "/portfolio",
            json={"id": "delete-me", "data": {"title": "Delete Card"}},
        )

        response = self.client.delete("/portfolio/delete-me")

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertTrue(payload["success"])
        self.assertEqual(payload["deletedId"], "delete-me")


def _api_analyze_payload() -> dict:
    return {
        "request": {
            "imagePath": "/local/app/path/card.jpg",
            "imageSource": "camera",
            "requestedCategory": "Pokemon Card",
            "appVersion": "1.0.0",
            "deviceMetadata": {"platform": "android"},
            "timestamp": "2026-06-30T09:00:00Z",
        },
        "image": {
            "fileName": "card.jpg",
            "mimeType": "image/jpeg",
            "sizeBytes": 123456,
            "imageSource": "camera",
            "localFilePath": "/local/app/path/card.jpg",
        },
    }


if __name__ == "__main__":
    unittest.main()
