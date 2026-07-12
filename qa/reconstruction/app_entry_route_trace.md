# App entry and decision trace

## Exact runtime chain

`lib/main.dart:main()` → binding/log/image-picker setup → `EnvironmentConfig.fromEnvironment()` (`APP_ENV`, legacy `COLLECTIQ_ENV`) → `CloudServiceRegistry.fromConfig()` → unawaited `CloudAppStartup.run()` / conditional `SupabaseBootstrap.ensureInitialized()` → `ProviderScope` → `CollectIqApp` → unawaited `AuthDeepLinkCoordinator.start()` → `MaterialApp(home: AppShell)` → `AppShell` watches `onboardingControllerProvider` → `SharedPreferencesOnboardingRepository` key `onboarding_completed_v1` → `OnboardingScreen` when false; loading spinner while resolving; `HomeScreen` fallback on preference error; otherwise selected shell tab (default Home).

Supabase auth session restoration is owned separately by `authControllerProvider` / `AuthController.build()` and `loadCurrentUser()`, backed by `SupabaseAuthRepository`, `SupabaseService`, and persisted key `supabase_auth_session`. It affects the Settings account panel and cloud eligibility; it does **not** redirect app entry.

Android callbacks use method channel `collectiq_ai/auth_links`; accepted intent shape is `<flavour-scheme>://auth/callback`. Schemes are `collectiq-local`, `collectiq-sit`, and `collectiq` (prod/default). `AuthCallbackParser` accepts the current environment, then `AuthDeepLinkCoordinator` completes an email-confirmation session or publishes confirmation status into `authControllerProvider`.

## Explicit answers

1. Fresh install: native Android launch drawable, Flutter onboarding preference loading spinner, then `OnboardingScreen`.
2. Valid session: onboarding still decides entry; after completion the shell opens Home. Session only changes Settings/cloud state.
3. Signed out: same onboarding/shell flow; local product remains usable and Settings shows account access.
4. Password-recovery deep link: the mobile parser returns `ignored` for `type=recovery`; Android intentionally does not intercept the HTTPS URL. Reset email redirects to the separate web page at `https://packlox.com/auth/reset-password`, whose password-update flow is covered by `web_auth_pages_test.dart`.
5. Email verification callback: valid tokens call `completeAuthCallback`; controller becomes signed in. Confirmation without a session becomes signed out with a success message; invalid/expired produces a controller error. The visible message is in Settings, not a callback route.
6. Guest mode: yes. Local mode is default; explicit anonymous Supabase sign-in exists; signed-out users can scan and keep a local portfolio.
7. Onboarding: once, controlled by a persisted Boolean; it can be reset through the controller.
8. First-run owner: `OnboardingController` + `SharedPreferencesOnboardingRepository.completedKey`.
9. Before Home: native splash, then async onboarding-loading scaffold; on first run, onboarding.
10. Duplicate/legacy entry: no named entry routes; `HomeScreen extends HomePage` is an alias. Scanner has duplicate legacy wrappers/pages (`presentation/scanner_screen.dart`, `pages/scanner_screen.dart`, `ScanWorkspaceScreen`) alongside canonical `ScanHubPage`.
11. CollectIQ branding remains in class/channel/package/config identifiers and SIT diagnostic log labels; visible Material title is PackLox. Native splash color resource identifiers remain CollectIQ-era.
12. Flavours change environment, application ID suffix, callback scheme, cloud flags/config and developer diagnostics—not the shell route. Local defaults cloud flags off; SIT scripts opt into services.

There is no fatal-configuration entry screen, offline-bootstrap screen, mobile auth guard, profile-lookup gate, or synchronous bootstrap barrier today. Cloud startup is deliberately unawaited and safe-no-op/fallback oriented. Web authentication pages exist outside the mobile Navigator architecture.
