# Full Test Suite Baseline Debt

Date: 2026-07-14
Branch: rebuild/product-language-v1
Phase 5 full suite command: `C:\Users\hario\Desktop\flutter\bin\flutter.bat test --reporter=compact`
Result: 574 passed, 9 failed.
Acceptance: unchanged from accepted Phase 4 baseline and within Phase 5 gate of no more than 9 failures.

## Remaining Failures

| File | Test | Classification |
| --- | --- | --- |
| `test/analyzer_service_test.dart` | `MockAnalyzerProvider consumes the backend analyzer contract when configured` | Existing backend analyzer contract debt; expected `selectedProvider` is null. |
| `test/domain_unit_test.dart` | `DioAiBackendApiService FastAPI detail error preserves analyzer error code` | Existing backend error-message mapping debt. |
| `test/domain_unit_test.dart` | `Supabase foundation SIT scripts pass required dart defines without hardcoded secrets` | Existing SIT script config debt; script still hardcodes mock AI provider. |
| `test/widget_test.dart` | `camera denied UI shows friendly message` | Existing stale scanner expectation; expects `Try again`. |
| `test/widget_test.dart` | `gallery import confirms enhancement before adding photo` | Existing stale enhancement-preview expectation. |
| `test/widget_test.dart` | `gallery import follows review workspace analyze result portfolio flow` | Existing stale review-workspace expectation. |
| `test/widget_test.dart` | `enhancement preview shows only Original and Enhanced` | Existing stale enhancement-preview expectation. |
| `test/widget_test.dart` | `enhancement preview can switch Enhanced back to Original` | Existing stale enhancement-preview expectation. |
| `test/widget_test.dart` | `saving enhanced scan preserves portfolio gallery metadata` | Existing stale enhancement metadata expectation. |

## Focused Phase 5 Runs

Passed:
- `test/shared_visual_foundations_test.dart` (12 tests)
- `test/bootstrap_entry_presentation_test.dart test/onboarding_presentation_test.dart test/app_shell_presentation_test.dart`
- `test/home_page_test.dart test/portfolio_screen_test.dart test/detail_screen_test.dart test/cloud_sync_status_widget_test.dart`
- `test/scan_hub_page_test.dart test/camera_capture_page_test.dart test/scanner_widgets_test.dart test/scanner_volume_03_structure_test.dart`
- `test/cloud_portfolio_sync_foundation_test.dart`

Checklist correction: `test/local_portfolio_persistence_test.dart` does not exist in this repository. Local portfolio persistence is covered in `test/domain_unit_test.dart`, `test/widget_test.dart`, and focused Portfolio/Detail tests.
