import json
import unittest
from pathlib import Path
from unittest.mock import patch

import httpx
from fastapi.testclient import TestClient

from app.main import app
from app.services.ai.openai_recognition_provider import OpenAIRecognitionProvider


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
        self.assertGreaterEqual(payload["marketSummary"]["salesCount"], 1)
        self.assertGreaterEqual(len(payload["comparableSales"]), 1)
        self.assertEqual(payload["timestamp"], "2026-06-30T09:00:00Z")
        self.assertIn(payload["confidenceLevel"], ["High", "Medium", "Low"])
        self.assertIsInstance(payload["fieldConfidence"], dict)
        self.assertIn("itemName", payload["fieldConfidence"])
        self.assertIsInstance(payload["lowConfidenceReasons"], list)
        self.assertIsInstance(payload["imageQualityIssues"], list)
        self.assertIsInstance(payload["scanRecommendations"], list)

    def test_api_analyze_openai_without_key_returns_safe_error(self) -> None:
        with patch(
            "app.routers.api_analyze.get_ai_recognition_provider",
            return_value=OpenAIRecognitionProvider(api_key=""),
        ):
            response = self.client.post(
                "/api/analyze",
                json=_api_analyze_payload(),
            )

        self.assertEqual(response.status_code, 501)
        error = response.json()["error"]
        self.assertEqual(error["code"], "ai_provider_not_configured")
        self.assertIn("OPENAI_API_KEY", error["message"])
        self.assertFalse(error["retryable"])

    def test_api_analyze_openai_success_returns_contract_response(self) -> None:
        provider = OpenAIRecognitionProvider(
            api_key="test-key",
            client=_FakeOpenAIClient(
                response=_FakeOpenAIResponse(
                    body={"output_text": json.dumps(_openai_output())}
                )
            ),
        )

        with patch(
            "app.routers.api_analyze.get_ai_recognition_provider",
            return_value=provider,
        ):
            response = self.client.post(
                "/api/analyze",
                json=_api_analyze_payload(base64_image=True),
            )

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["itemName"], "1999 Pokemon Charizard Holo")
        self.assertEqual(payload["category"], "Pokemon Card")
        self.assertEqual(payload["confidence"], 94)
        self.assertEqual(payload["aiReview"]["primaryMatch"], payload["itemName"])
        self.assertEqual(len(payload["alternatives"]), 3)
        self.assertGreaterEqual(payload["marketSummary"]["salesCount"], 1)
        self.assertEqual(payload["comparableSales"][0]["currency"], "AUD")
        self.assertEqual(payload["confidenceLevel"], "High")
        self.assertEqual(payload["fieldConfidence"]["itemName"], 96)
        self.assertEqual(payload["imageQualityIssues"], ["none"])
        self.assertIn("Use bright", payload["scanRecommendations"][0])

        self.assertIsNotNone(provider._client.last_request)
        request_json = provider._client.last_request["json"]
        self.assertEqual(request_json["model"], "gpt-4.1-mini")
        prompt_text = request_json["input"][0]["content"][0]["text"]
        self.assertIn("requestedCategory=Pokemon Card", prompt_text)
        self.assertIn("Return confidence for each extracted field", prompt_text)
        self.assertIn("glare/reflections", prompt_text)
        image_content = request_json["input"][0]["content"][1]
        self.assertTrue(image_content["image_url"].startswith("data:image/jpeg;base64,"))

    def test_api_analyze_openai_invalid_json_returns_safe_error(self) -> None:
        provider = OpenAIRecognitionProvider(
            api_key="test-key",
            client=_FakeOpenAIClient(
                response=_FakeOpenAIResponse(body={"output_text": "not json"})
            ),
        )

        with patch(
            "app.routers.api_analyze.get_ai_recognition_provider",
            return_value=provider,
        ):
            response = self.client.post(
                "/api/analyze",
                json=_api_analyze_payload(base64_image=True),
            )

        self.assertEqual(response.status_code, 502)
        error = response.json()["error"]
        self.assertEqual(error["code"], "ai_provider_invalid_response")
        self.assertTrue(error["retryable"])

    def test_api_analyze_openai_timeout_returns_safe_error(self) -> None:
        provider = OpenAIRecognitionProvider(
            api_key="test-key",
            client=_FakeOpenAIClient(exception=httpx.TimeoutException("slow")),
        )

        with patch(
            "app.routers.api_analyze.get_ai_recognition_provider",
            return_value=provider,
        ):
            response = self.client.post(
                "/api/analyze",
                json=_api_analyze_payload(base64_image=True),
            )

        self.assertEqual(response.status_code, 504)
        error = response.json()["error"]
        self.assertEqual(error["code"], "ai_provider_timeout")
        self.assertTrue(error["retryable"])

    def test_golden_manifest_structure(self) -> None:
        manifest_path = Path(__file__).parent / "test_assets" / "manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

        self.assertGreaterEqual(len(manifest), 3)
        for entry in manifest:
            self.assertTrue(entry["imageFilename"])
            self.assertTrue(entry["expectedCategory"])
            self.assertTrue(entry["expectedItem"])
            confidence_range = entry["expectedConfidenceRange"]
            self.assertGreaterEqual(confidence_range["min"], 0)
            self.assertLessEqual(confidence_range["max"], 100)
            self.assertLessEqual(confidence_range["min"], confidence_range["max"])

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


