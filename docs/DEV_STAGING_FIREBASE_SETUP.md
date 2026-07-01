# Dev/Staging Firebase Setup

This sprint wires Firebase behind CollectIQ AI cloud service interfaces for non-production environments only.

Production remains disabled. Local mode remains fully no-op.

## What Is Wired

Firebase-backed adapters exist for:

- Firebase Core bootstrap
- Firebase Auth anonymous sign-in/sign-out/current user
- Firebase Analytics event tracking
- Firebase Crashlytics non-fatal error capture
- Firebase Remote Config reads

The UI and controllers must continue using `CloudServiceRegistry` and service interfaces. They should not import Firebase SDKs directly.

## Environment Rules

Supported values:

- `APP_ENV=local` - default, all no-op
- `APP_ENV=dev` - Firebase may be used if feature flags are enabled
- `APP_ENV=staging` - Firebase may be used if feature flags are enabled
- `APP_ENV=prod` - Firebase is safe-disabled for now

Production Firebase wiring must be handled in a future release-readiness sprint with explicit config review.

## Feature Flags

Enable only the services needed for a test run:

```powershell
flutter run `
  --dart-define=APP_ENV=dev `
  --dart-define=USE_CLOUD_AUTH=true `
  --dart-define=USE_ANALYTICS=true `
  --dart-define=USE_CRASH_REPORTING=true
```

Available flags:

- `USE_CLOUD_AUTH`
- `USE_CLOUD_PORTFOLIO_SYNC`
- `USE_CLOUD_IMAGE_STORAGE`
- `USE_CRASH_REPORTING`
- `USE_ANALYTICS`
- `USE_REAL_AI_PROVIDER`

Legacy `COLLECTIQ_ENV` and `COLLECTIQ_USE_*` names are still accepted as
fallbacks for older local scripts, but new runs should use `APP_ENV` and
`USE_*`.

Cloud portfolio sync and cloud image storage are active only in dev/staging
when their flags are enabled and Firebase config is present.

## Firebase Project Setup

Create separate Firebase projects:

- `collectiq-ai-dev`
- `collectiq-ai-staging`

Do not reuse a production project for development.

For each project:

1. Open Firebase Console.
2. Add an Android app.
3. Use the package name from the Android manifest.
4. Download `google-services.json`.
5. Place the file in `android/app/google-services.json` for local testing.
6. Enable Anonymous Authentication if testing Firebase Auth.
7. Enable Crashlytics, Analytics, and Remote Config only for the project being tested.

If multiple Firebase projects are needed on one machine, keep environment-specific config files outside the repo and copy the correct one into `android/app/google-services.json` before running.

## Credential Safety

Do not commit:

- production Firebase config files
- service account JSON
- private keys
- API provider secrets
- backend service credentials

Firebase Android config contains public project identifiers, but it still should be reviewed before committing. Production config must not be added in this sprint.

## Verification

Local no-op verification:

```powershell
flutter test
flutter run --dart-define=APP_ENV=local
```

Dev Firebase Auth smoke test:

```powershell
flutter run `
  --dart-define=APP_ENV=dev `
  --dart-define=USE_CLOUD_AUTH=true
```

Expected:

- Local mode runs without Firebase config.
- Dev/staging uses Firebase adapters only when flags are true.
- Prod returns no-op services even if flags are accidentally enabled.
- No UI/controller imports Firebase directly.

## Production Protection

`FirebaseBootstrap` intentionally returns a safe-disabled result for `APP_ENV=prod`. This prevents accidental production traffic until production credentials, policies, release process, and monitoring are explicitly reviewed.
