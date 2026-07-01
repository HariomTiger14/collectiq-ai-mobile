# CollectIQ Real App Readiness Audit

Audit date: 2026-07-01

Status: superseded by the Supabase architecture unification sprint.

The current repository now uses one Supabase SIT architecture:

- Table: `public.portfolio_items`
- Profile table: `public.user_profiles`
- Storage bucket: `collectiq-portfolio-images`
- Storage path: `users/{userId}/portfolio_images/{itemId}.jpg`

See `docs/SUPABASE_ARCHITECTURE.md` for the active schema, RLS policies, sync flow, and migration report.

Remaining readiness statements from the original audit still apply unless separately verified:

- Live Supabase DEV/SIT project behavior is not verified from repository code alone.
- Physical Android install, camera/gallery, backend reachability, and full cloud sync SIT are not verified from repository code alone.
- Real AI and live pricing provider behavior are not verified from repository code alone.
- Production cloud services remain disabled.
