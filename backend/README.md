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
provider is intentionally enabled. Do not commit real secrets.

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
- `server_error` with HTTP 500

## Tests

From the `backend` folder:

```powershell
py -m unittest discover tests
```
