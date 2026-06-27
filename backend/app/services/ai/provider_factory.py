from app.core.config import settings
from app.services.ai.base_recognition_service import AIRecognitionService
from app.services.ai.mock_recognition_service import MockRecognitionService


def get_ai_recognition_service() -> AIRecognitionService:
    if settings.ai_provider.lower() == "mock":
        return MockRecognitionService()

    return MockRecognitionService()
