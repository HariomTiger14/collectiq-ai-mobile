from collections.abc import Callable

from app.core.config import settings
from app.schemas.api_analysis import ApiAnalyzeRequest
from app.services.ai.base_recognition_service import RecognitionResult
from app.services.ai.provider_factory import get_ai_recognition_provider
from app.services.analyzer.providers import (
    BackendAnalyzerProvider,
    GeminiAnalyzerProvider,
    MockAnalyzerProvider,
    OpenAIAnalyzerProvider,
    recognize_with_legacy_provider,
)


class BackendAnalyzerService:
    """Server-side analyzer boundary used by the production mobile contract."""

    def __init__(
        self,
        provider_factory: Callable[[str | None], object] | None = None,
    ) -> None:
        self._provider_factory = provider_factory

    def analyze(self, payload: ApiAnalyzeRequest) -> tuple[object, RecognitionResult]:
        provider = self._resolve_provider()
        recognition = recognize_with_legacy_provider(
            provider,
            request_metadata=_model_to_dict(payload.request),
            image_payload=_model_to_dict(payload.image),
        )
        return provider, recognition

    def _resolve_provider(self) -> BackendAnalyzerProvider | object:
        if self._provider_factory is not None:
            return self._provider_factory(None)

        selected_provider = settings.ai_provider.strip().lower()
        if selected_provider == "mock":
            return MockAnalyzerProvider()
        if selected_provider == "openai":
            return OpenAIAnalyzerProvider()
        if selected_provider == "gemini":
            return GeminiAnalyzerProvider()

        return get_ai_recognition_provider(selected_provider)


def _model_to_dict(model) -> dict:
    if hasattr(model, "model_dump"):
        return model.model_dump()
    return model.dict()

