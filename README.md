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

### Flutter AI Provider Safety

The Flutter app must not call OpenAI directly and must not receive OpenAI or
Gemini API keys through source code, `--dart-define`, local storage, or bundled
configuration.

Flutter provider selection is limited to safe client-side routing:

```text
AI_ANALYSIS_PROVIDER=mock
AI_BACKEND_ANALYSIS_ENDPOINT_URL=https://your-backend.example/scanner/analyze
```

`AI_ANALYSIS_PROVIDER=mock` remains the default. Future OpenAI or Gemini mobile
flows should send images only to the CollectIQ AI backend/proxy, where API keys
stay server-side.

### Future Backend AI Contract

The prepared mobile contract is:

```text
Flutter selected image
-> CollectIQ AI backend endpoint
-> server-side AI provider and pricing services
-> Flutter-compatible analysis response
```

Flutter request metadata is represented by `AiBackendAnalysisRequest` and may
include the local image path/reference, image source (`camera` or `gallery`),
requested category, safe app/device metadata, and timestamp. The image file
itself can be sent later as multipart upload to the backend endpoint.

Backend responses are represented by `AiBackendAnalysisResponse` and map into
the existing scanner `ScanResult`, including item name, category, value/range,
confidence, condition, market trend, key attributes, AI review, alternatives,
recommendation, market summary, and comparable sales. UI screens should continue
to consume `ScanResult` rather than backend DTOs directly.

`AiBackendAnalysisError` is the safe error shape for backend/proxy failures.
OpenAI, Gemini, pricing-provider, and marketplace credentials must remain on the
backend and must never be exposed to Flutter.

### Backend AI Client Skeleton

The mobile app now has an `AiBackendClient` boundary for future backend-based
analysis calls. The current implementation is `NoopAiBackendClient`, which makes
no network requests and returns user-safe errors for missing endpoints,
timeouts, unavailable networks, invalid responses, backend error payloads, and
malformed JSON.

`OpenAiVisionAnalysisProvider` is wired through this client, but still performs
no paid AI calls. If `AI_ANALYSIS_PROVIDER=openai_vision` is selected before the
backend integration is implemented, the scan flow shows a safe inline error such
as:

```text
Backend AI endpoint not configured. OpenAI Vision must run through the CollectIQ AI backend.
```

When a real client is added later, it should call only
`AI_BACKEND_ANALYSIS_ENDPOINT_URL`, parse `AiBackendAnalysisResponse`, and map
any transport/backend failure to `AiBackendClientException` so the scanner can
continue showing friendly offline-safe errors.

### Future Image Upload Payload

Before a future backend request is sent, Flutter prepares validated image
metadata with `AiImageUploadPayload`:

```text
fileName
mimeType
sizeBytes
imageSource
localFilePath
optional base64Preview placeholder
```

The payload preparer verifies that the local file exists, has a supported image
extension/MIME type, is non-empty, and is under the configured maximum size
(10 MB by default). Supported MIME types are JPG/JPEG, PNG, WEBP, HEIC, and
HEIF. Unsupported, missing, empty, or oversized images are converted into
friendly scan errors instead of raw file exceptions.

`AiBackendApiService` defines the future `analyzeImage(...)` service shape. The
current `NoopAiBackendApiService` does not call the network and exists only to
exercise safe request, payload, response, and error mapping. A real
implementation should send the validated image to the CollectIQ backend/proxy
only; AI provider keys remain backend-only.

### Market Pricing Data Foundation

Live collectible pricing is prepared behind a separate `MarketPricingProvider`
boundary so valuation can evolve independently from AI recognition. The pricing
request includes recognized item metadata such as title, category, condition,
year, brand, set name, card number, player/character, preferred currency, and an
optional pricing date.

`MarketPricingResult` returns:

```text
estimatedValue
lowEstimate
highEstimate
currency
marketTrend
recent comparable sales
confidence
sourceLabel
lastUpdated
```

The default `MockMarketPricingProvider` generates deterministic local pricing,
value ranges, trend labels, confidence, source labels, and comparable sales. It
does not call any live market APIs. Results can be converted into the existing
`PricingInfo` and `MarketSummary` models when scan-result enrichment is wired in
later.

Prepared future providers are:

```text
eBay completed sales
TCGplayer card pricing
PriceCharting
custom backend pricing
```

These placeholders return friendly not-enabled errors today. Real marketplace
API keys and paid pricing integrations must live only on the CollectIQ backend,
never in Flutter source, `--dart-define`, local storage, or bundled config.

### Scan Result Enrichment Pipeline

Scanner analysis now flows through a dedicated enrichment boundary:

```text
AI analysis provider
-> ScanResultEnrichmentService
-> MarketPricingProvider
-> final ScanResult for the existing UI
```

The enrichment service preserves AI recognition details such as title, category,
confidence, AI review, alternatives, and recommendation, then applies pricing
provider output to the existing `PricingInfo` and `MarketSummary` fields. If
pricing fails or is unavailable, the scan still completes with the AI result and
safe pricing defaults labelled `Mock pricing unavailable`.

## Supabase Cloud Foundation

CollectIQ AI is local-first by default. Supabase is optional infrastructure for
future account and cloud sync features; do not put real Supabase secrets in
source control.

### Create a Supabase project

1. Create a project at <https://supabase.com>.
2. Open Project Settings -> API.
3. Copy the Project URL.
4. Copy the anon public key.
5. Keep service-role keys out of the Flutter app.

### Run the schema

Run the SQL in:

```text
supabase/migrations/202606290001_collectiq_cloud_schema.sql
```

You can paste it into the Supabase SQL Editor or run it with the Supabase CLI.
The schema creates:

- `users`
- `collections`
- `collectibles`
- `scan_history`
- `pricing_snapshots`
- `favorites`
- `wishlist`

Row Level Security is enabled on every table. Policies restrict rows to
`auth.uid()` so users can only read, insert, update, or delete their own data.
The migration also creates a profile trigger that mirrors new `auth.users`
records into `public.users`.

### Run Flutter with Supabase configuration

Supabase remains disabled unless explicitly enabled with dart defines:

```powershell
flutter run `
  --dart-define=SUPABASE_ENABLED=true `
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-anon-public-key
```

Without these values, the app continues in guest/local-first mode and stores the
portfolio locally.

### Auth test plan

Use `docs/supabase_auth_test_plan.md` to validate:

- guest mode
- anonymous sign-in
- email/password sign-in
- sign out

Authentication is foundation-only right now. The app must not require login to
scan, save, view, search, sort, or delete local portfolio items.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Android Release Checklist

Release readiness items now covered in the Android shell:

- App label is `CollectIQ AI` through `android/app/src/main/res/values/strings.xml`.
- A placeholder adaptive launcher icon is provided for Android 8+ while the
  final brand icon is pending.
- Splash background and splash mark use CollectIQ colors instead of the default
  white Flutter launch screen.
- Main manifest permissions are limited to `INTERNET` and `CAMERA`.
- Android Photo Picker is used for gallery selection, so no broad media storage
  permission is required for Android 13+ gallery uploads.
- Cleartext HTTP traffic is enabled only in the debug manifest for local backend
  testing.
- Release builds suppress noisy `debugPrint` output with `kReleaseMode`.
- Release signing can use environment variables without committing secrets:

```powershell
$env:COLLECTIQ_UPLOAD_KEYSTORE="C:\path\to\upload-keystore.jks"
$env:COLLECTIQ_UPLOAD_STORE_PASSWORD="store-password"
$env:COLLECTIQ_UPLOAD_KEY_ALIAS="upload"
$env:COLLECTIQ_UPLOAD_KEY_PASSWORD="key-password"
```

If these values are absent, the local release APK build falls back to the debug
signing key for verification only. Do not ship a Play Store release signed with
the debug key.

Before distributing a build, run:

```powershell
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

`flutter build appbundle --release` requires a complete Android SDK command-line
tools installation. If Flutter reports that it cannot check or strip native
debug symbols, install Android SDK Command-line Tools in Android Studio and run:

```powershell
flutter doctor --android-licenses
```

Manual release checks:

- Launch on a physical Android device.
- Confirm camera capture, gallery selection, analyze, save, portfolio, and
  detail navigation still work.
- Confirm Android back navigation works on Android 13+.
- Confirm Supabase/backend dart defines are supplied only for environments that
  need them.
- Replace the placeholder launcher icon with final store artwork before public
  release.
