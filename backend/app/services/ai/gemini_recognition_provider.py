import base64
import logging
import time
from pathlib import Path
from typing import Any

import httpx

from app.core.config import settings
from app.services.ai.openai_recognition_provider import (
    AIProviderNotConfiguredError,
    OpenAIInvalidResponseError,
    OpenAIProviderError,
    OpenAIRecognitionProvider,
    OpenAITimeoutError,
)

logger = logging.getLogger("collectiq.ai.gemini")


class GeminiProviderError(OpenAIProviderError):
    """Raised when Gemini recognition cannot complete."""


class GeminiInvalidResponseError(OpenAIInvalidResponseError):
    """Raised when Gemini returns output that cannot be parsed."""


class GeminiTimeoutError(OpenAITimeoutError):
    """Raised when the Gemini request times out."""


class GeminiRecognitionProvider(OpenAIRecognitionProvider):
    provider_name = "gemini"

    def __init__(
        self,
        *,
        api_key: str | None = None,
        model: str | None = None,
        timeout_seconds: float | None = None,
        client: httpx.Client | None = None,
    ) -> None:
        self._api_key = settings.gemini_api_key if api_key is None else api_key
        self._model = model or settings.gemini_model
        self._timeout_seconds = (
            settings.gemini_timeout_seconds
            if timeout_seconds is None
            else timeout_seconds
        )
        self._client = client or httpx.Client(timeout=self._timeout_seconds)

    def recognize(self, image_path: Path):
        if not self._api_key.strip():
            raise AIProviderNotConfiguredError(
                "GEMINI_API_KEY is required when AI_PROVIDER=gemini."
            )

        encoded_image = base64.b64encode(image_path.read_bytes()).decode("ascii")
        payload = self._build_gemini_payload(
            image_base64=encoded_image,
            mime_type=self._media_type_for(image_path),
            prompt_context={
                "imageSource": "uploaded file",
                "fileName": image_path.name,
                "mimeType": self._media_type_for(image_path),
                "requestedCategory": "none",
                "appVersion": "unknown",
            },
        )
        return self._recognize_with_gemini_payload(payload, time.perf_counter())

    def recognize_api_payload(
        self,
        *,
        request_metadata: dict,
        image_payload: dict,
    ):
        if not self._api_key.strip():
            raise AIProviderNotConfiguredError(
                "GEMINI_API_KEY is required when AI_PROVIDER=gemini."
            )

        image_parts = self._image_parts_from_payload(image_payload)
        payload = self._build_gemini_payload(
            image_parts=image_parts,
            prompt_context={
                "imageSource": request_metadata.get("imageSource")
                or image_payload.get("imageSource")
                or "unknown",
                "requestedCategory": request_metadata.get("requestedCategory")
                or "none",
                "fileName": image_payload.get("fileName") or "unknown",
                "mimeType": image_payload.get("mimeType") or "application/octet-stream",
                "appVersion": request_metadata.get("appVersion") or "unknown",
            },
        )
        return self._recognize_with_gemini_payload(payload, time.perf_counter())

    def _recognize_with_gemini_payload(
        self,
        payload: dict[str, Any],
        started_at: float,
    ):
        try:
            response = self._client.post(
                self._generate_content_url(),
                headers={"Content-Type": "application/json"},
                json=payload,
                timeout=self._timeout_seconds,
            )
        except httpx.TimeoutException as exc:
            raise GeminiTimeoutError("Gemini recognition request timed out.") from exc
        except httpx.HTTPError as exc:
            raise GeminiProviderError(
                f"Gemini recognition request failed: {exc}"
            ) from exc

        if response.status_code >= 400:
            raise GeminiProviderError(
                "Gemini recognition request failed with "
                f"status {response.status_code}: {response.text}"
            )

        try:
            response_body = response.json()
        except ValueError as exc:
            raise GeminiInvalidResponseError(
                "Gemini response body was not valid JSON."
            ) from exc

        output_text = self._extract_gemini_text(response_body)
        result_payload = self._parse_json_object(output_text)
        processing_time_ms = int((time.perf_counter() - started_at) * 1000)
        if logger.isEnabledFor(logging.DEBUG):
            logger.debug(
                "Gemini recognition provider=%s model=%s latencyMs=%s",
                self.provider_name,
                self._model,
                processing_time_ms,
            )
        return self._to_recognition_result(result_payload, processing_time_ms)

    def _build_gemini_payload(
        self,
        *,
        image_parts: list[dict[str, Any]] | None = None,
        image_base64: str | None = None,
        mime_type: str | None = None,
        prompt_context: dict[str, Any],
    ) -> dict[str, Any]:
        parts: list[dict[str, Any]] = [{"text": self._prompt_text(prompt_context)}]
        if image_parts is not None:
            parts.extend(image_parts)
        elif image_base64 is not None and mime_type is not None:
            parts.append(
                {
                    "inline_data": {
                        "mime_type": mime_type,
                        "data": image_base64,
                    },
                }
            )
        return {
            "contents": [
                {
                    "role": "user",
                    "parts": parts,
                }
            ],
            "generationConfig": {
                "temperature": 0.1,
                "response_mime_type": "application/json",
            },
        }

    def _generate_content_url(self) -> str:
        return (
            "https://generativelanguage.googleapis.com/v1beta/models/"
            f"{self._model}:generateContent?key={self._api_key}"
        )

    def _extract_gemini_text(self, response_body: dict[str, Any]) -> str:
        candidates = response_body.get("candidates")
        if not isinstance(candidates, list) or not candidates:
            raise GeminiInvalidResponseError(
                "Gemini response did not include candidates."
            )

        content = candidates[0].get("content")
        if not isinstance(content, dict):
            raise GeminiInvalidResponseError(
                "Gemini response candidate did not include content."
            )

        parts = content.get("parts")
        if not isinstance(parts, list):
            raise GeminiInvalidResponseError(
                "Gemini response content did not include parts."
            )

        for part in parts:
            if isinstance(part, dict) and isinstance(part.get("text"), str):
                text = part["text"].strip()
                if text:
                    return text

        raise GeminiInvalidResponseError(
            "Gemini response did not include structured output text."
        )

    def _split_data_url(self, data_url: str) -> tuple[str, str]:
        prefix, _, encoded_image = data_url.partition(",")
        if not encoded_image:
            raise GeminiProviderError("Gemini image payload was empty.")

        mime_type = "application/octet-stream"
        if prefix.startswith("data:") and ";base64" in prefix:
            mime_type = prefix.removeprefix("data:").split(";", 1)[0]
        return mime_type, encoded_image

    def _image_parts_from_payload(self, image_payload: dict) -> list[dict[str, Any]]:
        raw_images = image_payload.get("images")
        payloads = raw_images if isinstance(raw_images, list) and raw_images else [image_payload]
        parts: list[dict[str, Any]] = []
        for payload in payloads:
            if not isinstance(payload, dict):
                continue
            image_data_url = self._image_data_url_from_api_payload(payload)
            mime_type, image_base64 = self._split_data_url(image_data_url)
            parts.append(
                {
                    "inline_data": {
                        "mime_type": mime_type,
                        "data": image_base64,
                    },
                }
            )
        return parts
