# Local Android SIT Results

Run date: 2026-07-01

Sprint: Stabilise Local MVP + Android Device SIT

## Device Used

No Android device was detected by Flutter in this Codex session.

`flutter devices` returned only:

- Windows desktop
- Chrome web
- Edge web

Android real-device SIT is therefore blocked until a physical Android device or emulator is visible to Flutter/ADB.

## Android Version

Not verified. No Android device was available.

## Test Steps And Results

| Area | Step | Result | Notes |
| --- | --- | --- | --- |
| Local-only launch | Run `flutter run` in default local mode | Blocked | No Android target device was available. |
| Navigation | Open onboarding, Home, Scan, Portfolio, Settings | Blocked | Requires Android target. Covered partially by widget tests. |
| Camera flow | Open camera, capture image, return to app | Blocked | Requires Android camera/gallery picker validation. |
| Camera analysis | Analyze captured image | Blocked | Real image analysis requires local FastAPI backend. Message is now explicit when backend is unavailable. |
| Camera save | Save result to portfolio and display image | Blocked | Persistence path is covered by local tests; device image display still needs SIT. |
| Gallery flow | Pick gallery image and return to app | Blocked | Requires Android gallery picker validation. |
| Gallery analysis | Analyze gallery image | Blocked | Real image analysis requires local FastAPI backend. |
| Gallery save | Save result to portfolio and display image | Blocked | Persistence path is covered by local tests; device image display still needs SIT. |
| Edit collectible | Open detail, edit title/category/manufacturer/series/year/country/value range/notes, save locally | Blocked | Local edit flow is implemented and covered by widget/repository tests. Android detail-page interaction still needs device SIT. |
| Settings interactions | Tap visible Settings rows and controls | Blocked | Rows now respond with local status, coming-soon, or cloud setup messages. Android tap pass still needs device SIT. |
| Restart persistence | Force stop, reopen, verify items/images | Blocked | Requires Android target. Repository reload tests cover saved paths but not OS lifecycle. |

## Bugs Found

1. Default local mode could queue image sync work after a local portfolio save even when Supabase was not configured. That could produce cloud sync failure/attention states during local-only testing.
2. Backend-unavailable scanner errors used the generic text `Unable to connect to AI service.`, which did not clearly explain that real camera/gallery image analysis needs the local FastAPI backend.

## Bugs Fixed

1. Local-only image saves no longer enqueue cloud image upload tasks when Supabase is not configured.
2. Backend-unavailable scanner error now says: `Local backend is not running. Start the CollectIQ FastAPI backend and try again.`
3. Added regression coverage for:
   - camera/gallery saved image paths surviving repository reload;
   - local-only mode not queuing cloud image sync failures;
   - backend-unavailable message remaining user-friendly.
4. Added local edit collectible flow from the detail page. Edits update title, category, manufacturer/brand, series, year, country, estimated value range, and notes while preserving image paths.
5. Visible Settings rows now either perform a local action, show a coming-soon message, or show a cloud setup/configuration-required message in local mode.

## Current Mock AI Limitation

- The built-in `sample://sports-card` scan remains fully local.
- Normal camera/gallery image analysis in the current mock-provider path still requires the local CollectIQ FastAPI backend. If the backend is not running, analysis shows: `Local backend is not running. Start the CollectIQ FastAPI backend and try again.`
- No real AI provider, cloud sync, Firebase, Supabase, billing, or production service was enabled by this local MVP sprint.

## Remaining Risks

- Physical Android camera picker flow has not been verified in this session.
- Physical Android gallery picker flow has not been verified in this session.
- Android permission dialogs and denial paths still require real-device testing.
- Force-stop/reopen image display persistence still requires real-device testing.
- Real-image analysis still depends on a running local FastAPI backend in default mock provider flow.
- Edit collectible behavior is locally tested but still needs Android detail-page SIT.
- Settings row messages are locally tested but still need Android tap-through SIT.
- No Firebase, Supabase, production, or paid-provider behavior was enabled or tested in this sprint.

## Verification Commands

```powershell
dart format lib test
flutter analyze
flutter test
```

Results:

- `dart format lib test`: passed; formatted 186 files, 4 changed from this sprint.
- `flutter analyze`: passed; no issues found.
- `flutter test`: passed; 254 tests.
