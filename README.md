# collectiq_ai

A new Flutter project.

## Onboarding + First-Time UX

CollectIQ AI shows a first-launch onboarding screen that explains the core
flow:

```text
Scan -> Analyze -> Save -> Track
```

The onboarding also makes the local-first model explicit: users can scan,
analyze in mock/default mode, save to Portfolio, manage alerts, wishlist
status, and goals without signing in. Cloud sync and account sign-in remain
optional.

The completion flag is stored locally as:

```text
onboarding_completed_v1
```

Settings includes a **Reset Onboarding** action for QA, demos, and beta tester
handoffs.

## Closed Beta Preparation

Closed beta readiness is tracked in:

- `docs/CLOSED_BETA_READINESS.md`
- `docs/TESTER_FEEDBACK_TEMPLATE.md`
- `docs/KNOWN_LIMITATIONS.md`

Generate a physical-device smoke checklist for each release candidate with:

```powershell
scripts\run_beta_smoke_checklist.ps1
```

The beta pack covers Play Store internal testing, tester feedback capture,
known limitations, local-first/offline expectations, optional Supabase/backend
configuration, billing test setup, and final manual smoke checks. Do not commit
secrets or expose provider API keys in Flutter builds.

## Master QA Automation

CollectIQ AI includes a reusable local + attached Android device QA suite. The
suite runs in mock/default mode and must not call paid OpenAI, eBay, or other
external provider APIs.

Run the full QA suite from the project root:

```powershell
scripts\run_master_qa.ps1 -DeviceId RZ8R213M8ZL
```

If the attached Android Flutter test runner is unavailable or timing out, run
the stable local/build suite and keep native picker validation semi-automated:

```powershell
scripts\run_master_qa.ps1 -DeviceId RZ8R213M8ZL -SkipDeviceUi
```

Focused runners are also available:

```powershell
scripts\run_flutter_quality.ps1
scripts\run_backend_quality.ps1
scripts\run_device_ui_tests.ps1 -DeviceId RZ8R213M8ZL
scripts\run_camera_gallery_tests.ps1 -DeviceId RZ8R213M8ZL
scripts\run_persistence_tests.ps1 -DeviceId RZ8R213M8ZL
scripts\run_stress_tests.ps1 -DeviceId RZ8R213M8ZL
scripts\run_android_builds.ps1
```

All reports are written under:

```text
build/test_reports/
```

Coverage classification:

- Fully automated: Flutter format/analyze/tests, backend tests,
  Home/Scan/Portfolio/Detail/Settings widget flows, usage limit error, and
  Android debug/release builds.
- Attached-device automation: `run_device_ui_tests.ps1` runs the Flutter
  integration smoke suite when the host/device runner is stable.
- Semi-automated: native camera/gallery picker QA, ADB crash/log capture,
  force-stop persistence smoke, and stress repetitions.
- Manual-only: OEM permission dialog decisions, real camera/gallery image
  visual confirmation, airplane-mode validation, real Supabase/provider
  validation, and paid-provider validation.

See `docs/REAL_DEVICE_TEST_AUTOMATION.md` and
`docs/PRODUCTION_READINESS_AUDIT.md` for the full matrix and release checklist.

## Backend

The local scanner backend is a FastAPI app in `backend/`.

Install and run it from the project root:

```powershell
cd backend
py -m pip install -r requirements.txt
py -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
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

The Flutter backend AI contract endpoint is:

```text
POST http://127.0.0.1:8000/api/analyze
JSON body: { "request": { ... }, "image": { ... } }
```

### AI Provider

Backend AI recognition is selected with `backend/.env`:

```text
AI_PROVIDER=mock
```

Mock remains the default and does not require external credentials. To enable
OpenAI vision recognition, set:

```text
AI_PROVIDER=openai
OPENAI_API_KEY=<server-side-openai-key>
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
AI_BACKEND_ANALYSIS_ENDPOINT_URL=https://your-backend.example/api/analyze
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

### Backend AI Integration Checklist

Before enabling real backend analysis, verify:

- `AI_BACKEND_ANALYSIS_ENDPOINT_URL` is configured.
- The endpoint URL parses as valid `http` or `https`.
- Release builds use HTTPS only.
- Local HTTP endpoints such as `localhost`, `127.0.0.1`, `10.0.2.2`,
  `192.168.x.x`, `10.x.x.x`, or `172.16-31.x.x` are used only for debug/local
  testing.
