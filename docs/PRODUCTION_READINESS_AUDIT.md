# CollectIQ AI Production Readiness Audit

Audit date: 2026-06-30

## Summary

CollectIQ AI is in strong internal-testing shape. Mock/local mode remains the
safe default, local-first portfolio behavior is preserved, backend AI and eBay
pricing are backend-only, and Android debug/release artifacts build
successfully.

Production readiness rating: **8 / 10 - internal beta ready, store-production
blocked by manual real-device validation, real provider validation, and release
signing finalization.**

## Automated Results

| Check | Result | Notes |
| --- | --- | --- |
| `dart format lib test` | Pass | 120 files checked; scanner timing file formatted. |
| `flutter analyze` | Pass | No analyzer issues found. |
| `flutter test` | Pass | 161 Flutter tests passing. |
| `cd backend; py -m unittest discover tests` | Pass | 51 backend tests passing. |
| `flutter pub outdated` | Pass with notes | `dio` 5.9.2 -> 5.10.0 and `dio_web_adapter` 2.1.2 -> 2.2.0 are upgradable; no upgrade applied during audit. |
| `flutter build apk --debug` | Pass | Built `build/app/outputs/flutter-apk/app-debug.apk`. |
| `flutter build apk --release` | Pass | Built `build/app/outputs/flutter-apk/app-release.apk` at 51.8 MB. |
| `flutter build appbundle --release` | Pass | Built `build/app/outputs/bundle/release/app-release.aab` at 51.8 MB. |

## Workflow Audit

| Workflow | Automated Status | Manual Status | Notes |
| --- | --- | --- | --- |
| App launch | Pass | Pending real device | Widget tests cover shell tabs and Home render. |
| Camera scan | Pass foundations | Pending real device | Controller tests cover picker stability/cancellation paths; physical Android still needs a final smoke test. |
| Gallery scan | Pass foundations | Pending real device | Gallery cancellation and ordering tests are covered. |
| Analyze mock | Pass | Pending real device | Mock provider remains default. |
| Analyze via backend if configured | Pass contract/client tests | Pending local backend run | HTTP client is disabled by default and endpoint validation is covered. |
| Save to Portfolio | Pass | Pending real device | Local save remains first and non-blocking. |
| Portfolio ordering | Pass | Pending real device | Newest-first timestamp tests cover camera/gallery/mixed/restart cases. |
| Search/filter | Pass | Pending real device | Widget tests cover search/filter behavior. |
| Detail page | Pass | Pending real device | Portfolio, Home, and Scan recent item navigation tests cover detail routing. |
| Home dashboard | Pass | Pending real device | Dashboard analytics and collector intelligence tests pass. |
| Collector intelligence | Pass | Pending real device | Score, insights, recommendations, goals, and achievements are tested. |
| Settings | Pass | Pending real device | Settings coverage includes diagnostics, sync, auth, and subscription placeholders. |
| Usage limits | Pass | Pending real device | Usage increment, failure, and friendly block behavior covered. |
| Local persistence after restart | Pass | Pending real device | SharedPreferences persistence ordering tests pass. |
| Delete item | Pass | Pending real device | Portfolio/detail delete tests cover confirmation path. |

## Offline / Online Behavior

| Scenario | Result | Notes |
| --- | --- | --- |
| App works offline in mock/local mode | Pass by architecture/tests | Mock AI and local repository do not require network. |
| Local save succeeds without internet | Pass | Local-first save tests and cloud-failure tests pass. |
| Backend AI fails gracefully when offline | Pass by client tests | Network, timeout, invalid endpoint, and backend error mapping are covered. |
| eBay pricing fallback works | Pass backend tests | Provider failure, rate limit, timeout, cache, and mock fallback are tested. |
| Cloud sync failure does not block local save | Pass | Local save is independent from sync worker failures. |
| Retryable sync state appears correctly | Pass foundations | Queue states and retry behavior are tested; manual Settings review still required. |

## Cloud Sync / Retry Audit

Current queue/state coverage:

- Pending
- Syncing
- Synced
- Failed
- Retryable
- Last sync timestamp
- Pending/failed counts in Settings
- Local-first save before cloud upload
- Failed sync retry path

Manual checklist:

1. Launch app with Supabase disabled and save a scan.
2. Confirm Settings shows local/guest mode and no blocking cloud error.
3. Enable Supabase configuration with valid anonymous auth.
4. Save an item and confirm local Portfolio updates immediately.
5. Trigger manual sync.
6. Confirm pending count moves to syncing, then synced.
7. Disable network and trigger sync.
8. Confirm failed/retryable state appears and local Portfolio remains usable.
9. Restore network and trigger manual sync again.
10. Confirm retry clears failed state.

## Real AI Validation Checklist

Automated tests must continue to mock OpenAI. Manual real AI validation should
use `docs/AI_PRICING_VALIDATION.md` and `backend/scripts/validate_real_analysis.py`.

For each image, record:

- image filename
- category expected
- item expected or keyword hints
- actual item name
- actual category
- confidence
- confidence class
- image quality warnings
- false positive notes
- false negative notes
- missing visible fields
- prompt tuning recommendation

Recommended manual dataset:

- Pokémon / TCG card
- sports card
- coin
- comic
- memorabilia
- intentionally blurry image
- cropped image
- dark image
- multiple collectibles in one photo

Pass criteria:

- API response follows the Flutter contract.
- Item/category are plausible from visible evidence.
- Low-quality images receive lower confidence and actionable guidance.
- Unknown fields are null/unknown rather than invented.
- No backend secrets appear in logs or responses.

