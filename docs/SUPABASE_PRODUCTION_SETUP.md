# Supabase Setup

Status: Supabase is the single cloud architecture for SIT and production
foundation work. Production traffic requires explicit flags and public Supabase
config.

For the canonical schema, bucket, RLS policies, and sync flow, see `docs/SUPABASE_ARCHITECTURE.md`.

## Active Schema

- Table: `public.portfolio_items`
- Profile table: `public.user_profiles`
- Bucket: `collectiq-portfolio-images`
- Object path: `users/{userId}/portfolio_images/{itemId}.jpg`

## Required Flags

SIT/dev/prod builds may use Supabase only when flags and config are supplied:

- `APP_ENV=sit`, `APP_ENV=dev`, or `APP_ENV=prod`
- `SUPABASE_ENABLED=true`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `USE_CLOUD_AUTH=true`
- `USE_CLOUD_PORTFOLIO_SYNC=true`
- `USE_CLOUD_IMAGE_STORAGE=true`

Production falls back safely when these flags or Supabase values are missing.

## Safety Rules

- Do not commit Supabase secrets or service-role keys.
- Do not enable production from local config.
- Apply committed migrations before SIT sync validation.
- Confirm `auth.uid() = user_id` ownership policies before using real tester accounts.
