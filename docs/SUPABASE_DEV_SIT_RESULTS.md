# Supabase DEV SIT Results

Run date: 2026-07-01

Sprint: Supabase DEV End-to-End Sync Validation

## Scope

Validate the existing non-production Supabase path for:

- Supabase Auth
- Supabase Storage bucket `collectiq-portfolio-images`
- Supabase table `portfolio_items`
- Local-save-first portfolio sync behavior

Production remains disabled. Local mode remains the default.

## Required DEV Configuration

Run the app with these dart defines for live DEV validation:

```powershell
flutter run `
  --dart-define=APP_ENV=dev `
  --dart-define=USE_CLOUD_AUTH=true `
  --dart-define=USE_CLOUD_PORTFOLIO_SYNC=true `
  --dart-define=USE_CLOUD_IMAGE_STORAGE=true `
  --dart-define=SUPABASE_URL=https://YOUR-DEV-PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_DEV_ANON_KEY
```

Do not commit Supabase values. Use only a DEV project.

## Config Check

| Required value | Result in this Codex session | Notes |
| --- | --- | --- |
| `APP_ENV=dev` | Not configured in shell | Covered by automated flag parsing tests. |
| `USE_CLOUD_AUTH=true` | Not configured in shell | Covered by automated flag parsing tests. |
| `USE_CLOUD_PORTFOLIO_SYNC=true` | Not configured in shell | Covered by automated flag parsing tests. |
| `USE_CLOUD_IMAGE_STORAGE=true` | Not configured in shell | Covered by automated flag parsing tests. |
| `SUPABASE_URL` | Not configured in shell | Live Supabase run not executed. |
| `SUPABASE_ANON_KEY` | Not configured in shell | Live Supabase run not executed. |

## Automated Validation Results

| Area | Result | Evidence |
| --- | --- | --- |
| Local mode unchanged | Passed | Registry returns no-op services in local mode; existing `flutter test` suite passed. |
| Production disabled | Passed | Supabase bootstrap returns disabled in `APP_ENV=prod`; registry stays no-op. |
| DEV registry selection | Passed | `APP_ENV=dev` plus cloud flags selects Supabase Auth, Storage, and Portfolio Sync services. |
| Missing config fallback | Passed | Missing Supabase URL/key returns safe missing-config status. |
| Anonymous auth fallback | Passed | Startup attempts anonymous auth only in DEV with auth flag; failures are tracked and do not throw. |
| User ID before sync | Passed | Coordinator checks signed-in user ID before upload/sync. |
| Storage object path | Passed | Expected path: `users/{userId}/portfolio_images/{itemId}.jpg`. |
| Portfolio table row | Passed | `portfolio_items` row mapping includes id, user_id, title, category, manufacturer, series, year, country, estimated value low/high, cloud image URL, sync status, raw JSON, created_at, and updated_at. |
| Local save before cloud sync | Passed | Sync coordinator only processes items already loaded from local portfolio; scanner save path saves locally before starting cloud sync. |
| Success state | Passed | Upload success syncs metadata and marks local item `synced`. |
| Failure state | Passed | Upload failure preserves local image path and marks item `failed` with retryable error context. |

## Live DEV SIT Status

Live Supabase DEV validation was not executed in this Codex session because no `SUPABASE_URL` or `SUPABASE_ANON_KEY` was available in the shell, and no Android device/emulator was validated here.

Once DEV credentials are supplied locally, run the app with the required dart defines and confirm:

1. Supabase anonymous auth creates a DEV user.
2. Settings shows Supabase cloud-ready status after auth.
3. Camera/gallery save completes locally first.
4. A storage object appears at:
   `collectiq-portfolio-images/users/{userId}/portfolio_images/{itemId}.jpg`
5. A row appears or updates in:
   `portfolio_items`
6. The local detail page sync status becomes `Synced`.
7. Turning off network or breaking storage policy keeps the item local and shows a failed/retryable sync state.

## Verification Commands

```powershell
dart format lib test
flutter analyze
flutter test
```

Latest results from this sprint:

- `dart format lib test`: passed
- `flutter analyze`: passed
- `flutter test`: passed