def _api_analyze_payload(*, base64_image: bool = False) -> dict:
    image_payload = {
        "fileName": "card.jpg",
        "mimeType": "image/jpeg",
        "sizeBytes": 123456,
        "imageSource": "camera",
        "localFilePath": "/local/app/path/card.jpg",
    }
    if base64_image:
        image_payload["base64Image"] = "aW1hZ2UtYnl0ZXM="

    return {
        "request": {
            "imagePath": "/local/app/path/card.jpg",
            "imageSource": "camera",
            "requestedCategory": "Pokemon Card",
            "appVersion": "1.0.0",
            "deviceMetadata": {"platform": "android"},
            "timestamp": "2026-06-30T09:00:00Z",
        },
        "image": image_payload,
    }


def _openai_output() -> dict:
    return {
        "title": "1999 Pokemon Charizard Holo",
        "category": "Pokemon Card",
        "confidence": 94,
        "estimatedValue": 1850,
        "condition": "Near Mint",
        "recommendation": "Consider professional grading before selling.",
        "description": "Likely a Base Set Charizard holographic card.",
        "detectedObjects": ["Card", "Pokemon", "Charizard"],
        "fieldConfidence": {
            "itemName": 96,
            "category": 95,
            "brand": 92,
            "setName": 88,
            "year": 82,
            "cardNumber": 78,
            "condition": 70,
        },
        "confidenceLevel": "High",
        "lowConfidenceReasons": [],
        "imageQualityIssues": ["none"],
        "scanRecommendations": [
            "Use bright, even lighting.",
            "Keep the card fully inside the frame.",
        ],
        "primaryMatch": "1999 Pokemon Charizard Holo",
        "alternativeMatches": [
            {
                "title": "2002 Pokemon Expedition Charizard",
                "category": "Pokemon Card",
                "confidence": 72,
                "reason": "Similar fire-type character and card framing.",
            },
            {
                "title": "2016 Pokemon Evolutions Charizard",
                "category": "Pokemon Card",
                "confidence": 68,
                "reason": "Modern reprint shares similar artwork cues.",
            },
            {
                "title": "Pokemon Charizard Promo Card",
                "category": "Pokemon Card",
                "confidence": 61,
                "reason": "Character match is strong, but set details differ.",
            },
        ],
        "confidenceExplanation": "High confidence from artwork and card layout.",
        "detectionQuality": "Good - card border and character are visible.",
        "aiReasoning": "The image matches Charizard TCG visual cues.",
        "year": "1999",
        "brand": "Pokemon",
        "setName": "Base Set",
        "series": "Pokemon TCG",
        "cardNumber": "4/102",
        "playerOrCharacter": "Charizard",
        "rarity": "Holo Rare",
        "estimatedGrade": "PSA 8-9",
        "language": "English",
        "edition": "Unlimited",
        "country": "United States",
        "mint": None,
        "material": "Cardstock",
        "notes": "Verify holo surface and centering before grading.",
    }


class _FakeOpenAIResponse:
    def __init__(self, *, status_code: int = 200, body: dict | None = None) -> None:
        self.status_code = status_code
        self._body = body or {}
        self.text = json.dumps(self._body)

    def json(self) -> dict:
        return self._body


class _FakeOpenAIClient:
    def __init__(
        self,
        *,
        response: _FakeOpenAIResponse | None = None,
        exception: Exception | None = None,
    ) -> None:
        self.response = response
        self.exception = exception
        self.last_request: dict | None = None

    def post(self, url: str, **kwargs) -> _FakeOpenAIResponse:
        self.last_request = {"url": url, **kwargs}
        if self.exception is not None:
            raise self.exception
        if self.response is None:
            raise AssertionError("Fake OpenAI client requires a response.")
        return self.response


if __name__ == "__main__":
    unittest.main()