- Flutter sends no OpenAI, Gemini, pricing, marketplace, service-role, or other
  privileged secrets.
- `AiBackendAnalysisRequest` passes validation before transport.
- Backend responses include required fields: item name, category, estimated
  value, confidence, condition, and recommendation.
- Optional fields use safe defaults so malformed or partial backend responses do
  not crash scanner, portfolio, or detail UI.

Contract validation helpers now cover:

```text
AiBackendContractValidator.validateRequest(...)
AiBackendContractValidator.validateResponsePayload(...)
AiBackendContractValidator.validateResponse(...)
AiBackendEndpointReadinessChecker.check(...)
```

Settings -> Developer Diagnostics shows whether the endpoint is configured,
valid, and release-safe. These checks do not call the network and do not enable
paid AI usage.

### Backend HTTP Client Disabled by Default

The app now includes a Dio-backed `DioAiBackendApiService` plus
`HttpAiBackendClient` for future server-side AI analysis. This path remains
disabled while `AI_ANALYSIS_PROVIDER=mock`, so normal development, tests, and
offline usage make no backend AI network calls.

To exercise the HTTP client against the local FastAPI backend, start the backend:

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Then run Flutter on an Android emulator with:

```powershell
flutter run `
  --dart-define=AI_ANALYSIS_PROVIDER=openai_vision `
  --dart-define=AI_BACKEND_ANALYSIS_ENDPOINT_URL=http://10.0.2.2:8000/api/analyze
```

For a physical Android device on the same Wi-Fi network, use your laptop LAN IP:

```powershell
flutter run `
  --dart-define=AI_ANALYSIS_PROVIDER=openai_vision `
  --dart-define=AI_BACKEND_ANALYSIS_ENDPOINT_URL=http://192.168.x.x:8000/api/analyze
```

For debug-only local backend testing, local HTTP endpoints such as
`http://10.0.2.2:8000/api/analyze` or
`http://192.168.x.x:8000/api/analyze` are allowed. Release builds must use
HTTPS. If the endpoint is missing, invalid, or not release-safe, the HTTP client
blocks the request before transport and the scanner shows a friendly inline
error.

The HTTP service maps backend failures safely:

- timeout -> retry-friendly timeout message
- network unavailable -> offline/network message
- non-200 response -> structured backend error
- malformed JSON -> readable response error
- invalid contract response -> invalid response error

The request body contains the validated `AiBackendAnalysisRequest` plus
`AiImageUploadPayload` metadata. It still targets only the CollectIQ backend; no
OpenAI, Gemini, pricing, marketplace, service-role, or other privileged keys are
stored in Flutter.

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

Production setup details live in `docs/SUPABASE_PRODUCTION_SETUP.md`, including
the SQL run order, RLS summary, private storage bucket policies, and validation
commands.

### Auth and cloud roadmap

The mobile app now uses an auth abstraction rather than depending directly on
Supabase from UI code:

```text
AuthRepository
-> AuthController/AuthState
-> Settings and future account screens
```

Current provider modes:

- Local Anonymous: default device-only identity. The app is fully usable.
- Supabase Anonymous: retained for compatibility/testing, but production cloud
  sync does not write portfolio data under anonymous sessions.
- Email / Password: real Supabase sign-up, sign-in, persisted session, and
  sign-out are available from Settings when Supabase is configured.
- Google Sign-In: placeholder; no OAuth client secrets are bundled.
- Apple Sign-In: placeholder; no OAuth secrets are bundled.

`AuthException` is the safe error type for auth-provider failures. Auth failures
must never block local scan, analyze, save, portfolio, search, sort, detail, or
delete flows.

Cloud sync is also local-first:

```text
Save collectible locally
-> Queue image/cloud work
-> If signed in with Supabase email/password, upload under that auth user id
-> If signed out/local, keep work local or retryable
-> Report sync state in Settings
-> Never block local portfolio persistence
```

If cloud sync fails, the local portfolio remains the source of truth and Settings
shows a recoverable sync status.

Production cloud sync is intentionally tied to the current authenticated
Supabase user. When an email/password user is signed in, database rows use that
session's `auth.uid()` as `user_id`, and image uploads are stored under:

```text
collectible-images/{userId}/{collectibleCloudId}/image.ext
```

When the user signs out, local portfolio data is not deleted. Manual Sync and
background image uploads stop using Supabase until another signed-in session is
available. A fresh empty device may download cloud items after sign-in; an
existing local portfolio does not resurrect unknown cloud rows during manual sync
so locally deleted items do not unexpectedly reappear.

Background image sync uses a persisted queue with these production states:

- Pending: local image is waiting for upload.
- Syncing: upload is currently running.
- Synced: cloud image metadata was saved back to the local portfolio item.
- Retryable: a temporary failure is waiting for backoff before another attempt.
- Failed: retry attempts are exhausted or user attention is needed.

Retries use exponential backoff. Local scan, analyze, save, portfolio, search,
sort, detail, and delete flows must continue even when queue processing,
Supabase Storage, or cloud record upload fails.

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
supabase/migrations/202606290002_collectible_images_storage_policies.sql
supabase/migrations/202606300001_production_cloud_sync_hardening.sql
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

Without these values, the app continues in Local Anonymous mode and stores the
portfolio locally.

To test production auth and sync:

1. Enable Email provider in Supabase Auth settings.
2. Apply the SQL schema and storage policies from `supabase/migrations/`.
3. Run Flutter with the dart defines above.
4. Open Settings.
5. Create an account with Email / Password or sign in to an existing account.
6. Scan and save a collectible; local save completes first.
7. Tap Sync Now in Settings to upload local portfolio rows and process queued
   image uploads.
8. Confirm rows use the signed-in user's id and images are written to the
   user-scoped folder in the `collectible-images` bucket.

### Auth test plan

Use `docs/supabase_auth_test_plan.md` to validate:

- local anonymous mode
- configured-but-signed-out local mode
- email/password sign-in
- email/password sign-up
- sign out

Authentication is optional. The app must not require login to scan, save, view,
search, sort, or delete local portfolio items.

### Secret handling

Never commit Supabase service-role keys, OAuth client secrets, OpenAI keys,
Gemini keys, marketplace pricing keys, or upload keystore passwords to Flutter
source. Mobile builds may receive only public Supabase anon configuration via
`--dart-define`; privileged credentials must stay server-side.

## Subscription, Usage, and Google Play Billing

CollectIQ AI is still free/local-first by default. Google Play Billing is
available as an Android MVP, but it is disabled unless explicitly configured for
a build. There are no hardcoded billing secrets, and mock/local testing does not
require a subscription.

Current plan behavior:

- Free: active default plan and development-safe scanner access.
- Pro: Google Play product-backed entitlement when billing is enabled.
- Premium: Google Play product-backed entitlement when billing is enabled.
- Payment status: `Not configured` unless a billing-enabled build can reach
  Google Play Billing.

Usage tracking is local and development-safe by default. Successful scan analyses
increment the local daily usage counter; failed analyses do not. The scanner
checks usage before analysis and shows a friendly inline error if a configured
limit is reached.

Development config:

```text
COLLECTIQ_USAGE_UNLIMITED=true
COLLECTIQ_DAILY_FREE_SCAN_LIMIT=25
```

`COLLECTIQ_USAGE_UNLIMITED` defaults to `true` so normal local testing is not
blocked.

### Google Play Billing MVP

Billing is controlled by `--dart-define` values:

```text
COLLECTIQ_BILLING_ENABLED=false
COLLECTIQ_PRO_PRODUCT_ID=collectiq_pro_monthly_test
COLLECTIQ_PREMIUM_PRODUCT_ID=collectiq_premium_monthly_test
```

To test Google Play Billing with internal testing:

1. Create subscription or managed product entries in Google Play Console.
2. Use product ids that match the dart defines above, or pass your own ids:

   ```powershell
   flutter run `
     --dart-define=COLLECTIQ_BILLING_ENABLED=true `
     --dart-define=COLLECTIQ_PRO_PRODUCT_ID=your_pro_product_id `
     --dart-define=COLLECTIQ_PREMIUM_PRODUCT_ID=your_premium_product_id
   ```

3. Upload a signed AAB to an internal testing track.
4. Add tester accounts in Play Console.
5. Install the app from the Play testing link, not from a sideloaded APK, when
   validating real purchase flows.
6. Use Google Play test cards/test purchase methods from a licensed tester
   account.
7. Open Settings -> Plan & Usage, load the available plans, purchase, cancel,
   and restore.

If billing is disabled, unavailable on the device, or products are not
configured, Settings shows `Payments not configured` and the app continues on
the Free/dev-safe entitlement.

Release checklist before enabling paid products:

- Product ids in Play Console match `COLLECTIQ_PRO_PRODUCT_ID` and
  `COLLECTIQ_PREMIUM_PRODUCT_ID`.
- Internal test purchases, pending purchases, cancelled purchases, failed
  purchases, and restore purchases are verified.
- Server-side receipt validation and durable account entitlements are planned
  before relying on purchases across devices.
- Free/local mode is still tested without billing defines.
- No payment, Supabase, OpenAI, Gemini, eBay, or service-role secrets are stored
  in Flutter source or committed files.

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
- Main manifest permissions are limited to `INTERNET`, `CAMERA`, and
  `POST_NOTIFICATIONS` for optional Android 13+ local price alerts.
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

## Local Price Alert Notifications

Price alerts are evaluated locally from the saved portfolio and local market
data. When an alert triggers, CollectIQ AI can show an Android local
notification through the native `collectiq_ai/notifications` MethodChannel.
No backend push notification service is required, and no pricing API is called
from Flutter.

Android setup:

- `POST_NOTIFICATIONS` is declared for Android 13+.
- The app creates a `collectiq_price_alerts` notification channel named
  `Price Alerts`.
- Settings shows notification permission status, enable/disable state, and last
  local notification status.
- If permission is denied, alerts still evaluate and save locally; notification
  delivery is skipped with a clear Settings status.

Duplicate protection:

- Each delivered alert stores a local token based on alert id and triggered
  timestamp.
- The same already-triggered alert is not notified repeatedly.
- If an alert is reset and triggers again later with a new timestamp, it can
  notify again.

Future backend push work:

- Add server-side device tokens only after production auth/cloud sync is fully
  enabled.
- Keep push notification credentials server-side.
- Continue using local alerts as the offline/local-first fallback.

## Crash Reporting + Analytics MVP

CollectIQ AI now has a privacy-safe telemetry abstraction for beta testing:

- `AppTelemetryService`: shared app-facing interface.
- `AnalyticsReporter`: records app flow events.
- `CrashReporter`: records non-fatal errors.
- `NoopTelemetryService`: default implementation. It performs no external
  calls and keeps local/offline mode unchanged.
- Firebase and Sentry are represented as config-driven placeholders until their
  SDKs and project secrets are added intentionally.

Telemetry is disabled by default. To test placeholder status labels locally:

```powershell
flutter run `
  --dart-define=COLLECTIQ_TELEMETRY_ENABLED=true `
  --dart-define=COLLECTIQ_TELEMETRY_PROVIDER=sentry `
  --dart-define=COLLECTIQ_SENTRY_DSN=placeholder-local-only
```

Do not commit real DSNs, Firebase config files, analytics write keys, API keys,
or crash reporting secrets.

Privacy-safe event policy:

- Allowed: coarse workflow events such as `app_open`, `scan_started`,
  `image_selected`, `analyze_started`, `analyze_success`, `analyze_failed`,
  `save_to_portfolio`, `price_alert_triggered`,
  `subscription_purchase_started`, `subscription_purchase_success`,
  `sync_started`, `sync_failed`, and `sync_success`.
- Allowed properties: source labels, category labels, counts, status labels,
  and latency values.
- Never track: image paths, image bytes, filenames, emails, API keys, access
  tokens, backend URLs, payment identifiers, prompts, notes, titles, or other
  personal collectible content.
- Sanitization removes sensitive keys and redacts values that look like paths,
  URLs, emails, or long secrets.

Settings -> Developer Diagnostics shows:

- Telemetry provider/status.
- Crash reporting enabled/disabled.
- Analytics enabled/disabled.

Future Firebase/Sentry setup:

- Add the SDK only when a production project is ready.
- Keep secrets in platform config or CI/CD secrets, not source code.
- Preserve `NoopTelemetryService` as the offline/local fallback.
