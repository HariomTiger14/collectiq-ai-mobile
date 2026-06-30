# CollectIQ AI Closed Beta Readiness

This document is the internal checklist for preparing CollectIQ AI for a
closed beta. The goal is to validate the Android app with real testers while
keeping mock/default mode safe, local-first, and free of hardcoded secrets.

## Release Candidate Scope

- App launch, onboarding, Home dashboard, Scan, Portfolio, Detail, Settings.
- Camera and Gallery scan paths.
- Mock/default analysis and pricing.
- Optional backend AI/pricing configuration for internal validation only.
- Local-first portfolio persistence.
- Optional Supabase auth/cloud sync test setup.
- Google Play Billing foundation with test products only.
- Local price alerts and local notifications.
- Telemetry/crash abstraction with no-op default unless configured.

## Play Store Internal Testing Checklist

| Area | Required before beta | Status |
| --- | --- | --- |
| Signed AAB | Build `flutter build appbundle --release` and upload to internal testing. | Manual |
| App name | Verify Play Console name is `CollectIQ AI`. | Manual |
| Launcher icon | Verify placeholder icon is acceptable for internal testers. | Manual |
| Screenshots | Capture Home, Scan, Result, Portfolio, Detail, Settings. | Manual |
| Privacy policy | Review `docs/PRIVACY_POLICY_DRAFT.md` and publish a beta privacy policy URL before inviting testers. | Manual |
| Data Safety form | Use `docs/DATA_SAFETY_DRAFT.md` to map local storage, optional account data, images, diagnostics, sync, and billing. | Manual |
| Permissions disclosure | Review `docs/PERMISSIONS_DISCLOSURE.md` against the Android manifest and runtime prompts. | Manual |
| Tester list | Add internal tester emails or Google Group. | Manual |
| Test accounts | Prepare optional Supabase email/password test accounts. | Manual |
| Billing products | Configure test Pro/Premium product IDs in Play Console. | Manual |
| License testers | Add billing testers in Play Console. | Manual |
| Supabase test project | Use a non-production project with RLS and storage policies applied. | Manual |
| Backend env setup | Use server-side `.env`; never put provider keys in Flutter. | Manual |
| Backend URL | Use HTTPS for release builds if backend mode is enabled. | Manual |
| Crash/analytics | Keep no-op by default, or enable configured provider only. | Manual |

## Environment Safety

Do not commit secrets. Flutter builds may use public configuration values via
`--dart-define`, but API keys for OpenAI, eBay, TCGPlayer, PriceCharting, or
server-side providers must stay in backend environment files.

Recommended beta modes:

```text
Default app mode:
AI_ANALYSIS_PROVIDER=mock
PRICING_PROVIDER=mock
SUPABASE_ENABLED=false
Telemetry provider disabled/noop

Backend validation mode:
AI_ANALYSIS_PROVIDER=openai_vision
AI_BACKEND_ANALYSIS_ENDPOINT_URL=https://<beta-backend>/api/analyze
```

## Privacy and Data Safety Drafts

The beta compliance draft set is:

- `docs/PRIVACY_POLICY_DRAFT.md`
- `docs/DATA_SAFETY_DRAFT.md`
- `docs/PERMISSIONS_DISCLOSURE.md`

These are planning drafts only. Final Play Store copy and public policy text
must be reviewed before launch.

## Final Beta Smoke Test Checklist

Run this checklist on at least one physical Android device before uploading a
new internal testing build.

1. App launch
   - Fresh install opens without crash.
   - Onboarding appears on first launch.
   - `Start Scanning` opens Scan.
   - `Explore Dashboard` opens Home.

2. Scan
   - Camera opens, captures, returns to Scan, and preview appears.
   - Gallery opens, selection returns to Scan, and preview appears.
   - Analyze shows loading state.
   - Result renders name, category, value, confidence, condition, market data.
   - `Scan Again` clears the flow.

3. Save and Portfolio
   - Save to Portfolio succeeds.
   - New item appears first in Portfolio.
   - Image thumbnail renders.
   - Search and category filter still work.
   - Detail page opens from Portfolio.

4. Home
   - Recent Activity contains the saved item.
   - Recent Activity opens Detail.
   - Dashboard metrics update from portfolio data.
   - Alerts, wishlist, goals, and insights sections render.

5. Detail
   - Image, value, pricing, AI review, profile fields, alerts, and wishlist
     status render without overflow.
   - Price alert can be created.
   - Wishlist status can be changed.
   - Back returns to Portfolio smoothly.

6. Settings
   - Account mode shows local/guest when not signed in.
   - Cloud sync status is clear and non-blocking.
   - Billing unavailable/test-product state is clear.
   - Notification permission status is clear.
   - Telemetry diagnostics are visible.
   - `Reset Onboarding` works.

7. Offline/local-first
   - Disable internet.
   - Mock scan still works.
   - Save to Portfolio still works.
   - Cloud/backend failures show friendly statuses and do not block local save.

8. Diagnostics
   - No `FATAL EXCEPTION`, `AndroidRuntime`, uncaught `E/flutter`, or ANR in
     logcat during normal smoke flow.
   - Backend/provider fallbacks are clear when optional services are disabled.

## Commands

```powershell
dart format lib test integration_test
flutter analyze
flutter test
cd backend
py -m unittest discover tests
cd ..
flutter build appbundle --release
```

Optional generated checklist:

```powershell
scripts\run_beta_smoke_checklist.ps1
```

## Beta Exit Criteria

- No app launch crash on supported Android test devices.
- Camera and Gallery return reliably.
- Scan, save, portfolio, detail, and dashboard flows are stable.
- Local-first mode works without sign-in or backend.
- No secrets are present in Flutter source or committed files.
- Internal tester feedback has no unresolved critical crashes.

## Remaining Manual Launch Steps

- Upload signed release AAB to Play Console internal testing.
- Complete Store Listing draft, screenshots, privacy policy, and Data Safety.
- Configure closed beta tester list.
- Confirm Play Billing test products and license testers.
- Apply Supabase schema/RLS/storage policies to a beta project if sync is tested.
- Deploy backend with server-side env vars if real AI/pricing validation is tested.
