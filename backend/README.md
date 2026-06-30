# CollectIQ AI Backend

FastAPI backend for CollectIQ AI analysis, portfolio, and future provider
integrations.

## Current MVP

- `GET /health`
- `POST /scanner/analyze` for multipart scanner uploads
- `POST /api/analyze` for the Flutter backend AI contract
- Mock AI recognition
- Backend pricing provider pipeline with mock fallback

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

Pricing selection:

- `PRICING_PROVIDER=mock`: default deterministic pricing and comparable sales.
- `PRICING_PROVIDER=ebay`: backend-only placeholder for completed sales.
- `PRICING_PROVIDER=tcgplayer`: backend-only placeholder for card pricing.
- `PRICING_PROVIDER=pricecharting`: backend-only placeholder for guide pricing.
- `PRICING_PROVIDER=aggregate`: future multi-provider blend.

Future pricing providers currently return typed unavailable errors that the
aggregation service converts to mock fallback pricing. Flutter still receives
the same response contract, and no third-party pricing API is called from the
mobile app.

When OpenAI is enabled, the backend sends the image to OpenAI's Responses API
with a strict structured-output schema. The prompt asks for collectible
identification, conservative AUD valuation, confidence explanation, detection
quality, reasoning, exactly three alternatives, and rich profile metadata. The
backend then normalizes that provider response into Flutter's
`AiBackendAnalysisResponse` contract.

The prompt also asks OpenAI to:

- identify item name, franchise/brand, category, set/series, year, visible
  number, manufacturer/publisher, language, edition/variant, and raw grading
  likelihood;
- return a 0-100 confidence score for each extracted field;
- avoid inventing data and use `null` or `Unknown` when details are not visible;
- classify confidence as `High` (90-100), `Medium` (70-89), or `Low` (<70);
- report low-confidence reasons and missing visual evidence;
- identify image-quality issues such as blur, glare/reflections, cropped edges,
  dark image, low resolution, and multiple collectibles in one photo;
- return actionable scan recommendations.

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

### Confidence Interpretation

- `High`: 90-100. The primary identity is likely, but users should still verify
  high-value items manually.
- `Medium`: 70-89. The broad item family is plausible, but details such as set,
  card number, issue, mint mark, or edition may need another scan.
- `Low`: below 70. Treat the result as a suggestion; retake the image or inspect
  manually before saving or valuing the item.

`fieldConfidence` reports confidence for individual fields, so a result may have
a high category match but lower confidence for year, number, edition, or grade.

### Image Capture Best Practices

- Use bright, even lighting.
- Avoid glare, sleeves with reflections, and dark backgrounds.
- Keep the full collectible inside the frame.
- Capture one collectible at a time.
- Retake if small text, set symbols, mint marks, issue numbers, or card numbers
  are blurry.
- Use a second close-up image later when adding multi-image analysis.

### Known AI Limitations

- AI estimates are not authentication, grading, or appraisal.
- Small print may be unreadable from normal phone distance.
- Reprints, variants, language differences, and editions can look very similar.
- Market value uses deterministic backend mock/fallback pricing until real
  pricing provider credentials and API mappings are enabled.
- Low-quality images should produce lower confidence and scan guidance rather
  than invented details.

### Prompt Engineering Guidelines

- Prefer conservative identification over overconfident claims.
- Ask for `null`/`Unknown` for unseen fields.
- Keep schema stable for Flutter.
- Add category-specific examples only when they improve structured output.
- Do not log full prompts or image payloads in production.
- Use `backend/tests/test_assets/manifest.json` as the golden dataset manifest.
  Current rows are placeholders until licensed or user-owned images are added.

## Pricing Architecture

Pricing is backend-only. Flutter sends images to the CollectIQ backend, the AI
provider identifies the collectible, and the backend pricing pipeline enriches
the result before returning the existing Flutter contract.

The pricing layer contains:

- `PricingProvider`: interface for provider implementations.
- `MockPricingProvider`: deterministic default used in tests and local dev.
- `EbayPricingProvider`: placeholder for completed/sold marketplace comps.
- `TCGPlayerPricingProvider`: placeholder for trading-card price guides.
- `PriceChartingPricingProvider`: placeholder for historical guide pricing.
- `PricingAggregationService`: normalizes comparable sales, removes obvious
  outliers, calculates estimated value/range/confidence/trend, and falls back
  safely when providers are unavailable.

Aggregation calculates:

- `estimatedValue`
- `lowEstimate`
- `highEstimate`
- `pricingConfidence`
- `marketTrend`
- `sourceCount`
- `pricingAge`
- recent comparable sales

### Pricing Error Handling

Provider failures should never crash analysis. The pipeline handles:

- provider unavailable
- timeout
- empty market data
- unsupported or incomplete provider data
- future rate-limit errors

If configured providers fail, the backend returns deterministic mock fallback
pricing with diagnostics marking `fallbackUsed=true`.

### Pricing Diagnostics

Debug logs include provider count, response time, fallback usage, cache status,
and pricing source count. Logs must not include provider API keys, payment
tokens, or raw third-party credentials.

### Future Cache Strategy

Before enabling real providers, add a backend cache keyed by normalized
collectible identity fields such as category, title, year, set, card number,
grade/condition, language, and edition. Recommended first pass:

- short TTL for marketplace sold comps;
- longer TTL for guide prices;
- stale-while-revalidate for repeated scans;
- per-provider cache status in diagnostics.

### Future Rate Limiting Strategy

Real pricing providers should be protected by:

- server-side API keys only;
- per-provider timeout budgets;
- request retries with backoff for retryable errors;
- per-user/backend rate limits;
- provider-specific quota monitoring;
- graceful fallback to cached or mock pricing when limits are reached.

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
