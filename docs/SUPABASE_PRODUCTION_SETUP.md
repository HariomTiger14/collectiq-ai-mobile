# Supabase Production Setup

CollectIQ AI is local-first. Supabase adds optional account-backed cloud sync,
but the mobile app must still scan, save, search, delete, and view the local
portfolio without login.

## Required Flutter configuration

Pass only the public Supabase anon configuration to Flutter:

```powershell
flutter run `
  --dart-define=SUPABASE_ENABLED=true `
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-anon-public-key
```

Never put service-role keys, database passwords, OpenAI keys, pricing keys, or
OAuth client secrets in Flutter source or dart-define values.

## Auth setup

1. Create a Supabase project.
2. Open Authentication -> Providers.
3. Enable Email.
4. Decide whether email confirmation is required for your test environment.
5. Keep Google and Apple disabled until OAuth client setup is intentionally
   added.

Cloud sync writes only when the app has a signed-in email/password Supabase
session. Signed-out/local mode stays local-only.

## Database setup

Run these SQL files in order:

```text
supabase/migrations/202606290001_collectiq_cloud_schema.sql
supabase/migrations/202606290002_collectible_images_storage_policies.sql
supabase/migrations/202606300001_production_cloud_sync_hardening.sql
```

The schema creates:

- `public.users`
- `public.collections`
- `public.collectibles`
- `public.scan_history`
- `public.pricing_snapshots`
- `public.favorites`
- `public.wishlist`

The `collectibles` table contains the fields the Flutter sync code upserts:

- `id`
- `user_id`
- `title`
- `category`
- `condition`
- `image_path`
- `image_storage_path`
- `estimated_value`
- `confidence`
- `metadata`
- `ai_review`
- `pricing`
- `saved_at`
- `updated_at`

The hardening migration adds soft-delete and sync metadata fields such as
`deleted_at`, `last_synced_at`, `sync_status`, and `cloud_version`.

## RLS policy summary

Row Level Security is enabled for every public app table.

Each owner-scoped table uses the same policy shape:

- `select`: `auth.uid() = user_id`
- `insert`: `with check (auth.uid() = user_id)`
- `update`: `using (auth.uid() = user_id)` and
  `with check (auth.uid() = user_id)`
- `delete`: `using (auth.uid() = user_id)`

For `public.users`, ownership uses `auth.uid() = id`.

Relationship tables, including pricing snapshots and favorites, also verify the
referenced collectible belongs to the authenticated user on insert.

## Storage setup

Run:

```text
supabase/migrations/202606290002_collectible_images_storage_policies.sql
```

This creates the private `collectible-images` bucket.

Flutter uploads images using this object layout:

```text
{userId}/{collectibleCloudId}/image.ext
```

The full storage object path sent to Supabase is:

```text
collectible-images/{userId}/{collectibleCloudId}/image.ext
```

Storage policies allow authenticated users to select, insert, update, and delete
objects only when the first folder in `storage.objects.name` matches
`auth.uid()::text`.

## Validation

Run local static validation:

```powershell
.\scripts\validate_supabase_setup.ps1
```

Run live read-only SQL checks when `psql` is installed:

```powershell
$env:SUPABASE_DB_URL = "postgresql://..."
.\scripts\validate_supabase_setup.ps1 -Live
```

The live check uses:

```text
supabase/setup/production_readiness_checks.sql
```

It reports:

- expected tables
- RLS enabled
- expected public table policies
- private `collectible-images` bucket
- expected storage policies

## Manual verification checklist

1. Run all SQL setup files.
2. Run the validation script.
3. Launch Flutter with Supabase dart defines.
4. Sign up or sign in from Settings.
5. Save a scanned collectible.
6. Tap Sync Now.
7. Confirm `public.collectibles.user_id` equals the signed-in Supabase user id.
8. Confirm Storage object path starts with that same user id.
9. Sign out and confirm local portfolio items remain visible.
10. Confirm local scan/save still works with network disabled.
