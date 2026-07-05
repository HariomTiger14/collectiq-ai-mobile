# Supabase Live SIT Setup

Audit date: 2026-07-01

This guide prepares a real non-production Supabase project for **CollectIQ SIT**.
Production Supabase uses the same foundation only when explicit production
flags and public Supabase config are supplied.

Use only the unified SIT architecture:

- Table: `public.portfolio_items`
- Profile table: `public.user_profiles`
- Storage bucket: `collectiq-portfolio-images`
- Storage path: `users/{userId}/portfolio_images/{itemId}.jpg`

Do not commit secrets. Use only the public anon key in Flutter/SIT config. Never put service-role keys in `config/sit.env`.

## 1. Open Supabase SQL Editor

1. Open the Supabase dashboard.
2. Select the DEV/SIT project.
3. Open **SQL Editor**.
4. Create a new query.
5. Open this repository file locally:

```text
supabase/migrations/202607010001_collectiq_portfolio_items_schema.sql
```

6. Paste the full SQL into the Supabase SQL Editor.
7. Run the query.
8. Confirm the query completes without errors.

## 2. Verify Tables

In Supabase, open **Table Editor** and verify:

- `user_profiles`
- `portfolio_items`

Expected `portfolio_items` columns include:

- `id`
- `user_id`
- `category`
- `title`
- `manufacturer`
- `series`
- `year`
- `country`
- `estimated_value_low`
- `estimated_value_high`
- `image_local_path`
- `image_storage_path`
- `cloud_image_url`
- `sync_status`
- `last_synced_at`
- `raw_json`
- `created_at`
- `updated_at`

Expected key:

- Primary key on `(id, user_id)`

## 3. Verify RLS Policies

In Supabase, open **Authentication > Policies** or the table policy view.

Verify RLS is enabled for:

- `public.user_profiles`
- `public.portfolio_items`

Verify policies exist:

- `Users can read own profile`
- `Users can insert own profile`
- `Users can update own profile`
- `Users can read own portfolio items`
- `Users can insert own portfolio items`
- `Users can update own portfolio items`
- `Users can delete own portfolio items`

The row ownership rule is:

```sql
auth.uid() = user_id
```

For `user_profiles`, the ownership rule is:

```sql
auth.uid() = id
```

## 4. Verify Storage Bucket

The migration creates the bucket automatically. In Supabase, open **Storage** and verify:

```text
collectiq-portfolio-images
```

The bucket should be private.

Expected app upload path:

```text
users/{userId}/portfolio_images/{itemId}.jpg
```

Verify storage policies exist:

- `Users can read own portfolio images`
- `Users can upload own portfolio images`
- `Users can update own portfolio images`
- `Users can delete own portfolio images`

The path policy should scope access to:

```text
users/{auth.uid()}/portfolio_images/*
```

## 5. Verify Auth Email/Password Settings

In Supabase, open **Authentication > Providers > Email**.

For SIT:

1. Enable the Email provider.
2. Enable email/password sign-in.
3. Decide whether email confirmation is required for testers.
4. If email confirmation is enabled, make sure tester emails can receive confirmation links.
5. Open **Authentication > URL Configuration** and set mobile plus Packlox web redirect URLs.

SIT:

```text
Site URL: https://packlox.com/auth/callback
Redirect URLs:
collectiq-sit://auth/callback
https://packlox.com/auth/callback
https://packlox.com/auth/reset-password
```

Future production, reserved only:

```text
collectiq://auth/callback
```

Do not use `localhost` for Android email confirmation. The phone must receive
the custom `collectiq-sit` scheme when testing mobile confirmation, and
password recovery must be able to open the browser route
`https://packlox.com/auth/reset-password` from any device.

Password recovery must not use `collectiq-sit://auth/callback`. If Android
opens the app from a reset password email, the recovery email was generated with
the wrong redirect URL or the tester clicked an older email. Generate a fresh
Forgot Password email after updating Supabase URL Configuration.

