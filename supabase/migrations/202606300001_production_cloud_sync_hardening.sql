-- CollectIQ AI production cloud sync hardening.
-- Adds soft-delete and sync bookkeeping columns without weakening RLS.
-- Safe to run after 202606290001_collectiq_cloud_schema.sql.

alter table public.collectibles
add column if not exists deleted_at timestamptz,
add column if not exists last_synced_at timestamptz,
add column if not exists sync_status text not null default 'synced',
add column if not exists cloud_version integer not null default 1;

alter table public.collections
add column if not exists deleted_at timestamptz,
add column if not exists last_synced_at timestamptz,
add column if not exists sync_status text not null default 'synced',
add column if not exists cloud_version integer not null default 1;

alter table public.scan_history
add column if not exists deleted_at timestamptz;

alter table public.pricing_snapshots
add column if not exists deleted_at timestamptz;

alter table public.favorites
add column if not exists deleted_at timestamptz;

alter table public.wishlist
add column if not exists deleted_at timestamptz,
add column if not exists last_synced_at timestamptz,
add column if not exists sync_status text not null default 'synced',
add column if not exists cloud_version integer not null default 1;

create index if not exists collectibles_user_saved_idx
on public.collectibles(user_id, saved_at desc);

create index if not exists collectibles_user_deleted_idx
on public.collectibles(user_id, deleted_at);

create index if not exists collections_user_deleted_idx
on public.collections(user_id, deleted_at);

create index if not exists wishlist_user_deleted_idx
on public.wishlist(user_id, deleted_at);

create index if not exists scan_history_user_deleted_idx
on public.scan_history(user_id, deleted_at);

create index if not exists pricing_snapshots_user_deleted_idx
on public.pricing_snapshots(user_id, deleted_at);

create index if not exists favorites_user_deleted_idx
on public.favorites(user_id, deleted_at);

alter table public.collectibles
drop constraint if exists collectibles_sync_status_check;
alter table public.collectibles
add constraint collectibles_sync_status_check
check (sync_status in ('local_only', 'pending', 'syncing', 'synced', 'failed', 'retryable', 'conflict'));

alter table public.collections
drop constraint if exists collections_sync_status_check;
alter table public.collections
add constraint collections_sync_status_check
check (sync_status in ('local_only', 'pending', 'syncing', 'synced', 'failed', 'retryable', 'conflict'));

alter table public.wishlist
drop constraint if exists wishlist_sync_status_check;
alter table public.wishlist
add constraint wishlist_sync_status_check
check (sync_status in ('local_only', 'pending', 'syncing', 'synced', 'failed', 'retryable', 'conflict'));
