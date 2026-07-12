# Authentication and onboarding audit

`CloudAppStartup` conditionally initializes `SupabaseBootstrap`, while application auth uses `SupabaseService` REST calls and SharedPreferences session persistence. `authControllerProvider` owns presentation state and initiates session restoration; no Supabase realtime auth-state subscription was found. Methods implemented: local/anonymous sign-in, Supabase anonymous sign-in, email/password sign-in/sign-up, resend confirmation, reset-email dispatch, callback completion, and sign-out. Google/Apple repository methods intentionally report unsupported.

Sign-up may return a session or confirmation-required state. Callback parsing handles confirmation tokens/errors with environment-specific schemes. Recovery callbacks are intentionally ignored by Android/mobile and continue to the PackLox HTTPS reset page; the web password-update flow is tested. A mobile password-update route is absent. There is no user-profile lookup or profile gate. Error normalization covers network, timeout, configuration, confirmation, rate limit and expired session. Retry is user-initiated; resend and password reset have cooldown/rate-limit state.

Auth presentation safely rebuildable without behavior changes: `features/auth/presentation/widgets/auth_access_panel.dart` and the account-access composition in `settings_screen.dart`. Future separate screens may call the same `AuthController` methods, but callback routing and password update require a separate contract sprint.

Onboarding is one composite `OnboardingScreen`, not a routed multi-page flow. `onboardingControllerProvider` owns the once-only Boolean persisted as `onboarding_completed_v1`. Completion either selects Scan or Home. It is independent of auth and environment.