## Real Pricing Validation Checklist

Automated tests must continue to mock eBay and other pricing providers. Manual
real pricing validation should record:

- expected rough market price
- estimated value returned
- low/high value range
- pricing provider
- source count
- cache hit/miss
- fallback used
- fallback reason
- provider latency
- outlier removals
- normalization quality

Pass criteria:

- Comparable sales are relevant to the identified collectible.
- Outlier values do not dominate the estimate.
- Empty/rate-limited provider responses fall back safely.
- Cache hit is faster than cache miss for the same item.
- Flutter parses the response without UI changes.

## Performance Measurement

Measured or logged in debug-safe paths:

- Camera image persistent-copy time.
- Gallery image persistent-copy time.
- AI provider analysis latency.
- Pricing enrichment latency.
- Total scan-to-result latency.
- Backend `/api/analyze` total latency.
- Backend AI provider latency.
- Backend pricing provider latency.
- eBay provider latency, cache state, and fallback reason.

Release safety:

- Flutter `debugPrint` is disabled in release mode in `main.dart`.
- Backend debug diagnostics are intended for local/manual validation and should
  remain off or sanitized in production logging.

## UX Polish Audit

Small rough edges checked:

- Loading states: covered for scan processing and backend errors.
- Empty states: Home, Portfolio, Scan, and Settings have non-crashing empty paths.
- Error messages: picker cancellation, invalid image path, backend errors, and usage-limit errors are user-safe.
- Offline messages: backend/network failures map to friendly scan errors.
- Settings labels: account, sync, diagnostics, plan, usage, and cloud status are present.
- Diagnostics clarity: provider status and endpoint readiness are visible.

No large redesign was performed in this audit.

## Security Audit

Findings:

- No real OpenAI, Supabase, eBay, service-role, or Google API secrets were found.
- Documentation had OpenAI-key-shaped placeholder strings. They were replaced
  with neutral placeholders to avoid false-positive secret scanner alerts.
- Flutter reads only public/config values via `dart-define`.
- OpenAI and eBay credentials remain backend-only.
- Release endpoint readiness enforces HTTPS for release-safe backend AI calls.
- Flutter debug logs are suppressed in release builds.

Remaining security checks before production:

- Run a formal secret scanner in CI.
- Confirm Play release signing uses the production upload key.
- Confirm backend production logs redact request payloads and never include
  provider prompts, image data, API keys, or user tokens.
- Confirm Supabase RLS policies in the production project match repository SQL.

## Dependency / Build Audit

Dependency notes:

- `dio` is upgradable from 5.9.2 to 5.10.0.
- `dio_web_adapter` is upgradable from 2.1.2 to 2.2.0.
- Several transitive test/analyzer packages have newer versions constrained by
  current dependency bounds.
- No dependency upgrades were applied because all tests/builds pass and the
  sprint scope is audit/fix, not dependency migration.

Build notes:

- Debug APK builds.
- Release APK builds.
- Release AAB builds.
- Release APK/AAB are verification artifacts only until Play signing and final
  store metadata are complete.

## Issues Found

1. **Missing Flutter scan-to-result timing visibility**
   - Impact: harder to diagnose slow AI/pricing/backend paths.
   - Fix: added debug-safe stopwatch logging for AI analysis latency, pricing
     enrichment latency, and total scan-to-result latency.

2. **Documentation placeholders looked like real OpenAI keys**
   - Impact: could trigger secret scanners even though they were examples.
   - Fix: replaced `sk-your...` placeholders with neutral
     `<server-side-openai-key>` values.

No functional regressions were found by automated tests or build checks.

## Remaining Blockers

- Run final camera/gallery/save/restart/delete smoke test on a physical Android device.
- Run real backend OpenAI validation with representative collectible images.
- Run real eBay pricing validation with expected-price notes.
- Verify Supabase sync against a production-like project with RLS enabled.
- Configure production Play upload signing.
- Decide whether to upgrade `dio` and `dio_web_adapter` in a separate dependency sprint.
- Add CI automation for Flutter tests, backend tests, secret scanning, and release build dry runs.

## Manual Real-Device Checklist

1. Fresh install release APK.
2. Launch app.
3. Confirm Home dashboard loads.
4. Scan with Camera.
5. Cancel camera and confirm app remains stable.
6. Capture camera image, analyze mock, save to Portfolio.
7. Pick Gallery image, analyze mock, save to Portfolio.
8. Confirm newest saved item appears first in Portfolio, Home Recent Activity, and Scan Recent Scans.
9. Restart app and confirm order persists.
10. Search Portfolio by title/category.
11. Apply category filter.
12. Open Detail page from Portfolio, Home, and Scan Recent Scans.
13. Delete an item and confirm Portfolio refreshes.
14. Disable network and confirm mock analyze/local save still works.
15. Enable backend endpoint and test friendly failure if backend is unreachable.
16. Review Settings for account mode, sync status, usage limits, diagnostics, and provider status.

## Release Readiness Checklist

- [x] Mock mode remains default.
- [x] Flutter tests pass.
- [x] Backend tests pass.
- [x] Flutter analyze passes.
- [x] Debug APK builds.
- [x] Release APK builds.
- [x] Release AAB builds.
- [x] No real secrets found in repository sweep.
- [x] Release debug logs are suppressed.
- [x] Backend/provider credentials remain server-side.
- [ ] Physical Android smoke test completed on release build.
- [ ] Real AI validation completed.
- [ ] Real pricing validation completed.
- [ ] Production Supabase sync validation completed.
- [ ] Production upload signing configured.
