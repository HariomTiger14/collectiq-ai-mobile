import json
import tempfile
import unittest
from pathlib import Path
from typing import Any

import httpx

from app.services.ai.openai_recognition_provider import (
    AIProviderNotConfiguredError,
    OpenAIInvalidResponseError,
    OpenAIProviderError,
    OpenAIRecognitionProvider,
    OpenAITimeoutError,
)


class FakeResponse:
    def __init__(
        self,
        *,
        status_code: int = 200,
        body: dict[str, Any] | None = None,
        text: str = "",
        json_error: Exception | None = None,
    ) -> None:
        self.status_code = status_code
        self._body = body or {}
        self.text = text
        self._json_error = json_error

    def json(self) -> dict[str, Any]:
        if self._json_error is not None:
            raise self._json_error
        return self._body


class FakeClient:
    def __init__(
        self,
        response: FakeResponse | None = None,
        exception: Exception | None = None,
    ) -> None:
        self.response = response
        self.exception = exception
        self.last_request: dict[str, Any] | None = None

    def post(self, url: str, **kwargs: Any) -> FakeResponse:
        self.last_request = {"url": url, **kwargs}
        if self.exception is not None:
            raise self.exception
        if self.response is None:
            raise AssertionError("FakeClient requires a response or exception.")
        return self.response


class OpenAIRecognitionProviderTest(unittest.TestCase):
    def test_missing_api_key_raises_configuration_error(self) -> None:
        provider = OpenAIRecognitionProvider(api_key="", client=FakeClient())

        with self.assertRaises(AIProviderNotConfiguredError):
            provider.recognize(Path("uploads/card.png"))

    def test_recognize_returns_structured_result_from_mocked_openai(self) -> None:
        output = {
            "title": "1952 Topps Mickey Mantle",
            "category": "Sports Card",
            "confidence": 92,
            "estimatedValue": 125000,
            "condition": "Good",
            "recommendation": "Authenticate and insure before sale.",
            "description": "Classic baseball card with strong collector demand.",
            "detectedObjects": ["Card", "Baseball", "Yankees"],
        }
        client = FakeClient(
            response=FakeResponse(body={"output_text": json.dumps(output)})
        )
        provider = OpenAIRecognitionProvider(
            api_key="test-key",
            model="gpt-test",
            client=client,
        )

        with tempfile.TemporaryDirectory() as directory:
            image_path = Path(directory) / "card.png"
            image_path.write_bytes(b"image-bytes")

            result = provider.recognize(image_path)

        self.assertEqual(result.title, "1952 Topps Mickey Mantle")
        self.assertEqual(result.category, "Sports Card")
        self.assertEqual(result.confidence, 92)
        self.assertEqual(result.estimatedValue, 125000)
        self.assertEqual(result.condition, "Good")
        self.assertEqual(result.recommendation, "Authenticate and insure before sale.")
        self.assertEqual(result.description, output["description"])
        self.assertEqual(result.detectedObjects, ["Card", "Baseball", "Yankees"])
        self.assertEqual(result.aiProvider, "openai")
        self.assertGreater(result.processingTimeMs, 0)
        self.assertIsNotNone(client.last_request)
        self.assertEqual(client.last_request["url"], provider.responses_url)
        self.assertEqual(client.last_request["json"]["model"], "gpt-test")
        image_content = client.last_request["json"]["input"][0]["content"][1]
        self.assertEqual(image_content["type"], "input_image")
        self.assertTrue(image_content["image_url"].startswith("data:image/png;base64,"))

    def test_recognize_parses_nested_response_output_text(self) -> None:
        output = {
            "title": "1921 Morgan Silver Dollar",
            "category": "Coin",
            "confidence": 88,
            "estimatedValue": 140,
            "condition": "Very Fine",
            "recommendation": "Store in a non-PVC holder.",
            "description": "Silver dollar with classic Morgan profile.",
            "detectedObjects": ["Coin", "Silver"],
        }
        client = FakeClient(
            response=FakeResponse(
                body={
                    "output": [
                        {
                            "content": [
                                {
                                    "type": "output_text",
                                    "text": json.dumps(output),
                                }
                            ]
                        }
                    ]
                }
            )
        )
        provider = OpenAIRecognitionProvider(api_key="test-key", client=client)

        with tempfile.TemporaryDirectory() as directory:
            image_path = Path(directory) / "coin.jpg"
            image_path.write_bytes(b"image-bytes")

            result = provider.recognize(image_path)

        self.assertEqual(result.title, "1921 Morgan Silver Dollar")
        self.assertEqual(result.aiProvider, "openai")

    def test_http_failure_raises_provider_error(self) -> None:
        provider = OpenAIRecognitionProvider(
            api_key="test-key",
            client=FakeClient(
                response=FakeResponse(
                    status_code=500,
                    text="server error",
                )
            ),
        )

        with tempfile.TemporaryDirectory() as directory:
            image_path = Path(directory) / "card.png"
            image_path.write_bytes(b"image-bytes")

            with self.assertRaises(OpenAIProviderError):
                provider.recognize(image_path)

    def test_timeout_raises_timeout_error(self) -> None:
        provider = OpenAIRecognitionProvider(
            api_key="test-key",
            client=FakeClient(exception=httpx.TimeoutException("slow")),
        )

        with tempfile.TemporaryDirectory() as directory:
            image_path = Path(directory) / "card.png"
            image_path.write_bytes(b"image-bytes")

            with self.assertRaises(OpenAITimeoutError):
                provider.recognize(image_path)

    def test_invalid_json_raises_invalid_response_error(self) -> None:
        provider = OpenAIRecognitionProvider(
            api_key="test-key",
            client=FakeClient(response=FakeResponse(body={"output_text": "nope"})),
        )

        with tempfile.TemporaryDirectory() as directory:
            image_path = Path(directory) / "card.png"
            image_path.write_bytes(b"image-bytes")

            with self.assertRaises(OpenAIInvalidResponseError):
                provider.recognize(image_path)

    def test_missing_required_field_raises_invalid_response_error(self) -> None:
        provider = OpenAIRecognitionProvider(
            api_key="test-key",
            client=FakeClient(response=FakeResponse(body={"output_text": "{}"})),
        )

        with tempfile.TemporaryDirectory() as directory:
            image_path = Path(directory) / "card.png"
            image_path.write_bytes(b"image-bytes")

            with self.assertRaises(OpenAIInvalidResponseError):
                provider.recognize(image_path)

    def test_non_json_http_body_raises_invalid_response_error(self) -> None:
        provider = OpenAIRecognitionProvider(
            api_key="test-key",
            client=FakeClient(
                response=FakeResponse(json_error=ValueError("not json")),
            ),
        )

        with tempfile.TemporaryDirectory() as directory:
            image_path = Path(directory) / "card.png"
            image_path.write_bytes(b"image-bytes")

            with self.assertRaises(OpenAIInvalidResponseError):
                provider.recognize(image_path)


if __name__ == "__main__":
    unittest.main()
