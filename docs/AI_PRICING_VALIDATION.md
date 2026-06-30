# CollectIQ AI AI + Pricing Validation

This document is the manual validation worksheet for the real end-to-end flow:

```text
Flutter image -> Backend /api/analyze -> OpenAI recognition -> eBay pricing -> Flutter result
```

Automated tests must keep provider calls mocked. Real OpenAI and eBay calls are
manual/local only because they can incur cost and require backend-only secrets.

## Run Backend In Mock Mode

Use this mode for baseline checks and safe local development.

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
$env:AI_PROVIDER="mock"
$env:PRICING_PROVIDER="mock"
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Run the validation script with a local jpg/jpeg/png:

```powershell
py scripts\validate_real_analysis.py C:\path\to\collectible.jpg --category "Pokemon Card"
```

Expected: mock AI and mock pricing return a shaped response, fallback is `no`,
and the response includes diagnostics.

## Run Backend In OpenAI + eBay Mode

Real provider calls are opt-in and backend-only. Do not pass secrets to Flutter.

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
$env:AI_PROVIDER="openai"
$env:OPENAI_API_KEY="sk-your-server-side-key"
$env:OPENAI_MODEL="gpt-4.1-mini"
$env:PRICING_PROVIDER="ebay"
$env:EBAY_ACCESS_TOKEN="your-server-side-ebay-access-token"
$env:EBAY_MARKETPLACE_ID="EBAY_AU"
$env:PRICING_CACHE_TTL_SECONDS="900"
$env:PRICING_PROVIDER_MIN_INTERVAL_MS="250"
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Then run:

```powershell
py scripts\validate_real_analysis.py C:\path\to\collectible.jpg --category "Pokemon Card"
```

Expected: OpenAI identifies the collectible, eBay pricing returns comparable
sales when available, and fallback is `no`. If eBay is unavailable, fallback may
be `yes` with a clear fallback reason.

## Run Flutter Against Local Backend

Android emulator:

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

Flutter must only receive the backend URL. OpenAI and eBay credentials stay in
`backend/.env` or local backend environment variables.

## Results Template

| Date | Image | Provider Mode | Expected Category | Actual Category | Item Name | Confidence | Pricing Source | Fallback Used | Value Range | Pass/Fail | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2026-06-30 | pokemon_card_placeholder.jpg | OpenAI + eBay | Pokemon Card |  |  |  |  |  |  |  |  |

## Pass/Fail Criteria

Pass when:

- backend returns HTTP 200;
- item name is plausible and not invented beyond visible evidence;
- category matches the expected category;
- confidence level matches image quality;
- low-confidence responses include clear reasons;
- image quality warnings are actionable when present;
- pricing source is eBay or mock fallback with a clear reason;
- value range is non-zero and reasonable for the identified collectible;
- Flutter result screen renders without crash or contract parsing errors.

Fail when:

- backend exposes secrets in logs or response;
- backend crashes instead of returning a safe error;
- OpenAI invents important fields without visual evidence;
- pricing fallback occurs without a visible fallback reason;
- Flutter cannot parse the backend response;
- result is high-confidence while image quality is clearly poor.

## Known Manual Checks

- Test at least one Pokemon/TCG card, sports card, coin, comic, and memorabilia
  item before v1 launch.
- Record whether pricing used live eBay or fallback.
- Repeat one image twice to verify cache hit behavior.
- Test one intentionally blurry/cropped image to verify image quality guidance.
