# Supabase Setup

Status: production remains disabled. This document records the single Supabase architecture used for SIT preparation only.

For the canonical schema, bucket, RLS policies, and sync flow, see `docs/SUPABASE_ARCHITECTURE.md`.

## Active Schema

- Table: `public.portfolio_items`
- Profile table: `public.user_profiles`
- Bucket: `collectiq-portfolio-images`
- Object path: `users/{userId}/portfolio_images/{itemId}.jpg`

## Required Flags

SIT/dev builds may use Supabase only when non-production flags and config are supplied:

- `APP_ENV=sit` or `APP_ENV=dev`
- `SUPABASE_ENABLED=true`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `USE_CLOUD_AUTH=true`
- `USE_CLOUD_PORTFOLIO_SYNC=true`
- `USE_CLOUD_IMAGE_STORAGE=true`

Production cloud services remain disabled until a later production-readiness pass explicitly enables them.

## Safety Rules

- Do not commit Supabase secrets or service-role keys.
- Do not enable production from local config.
- Apply committed migrations before SIT sync validation.
- Confirm `auth.uid() = user_id` ownership policies before using real tester accounts.
