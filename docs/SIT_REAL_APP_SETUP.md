# CollectIQ SIT Real App Setup

Audit date: 2026-07-01

This guide configures **CollectIQ SIT** as a non-production cloud-connected Android app. Production remains disabled.

## Required Local Config

Create `config/sit.env` from `config/sit.env.example`.

```bat
SUPABASE_URL=https://YOUR-DEV-PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
API_BASE_URL=http://YOUR-LAN-IP:8000
```

Do not commit `config/sit.env`. Do not put service-role keys, provider API keys, signing passwords, or private prompts in Flutter config.

## Supabase Checklist

For exact live Supabase console steps, use `docs/SUPABASE_LIVE_SIT_SETUP.md`.

Auth:

- Enable email/password auth in Supabase Auth.
- Decide whether email confirmation is required for SIT testers.
- Anonymous auth is optional; email auth is the SIT path.

Storage:

- Create bucket `collectiq-portfolio-images`.
- Expected object path: `users/{userId}/portfolio_images/{itemId}.jpg`.
- Add RLS policies allowing signed-in users to insert, update, select, and delete only objects under their own `users/{auth.uid()}/...` prefix.

Portfolio table:

- Create table `portfolio_items`.
- Required columns include `id`, `user_id`, `category`, `title`, `manufacturer`, `series`, `year`, `country`, `estimated_value_low`, `estimated_value_high`, `image_local_path`, `image_storage_path`, `cloud_image_url`, `sync_status`, `last_synced_at`, `raw_json`, `created_at`, and `updated_at`.
- Use the committed primary key on `(id, user_id)`.
- Add RLS policies allowing signed-in users to select, insert, update, and tombstone only rows where `user_id = auth.uid()`.

Static/local validation:

```bat
python scripts\validate_supabase_setup.py
```

Live DEV/SIT validation after `config/sit.env` is filled in:

```bat
.\check_supabase_sit.bat
```

## Run SIT

```bat
.\run_sit.bat
```

The script passes:

- `APP_ENV=sit`
- `USE_CLOUD_AUTH=true`
- `USE_CLOUD_PORTFOLIO_SYNC=true`
- `USE_CLOUD_IMAGE_STORAGE=true`
- `SUPABASE_ENABLED=true`
- values loaded from `config/sit.env`

If Supabase keys are missing, the app shows setup-required status and keeps local portfolio behavior available.

## Build And Install

```bat
.\build_sit_apk.bat
adb install -r build\app\outputs\flutter-apk\app-sit-debug.apk
```

The installed app name is **CollectIQ SIT**.

## Test Flow

1. Open Settings.
2. Confirm **SIT Readiness** shows `Environment: SIT`.
3. Confirm Supabase and backend URL status.
4. Sign up with an email/password account.
5. Restart the app and confirm the signed-in user is still shown.
6. Use camera or gallery to choose an image.
7. Analyze the image. Flutter calls the backend through `API_BASE_URL`; it never calls OpenAI directly.
8. Save the result. The item is saved locally first, then queued for cloud sync.
9. Tap **Sync Now** in Settings.
10. Confirm the image appears in `collectiq-portfolio-images`.
11. Confirm metadata appears in `portfolio_items`.
12. Edit the item and sync again; confirm the row updates.
13. Delete the item; confirm the row is tombstoned with `sync_status = deleted`.

## Backend AI

Start the FastAPI backend so the Android phone can reach `API_BASE_URL`.

For deployment/run details, use `docs/BACKEND_SIT_DEPLOYMENT.md`.

If backend AI is unreachable, the app shows:

```text
AI backend is not reachable. Check your internet/backend setup.
```

## Known Limitations

- Production remains disabled.
- The app still has local-first behavior; cloud failure must not delete local data.
- Marketplace, subscriptions, trending, and global reference search remain out of scope.
- Live Supabase validation requires real DEV project credentials and phone/network access.
