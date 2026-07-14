# Auth Phase 6A Freeze Record

Date: 2026-07-14
Branch: `rebuild/product-language-v1`
Starting HEAD: `62b8412920a6baebc3bf003a33c76dc633ac6a0d`
Status: Phase 6A Authentication Presentation freeze declared for implemented supported states.

## Implemented Screens And States

- Sign In
- Sign Up / Create Account
- Forgot Password
- Email verification presentation when `AuthFlowStatus.confirmationRequired` is real
- Guest continuation/return
- Web reset handoff presentation
- Settings signed-out account entry that navigates to Authentication
- Settings signed-in summary and sign-out from real auth state

## Preserved Contracts

- Supabase ownership remains in repository/controller layers.
- Auth widgets do not call Supabase directly.
- No auth guard added.
- Onboarding remains application entry.
- Guest/local access remains available.
- Password reset completion remains web-hosted.
- Deep-link coordinator ownership unchanged.
- Router architecture unchanged; local `Navigator.push` only.
- Product Language definitions unchanged.
- Phase 6B Settings was not started.

## Controller Lifecycle Decision

`AuthController` keeps `_repository` mutable (`late AuthRepository`) instead of `late final AuthRepository`.

Reason: Riverpod can rerun a Notifier `build` on the same notifier instance after invalidation or dependency updates. A `late final` repository assignment can therefore throw `LateInitializationError` on rebuild. The focused test `AuthController can rebuild without replacing session state` invalidates `authControllerProvider`, reloads the current user, and proves the session state survives with the provider-owned repository contract intact.

Risk assessment: low. The repository is still injected only through `authRepositoryProvider`; no widget owns Supabase directly, no subscriptions were moved, and no auth guard or deep-link ownership changed.

## Validation

- `C:\Users\hario\Desktop\flutter\bin\flutter.bat analyze`: pass, no issues found.
- `C:\Users\hario\Desktop\flutter\bin\flutter.bat test test\auth_presentation_test.dart --reporter=compact`: pass, 18 tests.
- `C:\Users\hario\Desktop\flutter\bin\flutter.bat test test\widget_test.dart --reporter=compact --plain-name "shows settings screen content"`: pass.
- `rg "skip:" test -n`: no matches.
- `C:\Users\hario\Desktop\flutter\bin\flutter.bat test --reporter=compact`: 580 passed, 0 skipped, 9 failed.
- `C:\Users\hario\Desktop\flutter\bin\flutter.bat build apk --debug --flavor local --dart-define=APP_ENV=local`: pass.
- `C:\Users\hario\Desktop\flutter\bin\flutter.bat install -d RZ8R213M8ZL --debug --flavor local`: pass.
- Samsung SM-E625F runtime launch, screenshots, hierarchy XML, window dump, logcat, and comparison PNG captured.

## Full-Suite Failures Remaining

All remaining failures match accepted baseline debt:

- `test/analyzer_service_test.dart`: `MockAnalyzerProvider consumes the backend analyzer contract when configured`
- `test/domain_unit_test.dart`: `DioAiBackendApiService FastAPI detail error preserves analyzer error code`
- `test/domain_unit_test.dart`: `Supabase foundation SIT scripts pass required dart defines without hardcoded secrets`
- `test/widget_test.dart`: `camera denied UI shows friendly message`
- `test/widget_test.dart`: `gallery import confirms enhancement before adding photo`
- `test/widget_test.dart`: `gallery import follows review workspace analyze result portfolio flow`
- `test/widget_test.dart`: `enhancement preview shows only Original and Enhanced`
- `test/widget_test.dart`: `enhancement preview can switch Enhanced back to Original`
- `test/widget_test.dart`: `saving enhanced scan preserves portfolio gallery metadata`

## Legacy Settings-Embedded Auth Tests

Twelve obsolete Settings-embedded auth tests were deleted, not skipped. Replacement coverage lives in `test/auth_presentation_test.dart`; see `qa/reconstruction/auth_phase6a_legacy_test_migration.md`.

## Evidence

- `qa/reconstruction/auth_phase6a_authority_identity.md`
- `qa/reconstruction/auth_phase6a_measurements.md`
- `qa/reconstruction/auth_phase6a_runtime_comparison.md`
- `qa/reconstruction/auth_phase6a_fidelity_acceptance.md`
- `qa/reconstruction/auth_phase6a_test_regression_analysis.md`
- `qa/reconstruction/auth_phase6a_legacy_test_migration.md`
- `qa/reconstruction/auth_phase6a_full_test_output.txt`
- `qa/screenshots/approved_authority_remediation/auth/comparison/phase6a_auth_authority_vs_runtime.png`

## Rollback Boundary

- `lib/features/auth/presentation/screens/auth_screens.dart`
- `lib/features/auth/presentation/controllers/auth_controller.dart`
- `lib/features/settings/presentation/settings_screen.dart`
- `test/auth_presentation_test.dart`
- `test/widget_test.dart`
- Phase 6A QA evidence records

Freeze declaration: declared for Phase 6A implemented supported Authentication Presentation states.
