# collectiq_ai

A new Flutter project.

## Backend

The local scanner backend is a FastAPI app in `backend/`.

Install and run it from the project root:

```powershell
cd backend
py -m pip install -r requirements.txt
py -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Swagger is available at:

```text
http://127.0.0.1:8000/docs
```

The scanner endpoint remains:

```text
POST http://127.0.0.1:8000/scanner/analyze
multipart field: image
```

Uploaded images are saved to `uploads/`, and the endpoint returns the same
scanner analysis response shape for both mock and OpenAI providers.

### AI Provider

Backend AI recognition is selected with `backend/.env`:

```text
AI_PROVIDER=mock
```

Mock remains the default and does not require external credentials. To enable
OpenAI vision recognition, set:

```text
AI_PROVIDER=openai
OPENAI_API_KEY=sk-your-key
OPENAI_MODEL=gpt-4.1-mini
OPENAI_TIMEOUT_SECONDS=30
```

The OpenAI provider sends the uploaded image to the OpenAI Responses API and
requests strict structured JSON with these Flutter-compatible fields:

```json
{
  "title": "1952 Topps Mickey Mantle",
  "category": "Sports Card",
  "confidence": 92,
  "estimatedValue": 125000,
  "condition": "Good",
  "recommendation": "Authenticate and insure before sale.",
  "description": "Classic baseball card with strong collector demand.",
  "detectedObjects": ["Card", "Baseball", "Yankees"],
  "aiProvider": "openai",
  "processingTimeMs": 1240,
  "primaryMatch": "1952 Topps Mickey Mantle",
  "alternativeMatches": [
    {
      "title": "1953 Topps Mickey Mantle",
      "category": "Sports Card",
      "confidence": 73,
      "reason": "Same player and similar vintage card styling."
    },
    {
      "title": "1951 Bowman Mickey Mantle",
      "category": "Sports Card",
      "confidence": 68,
      "reason": "Same player rookie-era issue with related portrait cues."
    },
    {
      "title": "1952 Topps Baseball Common",
      "category": "Sports Card",
      "confidence": 56,
      "reason": "Same set layout, but player identity may differ."
    }
  ],
  "confidenceExplanation": "Strong card layout and player cues, but print details need confirmation.",
  "detectionQuality": "Good - subject and border are visible.",
  "aiReasoning": "The image matches vintage baseball card proportions and Yankees-era Mantle visual cues.",
  "year": "1952",
  "brand": "Topps",
  "setName": "Topps Baseball",
  "series": "MLB",
  "cardNumber": "311",
  "playerOrCharacter": "Mickey Mantle",
  "rarity": "Key Card",
  "estimatedGrade": "Good",
  "language": "English",
  "edition": "Base",
  "country": "United States",
  "mint": null,
  "material": "Cardstock",
  "notes": "Authentication recommended before insurance or resale.",
  "pricing": {
    "estimatedMarketValue": 125000,
    "lowEstimate": 97500,
    "highEstimate": 152500,
    "currency": "AUD",
    "pricingSource": "Mock market blend: eBay comps + PSA guide",
    "pricingConfidence": 83,
    "lastUpdated": "2026-06-29T00:00:00Z"
  }
}
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
