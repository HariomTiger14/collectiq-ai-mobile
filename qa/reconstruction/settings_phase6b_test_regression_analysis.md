# Settings Phase 6B Test Regression Analysis

Date: 2026-07-14
Branch: `rebuild/product-language-v1`
Starting HEAD: `3b2d4ab26be414586512498c5588fd2b5531e947`

## Summary

Accepted Phase 6A full-suite baseline:

- `580 passed, 9 failed`

Initial Phase 6B full-suite result:

- `583 passed, 12 failed`

Final Phase 6B full-suite result after narrow remediation:

- `586 passed, 9 failed`

No new Settings/Auth-related failure remains. The full suite is still not entirely passing; the remaining 9 failures match the accepted Phase 6A baseline debt.

## Three New Phase 6B Failures

| File | Test | Initial failure | Baseline? | Settings relevance | Individual status | Containing file status | Root cause | Remediation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `test/price_alert_notifications_test.dart` | `Settings status renders notification state` | Expected text `Permissions`; actual Phase 6B label is `Notification permission`. | No | Yes | Failed before fix; passes after fix | `price_alert_notifications_test.dart` passes, 4 tests | Stale Settings visual expectation | Updated assertion to `Notification permission`, preserving notification state and denied permission coverage. |
| `test/widget_test.dart` | `about route renders PackLox info without placeholder links` | `tap(find.text('About PackLox'))` became ambiguous because Phase 6B has both section heading and row title. | No | Yes | Failed before fix; passes after fix | `widget_test.dart` remains at 122 passed, 6 known baseline failures | Stale Settings visual expectation | Tapped the row subtitle `Version 1.0.0 (1)` as the stable actionable row target. |
| `test/widget_test.dart` | `settings hides configured AI provider internals` | Could not reveal removed `Scanning` section; Phase 6B moved scan preference copy under `Preferences`. | No | Yes | Failed before fix; passes after fix | `widget_test.dart` remains at 122 passed, 6 known baseline failures | Stale Settings visual expectation | Revealed `Default scan mode`, asserted `Default scan mode` and `Auto Enhance`, and retained absence checks for provider internals. |

These were test migrations required by the approved Settings authority. None indicated a genuine Settings behaviour regression, Authentication separation regression, App Shell integration regression, provider contamination, or state-order issue.

## Full 12-Failure Inventory From Initial Phase 6B Run

| File | Test | Failure message | In Phase 6A accepted 9? | One of three new? | Classification |
| --- | --- | --- | --- | --- | --- |
| `test/analyzer_service_test.dart` | `MockAnalyzerProvider consumes the backend analyzer contract when configured` | Expected `'gemini'`, actual `<null>`. | Yes | No | Unrelated baseline failure: backend analyzer contract debt. |
| `test/domain_unit_test.dart` | `DioAiBackendApiService FastAPI detail error preserves analyzer error code` | Expected message `Real AI analysis requires uploaded image bytes.`, actual `Backend AI analysis failed. Please try again.` | Yes | No | Unrelated baseline failure: backend error-message mapping debt. |
| `test/domain_unit_test.dart` | `Supabase foundation SIT scripts pass required dart defines without hardcoded secrets` | Expected script to contain `--dart-define=AI_ANALYSIS_PROVIDER=%AI_ANALYSIS_PROVIDER%`; script contains `--dart-define=AI_ANALYSIS_PROVIDER=mock`. | Yes | No | Unrelated baseline failure: SIT script config debt. |
| `test/price_alert_notifications_test.dart` | `Settings status renders notification state` | Expected exactly one `Permissions`; found 0. | No | Yes | Stale Settings visual expectation. |
| `test/widget_test.dart` | `about route renders PackLox info without placeholder links` | Tap target `About PackLox` ambiguously found 2 widgets. | No | Yes | Stale Settings visual expectation. |
| `test/widget_test.dart` | `settings hides configured AI provider internals` | Could not reveal `Scanning`. | No | Yes | Stale Settings visual expectation. |
| `test/widget_test.dart` | `camera denied UI shows friendly message` | Expected `Try again`; found 0. | Yes | No | Existing stale scanner expectation. |
| `test/widget_test.dart` | `gallery import confirms enhancement before adding photo` | Existing gallery/enhancement expectation failure; see Phase 6A full-test output. | Yes | No | Existing stale enhancement-preview expectation. |
| `test/widget_test.dart` | `gallery import follows review workspace analyze result portfolio flow` | Existing review-workspace expectation failure; see Phase 6A full-test output. | Yes | No | Existing stale review-workspace expectation. |
| `test/widget_test.dart` | `enhancement preview shows only Original and Enhanced` | Timed out waiting for `Enhanced`. | Yes | No | Existing stale enhancement-preview expectation. |
| `test/widget_test.dart` | `enhancement preview can switch Enhanced back to Original` | Timed out waiting for `Enhanced`. | Yes | No | Existing stale enhancement-preview expectation. |
| `test/widget_test.dart` | `saving enhanced scan preserves portfolio gallery metadata` | Existing enhancement metadata expectation failure; see Phase 6A full-test output. | Yes | No | Existing stale enhancement metadata expectation. |

## Settings Test Migration Review

| Area | Old assertion | New assertion | Reason | Behaviour still protected |
| --- | --- | --- | --- | --- |
| Notifications | `Permissions` | `Notification permission` | Phase 6B copy narrows notification ownership to real price-alert permission only. | Yes: price alerts, denied permission state, and switch are still asserted. |
| About route tap | Tap `About PackLox` | Tap row subtitle `Version 1.0.0 (1)` | Phase 6B has an `About PackLox` section heading and row title. | Yes: existing About route content and absence of placeholder links are still asserted. |
| AI provider internals | Reveal `Scanning`; expect `Estimate guidance`; assert no provider internals | Reveal `Default scan mode`; expect `Default scan mode` and `Auto Enhance`; assert no provider internals | Phase 6B folded scan preferences into `Preferences` without exposing provider config. | Yes: provider internals remain hidden, and approved preferences remain visible. |

No test was skipped. No arbitrary delay was added. No Home, Scanner, Portfolio, Detail, backend, Supabase, router, onboarding, or Product Language contract was changed.

## Focused Results

- Exact three new failures after remediation: pass individually.
- `test/price_alert_notifications_test.dart`: pass, 4 tests.
- `test/widget_test.dart`: 122 passed, 6 failed; the 6 failures match existing Phase 6A widget baseline debt.
- `flutter analyze`: pass.
- `test/settings_phase6b_test.dart`: pass, 6 tests.
- `test/auth_presentation_test.dart`: pass, 18 tests.

## Final Full-Suite Result

- `C:\Users\hario\Desktop\flutter\bin\flutter.bat test --reporter=compact`
- Result: `586 passed, 9 failed`.

The failure count returned to the accepted Phase 6A ceiling. The full suite must not be described as entirely passing.
