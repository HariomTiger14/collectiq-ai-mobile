# PackLox SIT Cloud Foundation Final Report

Baseline: `ec7ba66` (`fix: stabilize Android release shell tab switching`)

## Architecture Diagram

```text
PackLox Flutter app
  |
  v
Riverpod controllers
  |
  +-- AuthController
  |     |
  |     v
  |   SupabaseAuthRepository
  |     |
  |     v
  |   SupabaseService
  |
  +-- PortfolioController / ScannerController / SyncController
        |
        v
      SharedPreferencesPortfolioRepository
        |
        v
      CloudPortfolioSyncCoordinator
        |
        +-- SupabaseCloudStorageService
        |     bucket: collectiq-portfolio-images
        |     path: users/{userId}/portfolio_images/{itemId}.{ext}
        |
        +-- SupabaseCloudPortfolioSyncService
              table: public.portfolio_items

Analytics, crash reporting, and remote config remain no-op placeholders.
```

## Files Removed

- `lib/core/cloud/firebase/firebase_auth_service.dart`
- `lib/core/cloud/firebase/firebase_cloud_storage_service.dart`
- `lib/core/cloud/firebase/firebase_cloud_portfolio_sync_service.dart`
- `lib/core/cloud/firebase/firebase_remote_config_service.dart`
- `lib/core/cloud/firebase/firebase_analytics_service.dart`
- `lib/core/cloud/firebase/firebase_crash_reporting_service.dart`
- `lib/core/cloud/firebase/firebase_bootstrap.dart`
- `docs/ANDROID_DEV_FIREBASE_SIT.md`
- `docs/DEV_STAGING_FIREBASE_SETUP.md`

Removed package families:

- Firebase Core/Auth/Storage/Remote Config/Analytics/Crashlytics
- Cloud Firestore
- Android Google Services Gradle hook

## Files Modified

- Cloud registry and Supabase bootstrapping now select only Supabase or no-op
  services.
- Runtime cloud gates now use `EnvironmentConfig.allowsCloudServices`.
- Production Supabase can be selected only with explicit cloud flags and public
  Supabase config.
- Telemetry is now no-op/placeholder only.
- Tests and docs were updated to match the single-provider architecture.

## Authentication Status

Verified by automated tests:

- Local/no-config fallback
- Supabase repository selection
- Sign up/sign in normalization paths
- Email confirmation pending/error handling
- Resend confirmation cooldown/rate-limit handling
- Forgot-password request handling
- Deep-link callback parser/coordinator behavior
- Logout/local state transition
- Settings account-state behavior through widget coverage

Not live-verified in this Codex session:

- Real Supabase email delivery
- Real reset-password password update page
- Real token refresh against an expiring Supabase session

## Storage Status

Verified by automated tests:

- Supabase bucket/path convention
- Local image persistence path preservation
- Upload success marks local item synced
- Upload failure keeps local item visible and retryable
- Delete/metadata tombstone path
- Missing-config local fallback

Not live-verified:

- Real private bucket signed URL behavior
- Real camera/gallery Android picker persistence
- Large image upload performance

## Sync Status

Verified by automated tests:

- Local-first save
- Pending/failed/synced item transitions
- Manual cloud sync merge
- Update sync
- Delete tombstone
- RLS-compatible `user_id` row shape
- Production missing-config fallback

Not live-verified:

- Real Supabase RLS/storage policy enforcement
- Multi-device conflict behavior
- Offline network toggling on a device

## Remaining Technical Debt

- `SupabaseService` still uses a custom REST gateway. A future hardening sprint
  should decide whether to migrate fully to `supabase_flutter` for session
  refresh and password update flows.
- Live SIT requires real `SUPABASE_URL`, `SUPABASE_ANON_KEY`, email inbox
  access, and an Android device/emulator.
- Analytics/crash provider selection remains intentionally out of scope.
- Analyzer API integration remains untouched.

## Recommended Next Sprint

Run live Supabase SIT on Android:

1. Fresh install with SIT flags and Supabase config.
2. Create account, verify email, log in, restore session.
3. Capture/gallery image, save collectible, upload image, sync metadata.
4. Restart, logout/login, verify portfolio restore.
5. Toggle network off/on and verify retry behavior.
6. Then start Analyzer API integration only after the cloud foundation is live
   validated.
