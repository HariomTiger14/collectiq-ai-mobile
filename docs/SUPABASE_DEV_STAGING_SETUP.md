# Supabase DEV/STAGING Setup

Supabase is the primary DEV/STAGING backend for CollectIQ AI auth, portfolio
metadata sync, and image storage.

Production uses the same Supabase foundation only when explicit production
flags and public Supabase config are supplied. Local mode remains no-op.

## Runtime Flags

Local/default mode:

```powershell
flutter run
```

DEV Supabase mode:

```powershell
flutter run `
  --dart-define=APP_ENV=dev `
  --dart-define=USE_CLOUD_AUTH=true `
  --dart-define=USE_CLOUD_PORTFOLIO_SYNC=true `
  --dart-define=USE_CLOUD_IMAGE_STORAGE=true `
  --dart-define=SUPABASE_URL=https://YOUR-DEV-PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_DEV_ANON_KEY
```

Staging uses the same flags with `APP_ENV=staging` and staging project values.

Do not pass production Supabase values in this sprint.

## Required Supabase Values

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

These are read only from dart-define values. They are not hardcoded in source.

If either value is missing in DEV/STAGING, Supabase bootstrap logs a safe
warning and services behave as no-op/fallback. The app remains usable locally.

## Auth

Enable Supabase Auth anonymous sign-in for DEV/STAGING.

The app calls `AuthService.signInAnonymously()` only through
`CloudServiceRegistry`. If anonymous auth fails, the app continues local-only.

## Storage

Create a Storage bucket:

```text
collectiq-portfolio-images
```

Image path convention:

```text
users/{userId}/portfolio_images/{itemId}.jpg
```

The local image file is never deleted if cloud upload fails.

## Portfolio Metadata Table

Create table:

```text
portfolio_items
```

Expected columns:

| Column | Suggested Type | Notes |
| --- | --- | --- |
| `id` | `text primary key` | Local collectible id |
| `user_id` | `uuid/text` | Supabase auth user id |
| `category` | `text` | Display category |
| `title` | `text` | Display title |
| `manufacturer` | `text null` | Mapped from brand |
| `series` | `text null` | Mapped from series/set |
| `year` | `int null` | Parsed if available |
| `country` | `text null` | Optional |
| `estimated_value_low` | `numeric null` | Pricing low estimate |
| `estimated_value_high` | `numeric null` | Pricing high estimate |
| `image_local_path` | `text null` | Local-only path for current device |
| `cloud_image_url` | `text null` | Signed/public URL cache |
| `sync_status` | `text` | `localOnly`, `pendingUpload`, `synced`, `failed` |
| `last_synced_at` | `timestamptz null` | Last successful sync |
| `raw_json` | `jsonb` | Full `CollectibleItem.toJson()` payload |
| `created_at` | `timestamptz` | Local save timestamp |
| `updated_at` | `timestamptz` | Cloud row update timestamp |

The app writes normalized columns plus `raw_json`. If the schema differs, the
sync service prefers `raw_json` during download and falls back to normalized
columns. Optional/missing fields should not crash local mode.

## RLS Notes

Enable RLS on `portfolio_items`.

Policy intent:

- Users can select rows where `user_id = auth.uid()`.
- Users can insert rows where `user_id = auth.uid()`.
- Users can update rows where `user_id = auth.uid()`.
- Users can soft-delete/update only their own rows.

Storage policy intent for bucket `collectiq-portfolio-images`:

- Users can read/write/delete objects whose path starts with:

```text
users/{auth.uid()}/
```

## Verification

1. Run local mode without Supabase values.
2. Confirm scan/save/portfolio works.
3. Run DEV mode with Supabase values and cloud flags.
4. Confirm an anonymous Supabase user appears.
5. Save a collectible.
6. Confirm Storage object appears under the expected path.
7. Confirm `portfolio_items` row appears.
8. Confirm item detail shows `Synced`.
9. Disable network/config and confirm local save still works.

## Production Checklist Later

Before production can be enabled:

1. Create separate production Supabase project.
2. Review table schema and migrations.
3. Review RLS policies.
4. Review Storage policies.
5. Add monitoring and alerting.
6. Confirm data deletion/export workflows.
7. Review privacy policy and Data Safety disclosures.
8. Explicitly enable production in code/config in a dedicated release sprint.
