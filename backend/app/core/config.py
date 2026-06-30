import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parents[3]
BACKEND_ROOT = Path(__file__).resolve().parents[2]
UPLOAD_DIR = PROJECT_ROOT / "uploads"
MAX_IMAGE_BYTES = 10 * 1024 * 1024
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png"}
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png"}
CHUNK_SIZE = 1024 * 1024

load_dotenv(BACKEND_ROOT / ".env")


@dataclass(frozen=True)
class Settings:
    ai_provider: str = os.getenv("AI_PROVIDER", "mock")
    pricing_provider: str = os.getenv("PRICING_PROVIDER", "mock")
    openai_api_key: str = os.getenv("OPENAI_API_KEY", "")
    openai_model: str = os.getenv("OPENAI_MODEL", "gpt-4.1-mini")
    openai_timeout_seconds: float = float(os.getenv("OPENAI_TIMEOUT_SECONDS", "30"))
    ebay_access_token: str = os.getenv("EBAY_ACCESS_TOKEN", "")
    ebay_browse_api_url: str = os.getenv(
        "EBAY_BROWSE_API_URL",
        "https://api.ebay.com/buy/browse/v1/item_summary/search",
    )
    ebay_marketplace_id: str = os.getenv("EBAY_MARKETPLACE_ID", "EBAY_AU")
    ebay_timeout_seconds: float = float(os.getenv("EBAY_TIMEOUT_SECONDS", "10"))
    tcgplayer_client_id: str = os.getenv("TCGPLAYER_CLIENT_ID", "")
    tcgplayer_client_secret: str = os.getenv("TCGPLAYER_CLIENT_SECRET", "")
    tcgplayer_api_base: str = os.getenv(
        "TCGPLAYER_API_BASE",
        "https://api.tcgplayer.com",
    )
    tcgplayer_timeout_seconds: float = float(
        os.getenv("TCGPLAYER_TIMEOUT_SECONDS", "10")
    )
    pricecharting_api_key: str = os.getenv("PRICECHARTING_API_KEY", "")
    pricecharting_api_base: str = os.getenv(
        "PRICECHARTING_API_BASE",
        "https://www.pricecharting.com",
    )
    pricecharting_timeout_seconds: float = float(
        os.getenv("PRICECHARTING_TIMEOUT_SECONDS", "10")
    )
    pricing_cache_ttl_seconds: int = int(os.getenv("PRICING_CACHE_TTL_SECONDS", "900"))
    pricing_provider_min_interval_ms: int = int(
        os.getenv("PRICING_PROVIDER_MIN_INTERVAL_MS", "250")
    )


settings = Settings()
