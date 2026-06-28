from pathlib import Path

from app.services.ai.base_recognition_service import (
    AIRecognitionProvider,
    RecognitionResult,
)


class AIProviderNotConfiguredError(RuntimeError):
    """Raised when a selected AI provider is not ready for recognition."""


class OpenAIRecognitionProvider(AIRecognitionProvider):
    provider_name = "openai"

    def recognize(self, image_path: Path) -> RecognitionResult:
        raise AIProviderNotConfiguredError(
            "OpenAI recognition provider is not configured yet. "
            "Set AI_PROVIDER=mock until OpenAI credentials and prompts are added."
        )
