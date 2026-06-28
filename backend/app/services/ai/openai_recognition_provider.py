import base64
import json
import time
from pathlib import Path
from typing import Any

import httpx

from app.core.config import settings
from app.services.ai.base_recognition_service import (
    AIRecognitionProvider,
    AlternativeMatch,
    RecognitionResult,
)


class AIProviderNotConfiguredError(RuntimeError):
    """Raised when a selected AI provider is not ready for recognition."""


class OpenAIProviderError(RuntimeError):
    """Raised when OpenAI recognition cannot complete."""


class OpenAIInvalidResponseError(OpenAIProviderError):
    """Raised when OpenAI returns output that cannot be parsed."""


class OpenAITimeoutError(OpenAIProviderError):
    """Raised when the OpenAI request times out."""


class OpenAIRecognitionProvider(AIRecognitionProvider):
    provider_name = "openai"
    responses_url = "https://api.openai.com/v1/responses"

    def __init__(
        self,
        *,
        api_key: str | None = None,
        model: str | None = None,
        timeout_seconds: float | None = None,
        client: httpx.Client | None = None,
    ) -> None:
        self._api_key = settings.openai_api_key if api_key is None else api_key
        self._model = model or settings.openai_model
        self._timeout_seconds = (
            settings.openai_timeout_seconds
            if timeout_seconds is None
            else timeout_seconds
        )
        self._client = client or httpx.Client(timeout=self._timeout_seconds)

    def recognize(self, image_path: Path) -> RecognitionResult:
        if not self._api_key.strip():
            raise AIProviderNotConfiguredError(
                "OPENAI_API_KEY is required when AI_PROVIDER=openai."
            )

        started_at = time.perf_counter()
        payload = self._build_payload(image_path)

        try:
            response = self._client.post(
                self.responses_url,
                headers={
                    "Authorization": f"Bearer {self._api_key}",
                    "Content-Type": "application/json",
                },
                json=payload,
                timeout=self._timeout_seconds,
            )
        except httpx.TimeoutException as exc:
            raise OpenAITimeoutError("OpenAI recognition request timed out.") from exc
        except httpx.HTTPError as exc:
            raise OpenAIProviderError(
                f"OpenAI recognition request failed: {exc}"
            ) from exc

        if response.status_code >= 400:
            raise OpenAIProviderError(
                "OpenAI recognition request failed with "
                f"status {response.status_code}: {response.text}"
            )

        try:
            response_body = response.json()
        except ValueError as exc:
            raise OpenAIInvalidResponseError(
                "OpenAI response body was not valid JSON."
            ) from exc

        result_payload = self._extract_structured_output(response_body)
        processing_time_ms = int((time.perf_counter() - started_at) * 1000)
        return self._to_recognition_result(result_payload, processing_time_ms)

    def _build_payload(self, image_path: Path) -> dict[str, Any]:
        encoded_image = base64.b64encode(image_path.read_bytes()).decode("ascii")
        media_type = self._media_type_for(image_path)

        return {
            "model": self._model,
            "input": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "input_text",
                            "text": (
                                "Identify this collectible and estimate its "
                                "collector profile. Return conservative, "
                                "realistic values in Australian dollars. "
                                "Include reasoning, detection quality, and "
                                "exactly three plausible alternative matches."
                            ),
                        },
                        {
                            "type": "input_image",
                            "image_url": f"data:{media_type};base64,{encoded_image}",
                        },
                    ],
                }
            ],
            "text": {
                "format": {
                    "type": "json_schema",
                    "name": "collectible_recognition",
                    "strict": True,
                    "schema": {
                        "type": "object",
                        "additionalProperties": False,
                        "required": [
                            "title",
                            "category",
                            "confidence",
                            "estimatedValue",
                            "condition",
                            "recommendation",
                            "description",
                            "detectedObjects",
                            "primaryMatch",
                            "alternativeMatches",
                            "confidenceExplanation",
                            "detectionQuality",
                            "aiReasoning",
                        ],
                        "properties": {
                            "title": {"type": "string"},
                            "category": {"type": "string"},
                            "confidence": {
                                "type": "integer",
                                "minimum": 0,
                                "maximum": 100,
                            },
                            "estimatedValue": {
                                "type": "integer",
                                "minimum": 0,
                            },
                            "condition": {"type": "string"},
                            "recommendation": {"type": "string"},
                            "description": {"type": "string"},
                            "detectedObjects": {
                                "type": "array",
                                "items": {"type": "string"},
                            },
                            "primaryMatch": {"type": "string"},
                            "alternativeMatches": {
                                "type": "array",
                                "minItems": 3,
                                "maxItems": 3,
                                "items": {
                                    "type": "object",
                                    "additionalProperties": False,
                                    "required": [
                                        "title",
                                        "category",
                                        "confidence",
                                        "reason",
                                    ],
                                    "properties": {
                                        "title": {"type": "string"},
                                        "category": {"type": "string"},
                                        "confidence": {
                                            "type": "integer",
                                            "minimum": 0,
                                            "maximum": 100,
                                        },
                                        "reason": {"type": "string"},
                                    },
                                },
                            },
                            "confidenceExplanation": {"type": "string"},
                            "detectionQuality": {"type": "string"},
                            "aiReasoning": {"type": "string"},
                        },
                    },
                }
            },
        }

    def _extract_structured_output(self, response_body: dict[str, Any]) -> dict[str, Any]:
        output_text = response_body.get("output_text")
        if isinstance(output_text, str) and output_text.strip():
            return self._parse_json_object(output_text)

        for output_item in response_body.get("output", []):
            if not isinstance(output_item, dict):
                continue
            for content_item in output_item.get("content", []):
                if not isinstance(content_item, dict):
                    continue
                text = content_item.get("text")
                if isinstance(text, str) and text.strip():
                    return self._parse_json_object(text)

        raise OpenAIInvalidResponseError(
            "OpenAI response did not include structured output text."
        )

    def _parse_json_object(self, output_text: str) -> dict[str, Any]:
        try:
            parsed = json.loads(output_text)
        except json.JSONDecodeError as exc:
            raise OpenAIInvalidResponseError(
                "OpenAI structured output was not valid JSON."
            ) from exc

        if not isinstance(parsed, dict):
            raise OpenAIInvalidResponseError(
                "OpenAI structured output must be a JSON object."
            )
        return parsed

    def _to_recognition_result(
        self,
        payload: dict[str, Any],
        processing_time_ms: int,
    ) -> RecognitionResult:
        required_string_fields = [
            "title",
            "category",
            "condition",
            "recommendation",
            "description",
            "primaryMatch",
            "confidenceExplanation",
            "detectionQuality",
            "aiReasoning",
        ]
        for field in required_string_fields:
            value = payload.get(field)
            if not isinstance(value, str) or not value.strip():
                raise OpenAIInvalidResponseError(
                    f"OpenAI structured output missing string field '{field}'."
                )

        detected_objects = payload.get("detectedObjects")
        if not isinstance(detected_objects, list) or not all(
            isinstance(item, str) and item.strip() for item in detected_objects
        ):
            raise OpenAIInvalidResponseError(
                "OpenAI structured output missing detectedObjects list."
            )

        alternative_matches = self._parse_alternative_matches(payload)

        try:
            confidence = int(payload["confidence"])
            estimated_value = int(payload["estimatedValue"])
        except (KeyError, TypeError, ValueError) as exc:
            raise OpenAIInvalidResponseError(
                "OpenAI structured output had invalid numeric fields."
            ) from exc

        return RecognitionResult(
            title=payload["title"].strip(),
            category=payload["category"].strip(),
            confidence=max(0, min(confidence, 100)),
            estimatedValue=max(0, estimated_value),
            condition=payload["condition"].strip(),
            recommendation=payload["recommendation"].strip(),
            description=payload["description"].strip(),
            detectedObjects=[item.strip() for item in detected_objects],
            aiProvider=self.provider_name,
            processingTimeMs=max(1, processing_time_ms),
            primaryMatch=payload["primaryMatch"].strip(),
            alternativeMatches=alternative_matches,
            confidenceExplanation=payload["confidenceExplanation"].strip(),
            detectionQuality=payload["detectionQuality"].strip(),
            aiReasoning=payload["aiReasoning"].strip(),
        )

    def _parse_alternative_matches(
        self,
        payload: dict[str, Any],
    ) -> list[AlternativeMatch]:
        raw_matches = payload.get("alternativeMatches")
        if not isinstance(raw_matches, list) or len(raw_matches) != 3:
            raise OpenAIInvalidResponseError(
                "OpenAI structured output must include exactly three alternative matches."
            )

        matches: list[AlternativeMatch] = []
        for raw_match in raw_matches:
            if not isinstance(raw_match, dict):
                raise OpenAIInvalidResponseError(
                    "OpenAI alternative matches must be JSON objects."
                )

            required_fields = ["title", "category", "reason"]
            for field in required_fields:
                value = raw_match.get(field)
                if not isinstance(value, str) or not value.strip():
                    raise OpenAIInvalidResponseError(
                        "OpenAI alternative match missing string field "
                        f"'{field}'."
                    )

            try:
                confidence = int(raw_match["confidence"])
            except (KeyError, TypeError, ValueError) as exc:
                raise OpenAIInvalidResponseError(
                    "OpenAI alternative match had invalid confidence."
                ) from exc

            matches.append(
                AlternativeMatch(
                    title=raw_match["title"].strip(),
                    category=raw_match["category"].strip(),
                    confidence=max(0, min(confidence, 100)),
                    reason=raw_match["reason"].strip(),
                )
            )

        return matches

    def _media_type_for(self, image_path: Path) -> str:
        extension = image_path.suffix.lower()
        if extension in {".jpg", ".jpeg"}:
            return "image/jpeg"
        if extension == ".png":
            return "image/png"
        return "application/octet-stream"
