# Android DEV Firebase SIT

This checklist verifies that CollectIQ AI can run with real DEV Firebase
services on Android without affecting local/default mode or production.

Production remains disabled in this sprint.

## Dart Defines

Local/default mode:

```powershell
flutter run
```

Equivalent explicit local mode:

```powershell
flutter run --dart-define=APP_ENV=local
```

DEV cloud-enabled mode:

```powershell
flutter run `
  --dart-define=APP_ENV=dev `
  --dart-define=USE_CLOUD_AUTH=true `
  --dart-define=USE_CLOUD_PORTFOLIO_SYNC=true `
  --dart-define=USE_CLOUD_IMAGE_STORAGE=true `
  --dart-define=USE_ANALYTICS=true `
  --dart-define=USE_CRASH_REPORTING=true `
  --dart-define=USE_REAL_AI_PROVIDER=false
```

Older `COLLECTIQ_*` defines are still accepted as a fallback, but new smoke
tests should use `APP_ENV` and `USE_*`.

## Android Firebase Config

1. Create or open the non-production Firebase project, for example
   `collectiq-ai-dev`.
2. Add an Android app with package name:

```text
com.collectiq.ai
```

3. Download `google-services.json`.
4. Place it locally at:

```text
android/app/google-services.json
```

5. Do not commit production config. This path is ignored by git by default.

The Android Gradle project registers the Google Services plugin, but the app
module applies it only when `android/app/google-services.json` exists. Local
mode can therefore build and run without Firebase config.

## Firebase Console Setup

For DEV SIT, enable only the services you are testing:

- Authentication: enable Anonymous provider.
- Firestore: create DEV database and rules for test users.
- Storage: create DEV bucket and rules for test users.
- Analytics: enabled only when `USE_ANALYTICS=true`.
- Crashlytics: enabled only when `USE_CRASH_REPORTING=true`.

Do not configure production Firebase in this sprint.

## Smoke Test

### 1. Local Launch

Run:

```powershell
flutter run --dart-define=APP_ENV=local
```

Expected:

- App launches.
- Scan, save, portfolio, settings still work.
- No Firebase config is required.
- Settings shows cloud sync disabled/local-only behavior.

### 2. DEV Launch

Run the DEV command from the Dart Defines section.

Expected:

- App launches.
- Missing Firebase config produces only a safe warning and app remains usable.
- With `google-services.json` present, Firebase initializes for DEV only.
- Production remains disabled.

### 3. Anonymous Auth

In DEV Firebase Console:

- Open Authentication.
- Confirm a new anonymous user appears after app startup.

Expected app behavior:

- No login UI is required.
- If auth fails, app continues local-only.

### 4. Save + Sync

In the app:

1. Scan or use gallery.
2. Analyze.
3. Save to Portfolio.

Expected:

- Item appears locally immediately.
- If cloud flags and Firebase config are valid, image upload starts in the
  background.
- Portfolio detail status becomes `Synced` after successful cloud sync.
- If upload fails, item remains local and detail status becomes `Sync failed`.

Firebase Console checks:

- Storage object path:

```text
users/{userId}/portfolio_images/{itemId}.jpg
```

- Firestore document path:

```text
users/{userId}/portfolio_items/{itemId}
```

### 5. Manual Sync

Open Settings and tap `Sync Now`.

Expected:

- Enabled only in dev/staging with cloud portfolio and image flags.
- Local/prod shows `Cloud sync is disabled in this environment`.
- Successful sync updates local item status.
- Failed sync does not delete or hide local portfolio items.

### 6. Analytics / Crash Reporting

With flags enabled, verify DEV dashboards receive safe events only:

- `app_started`
- `anonymous_auth_success` or `anonymous_auth_failed`
- `portfolio_item_saved`
- `portfolio_sync_started`
- `portfolio_sync_success` or `portfolio_sync_failed`
- `manual_sync_clicked`

Do not log emails, image paths, API keys, tokens, or personal content.

### 7. Production Guard

Run:

```powershell
flutter run `
  --dart-define=APP_ENV=prod `
  --dart-define=USE_CLOUD_AUTH=true `
  --dart-define=USE_CLOUD_PORTFOLIO_SYNC=true `
  --dart-define=USE_CLOUD_IMAGE_STORAGE=true `
  --dart-define=USE_ANALYTICS=true `
  --dart-define=USE_CRASH_REPORTING=true
```

Expected:

- App remains usable.
- Cloud registry returns no-op services.
- No real production Firebase services are contacted.

## Pass / Fail Criteria

Pass when:

- Local mode works without `google-services.json`.
- DEV mode works with DEV Firebase config.
- Anonymous DEV user is created.
- Save remains local-first.
- Storage and Firestore entries appear for synced items.
- Manual sync works.
- Production remains disabled/no-op.

Fail if:

- Local mode requires Firebase config.
- PROD contacts real cloud services.
- Local save is blocked by cloud failure.
- Firebase SDKs are imported directly by UI/controllers.