The mobile app can show the recovery redirect URL it supplied to Supabase in
**SIT Readiness > Password recovery redirect**, but Supabase does not return the
actual generated email link to the anon recover request. To confirm the exact
link, inspect the received reset email or the Supabase email template/logs.

If the confirmation link opens a blank browser page instead of returning to the
app, return to CollectIQ SIT manually and tap **Sign In** after email
confirmation. Then check **SIT Readiness > Last deep link received** to see
whether Android delivered the callback to the app.

The app uses email/password auth for SIT. Anonymous auth can remain disabled unless you intentionally test guest cloud startup behavior.

## 5a. Packlox Web Auth Pages

The repository includes minimal static pages for browser auth flows:

```text
web/auth/callback/index.html
web/auth/reset-password/index.html
```

Deploy them so these routes resolve:

```text
https://packlox.com/auth/callback
https://packlox.com/auth/reset-password
```

The browser pages load public Supabase config from:

```text
web/auth/config.js
```

Replace the placeholder values during deployment. Commit no real secrets. The
anon key is public, but the service-role key must never be used in these pages.

## 6. Find `SUPABASE_URL`

In Supabase:

1. Open **Project Settings**.
2. Open **API**.
3. Copy the Project URL.

It should look like:

```text
https://YOUR-DEV-PROJECT.supabase.co
```

## 7. Find `SUPABASE_ANON_KEY`

In Supabase:

1. Open **Project Settings**.
2. Open **API**.
3. Copy the public anon key.

Use only the anon key in app config. Do not copy the service-role key into this repository.

## 8. Create `config/sit.env`

Copy:

```text
config/sit.env.example
```

to:

```text
config/sit.env
```

Fill in:

```bat
SUPABASE_URL=https://YOUR-DEV-PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
API_BASE_URL=http://YOUR-LAN-IP:8000
```

`config/sit.env` is ignored by git. Do not commit it.

## 9. Run The Local Static Validator

From the repository root:

```bat
python scripts\validate_supabase_setup.py
```

This validates committed SQL/setup files, not the live Supabase project.

## 10. Run The Live SIT Checker

After `config/sit.env` exists:

```bat
.\check_supabase_sit.bat
```

Or set environment variables yourself and run:

```bat
py scripts\check_live_supabase_sit.py
```

The checker uses only:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

It checks:

- Supabase Auth settings endpoint is reachable.
- `portfolio_items` is visible through the REST schema.
- `user_profiles` is visible through the REST schema.
- Storage endpoint is reachable.
- `collectiq-portfolio-images` bucket is visible or storage APIs are reachable enough to require manual UI verification.

The checker performs no writes.

Private Supabase Storage buckets may not be fully verifiable with only the public anon key. If the checker prints:

```text
Bucket existence not verifiable with anon key; verify manually in Supabase UI
```

open **Storage** in Supabase and confirm `collectiq-portfolio-images` exists. This warning is acceptable for private buckets protected by RLS/storage policies.

## 11. Run CollectIQ SIT

```bat
.\run_sit.bat
```

The app should show **CollectIQ SIT** and keep production disabled.

## 12. Build The SIT APK

```bat
.\build_sit_apk.bat
```

Install on a connected Android phone:

```bat
adb install -r build\app\outputs\flutter-apk\app-sit-debug.apk
```

## Troubleshooting

If table checks fail:

- Re-run `supabase/migrations/202607010001_collectiq_portfolio_items_schema.sql`.
- Confirm you are using the correct DEV/SIT project URL.

If bucket checks fail:

- Confirm `collectiq-portfolio-images` exists.
- Confirm the bucket name has no spelling changes.
- If the checker reports that bucket existence is not verifiable with the anon key, verify the bucket manually in Supabase UI instead of treating it as a setup failure.

If Auth checks fail:

- Confirm the anon key belongs to the same project URL.
- Confirm Email provider is enabled.

If the app can sign in but sync fails:

- Check RLS policies.
- Check storage policies.
- Confirm the signed-in user id matches the `users/{userId}/...` object path.
