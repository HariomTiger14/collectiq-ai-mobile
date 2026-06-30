# CollectIQ AI Backend

FastAPI backend for CollectIQ AI analysis, portfolio, and future provider
integrations.

## Current MVP

- `GET /health`
- `POST /scanner/analyze` for multipart scanner uploads
- `POST /api/analyze` for the Flutter backend AI contract
- Mock AI recognition
- Mock pricing

The backend is the only place future OpenAI, Gemini, pricing, marketplace, or
payment provider keys should live. Flutter must call this backend/proxy only.
`AI_PROVIDER=mock` is the default, so `/api/analyze` returns mock analysis unless
OpenAI is explicitly selected in backend `.env`.

## Local Setup

From the repository root:

```powershell
cd backend
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Health check:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
```

Android emulator Flutter config for future backend testing:

```powershell
flutter run `
  --dart-define=AI_ANALYSIS_PROVIDER=openai_vision `
  --dart-define=AI_BACKEND_ANALYSIS_ENDPOINT_URL=http://10.0.2.2:8000/api/analyze
```

Physical Android device on the same network:

```powershell
flutter run `
  --dart-define=AI_ANALYSIS_PROVIDER=openai_vision `
  --dart-define=AI_BACKEND_ANALYSIS_ENDPOINT_URL=http://YOUR_LAN_IP:8000/api/analyze
```

Mock mode remains the Flutter default and makes no backend AI calls.

## Environment

Copy `.env.example` to `.env`.

```text
AI_PROVIDER=mock
PRICING_PROVIDER=mock
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4.1-mini
OPENAI_TIMEOUT_SECONDS=30
```

For v1.0 preparation, keep `AI_PROVIDER=mock` until the production backend AI
provider is intentionally enabled. If `AI_PROVIDER=openai` is selected without
`OPENAI_API_KEY`, `/api/analyze` returns a safe `ai_provider_not_configured`
error instead of making a provider call. Do not commit real secrets.

## POST /api/analyze

This endpoint accepts the JSON envelope prepared by Flutter's backend client:

```json
{
  "request": {
    "imagePath": "/local/app/path/card.jpg",
    "imageSource": "camera",
    "requestedCategory": "Pokemon Card",
    "appVersion": "1.0.0",
    "deviceMetadata": {},
    "timestamp": "2026-06-30T09:00:00Z"
  },
  "image": {
    "fileName": "card.jpg",
    "mimeType": "image/jpeg",
    "sizeBytes": 123456,
    "imageSource": "camera",
    "localFilePath": "/local/app/path/card.jpg"
  }
}
```

The MVP returns mock recognition and mock pricing data shaped like Flutter's
`AiBackendAnalysisResponse`.

Provider selection:

- `AI_PROVIDER=mock`: default, no external calls.
- `AI_PROVIDER=openai`: OpenAI Vision provider path. Requires
  `OPENAI_API_KEY`; keep this key server-side in `backend/.env` only.

When OpenAI is enabled, the backend sends the image to OpenAI's Responses API
with a strict structured-output schema. The prompt asks for collectible
identification, conservative AUD valuation, confidence explanation, detection
quality, reasoning, exactly three alternatives, and rich profile metadata. The
backend then normalizes that provider response into Flutter's
`AiBackendAnalysisResponse` contract.

### Enable OpenAI Locally

OpenAI is opt-in and may incur API cost. Keep mock mode for normal development
and tests.

1. Copy `.env.example` to `.env`.
2. Set:

```text
AI_PROVIDER=openai
OPENAI_API_KEY=sk-your-server-side-key
OPENAI_MODEL=gpt-4.1-mini
OPENAI_TIMEOUT_SECONDS=30
```

3. Start the backend:

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Never pass `OPENAI_API_KEY` to Flutter with `--dart-define`, local storage, or
source code. Flutter should only know the CollectIQ backend URL.

### Error Responses

Errors use a backend-safe shape:

```json
{
  "success": false,
  "error": {
    "code": "missing_image",
    "message": "Image metadata is required.",
    "retryable": false,
    "details": {}
  }
}
```

Implemented MVP errors:

- `missing_image` with HTTP 400
- `invalid_payload` with HTTP 422
- `unsupported_category` with HTTP 422
- `ai_provider_not_configured` with HTTP 501
- `ai_provider_timeout` with HTTP 504
- `ai_provider_invalid_response` with HTTP 502
- `ai_provider_error` with HTTP 502
- `server_error` with HTTP 500

## Tests

From the `backend` folder:

```powershell
py -m unittest discover tests
```
