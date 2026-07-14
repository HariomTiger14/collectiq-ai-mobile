# Current Authentication and Settings Architecture

## Scope
This audit records the current Flutter architecture that future remediation must separate. It is documentation only.

## Application Entry
`lib/main.dart` starts `authDeepLinkCoordinatorProvider` in `CollectIqApp.initState` and renders `MaterialApp(home: const AppShell())`. `lib/core/navigation/app_shell.dart` gates first-run access through `onboardingControllerProvider`, not authentication. The shell destinations are Home, Portfolio, Scan, and Settings.

## Settings Ownership Today
`lib/features/settings/presentation/settings_screen.dart` currently owns account/auth UI state that should not remain in Settings after remediation:

- `_emailController`
- `_passwordController`
- `_resendCountdownTimer`
- auth-controller listener side effects
- creation of `AuthAccessPanel`
- account/profile rows, sync sections, diagnostics, notifications, and support/legal settings

The screen renders account content and then inserts `AuthAccessPanel`, so signed-out users see credential fields inside Settings.

## Authentication Presentation Today
`lib/features/auth/presentation/widgets/auth_access_panel.dart` is explicitly described as the account access panel used by Settings. It contains email/password fields, password visibility, password strength, sign-in, sign-up, resend confirmation, forgot-password, and signed-in account panel states. Its widget keys are legacy test anchors such as `settings-auth-email-field`, `settings-auth-sign-in-button`, and `settings-auth-sign-up-button`.

## Authentication Controller and Repository
`lib/features/auth/presentation/controllers/auth_controller.dart` owns `AuthFlowStatus`, `AuthState`, sign-in, sign-up, confirmation, resend, password reset, callback application, anonymous sign-in, and sign-out orchestration.

`lib/features/auth/data/repositories/supabase_auth_repository.dart` uses Supabase when configured and falls back to local/mock behavior when it is not configured. Email/password operations require Supabase configuration. Local/guest mode is an intentional runtime behavior and must remain available.

## Deep Link and Web Recovery
`lib/features/auth/services/auth_deep_link_service.dart` handles auth callback links and applies confirmation sessions or confirmation errors. `lib/features/auth/domain/entities/auth_callback_result.dart` defines `collectiq-sit://auth/callback` and `collectiq://auth/callback`; it ignores password recovery callbacks. `web/auth/reset-password/index.html`, `web/auth/reset-password/reset-password.js`, and `web/auth/callback/index.html` are current runtime recovery/callback references.

## Tests That Encode Legacy Coupling
`test/widget_test.dart` currently includes Settings-embedded auth assertions using `settings-auth-*` keys. Those tests are useful as regression inventory, but future remediation should replace them with separate auth-screen tests and Settings account-entry tests.

## Constraints To Preserve
No auth guard exists today. Onboarding remains the application-entry condition. Signed-out/local users can use Home, Scanner, Portfolio, and Detail. Sign-out does not delete local data. Password recovery uses the existing web reset path unless separately approved.
