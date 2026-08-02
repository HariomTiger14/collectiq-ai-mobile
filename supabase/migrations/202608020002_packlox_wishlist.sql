-- PackLox cloud-backed wishlist / collection-status entries (owned / wanted /
-- missing) keyed to the authenticated user, so a collector's tracked status
-- follows them across devices and reinstalls. On-device SharedPreferences stays
-- the offline cache; this table is the source of truth when signed in.
--
-- Deletion is a soft flag (`deleted`) rather than a row removal so multi-device
-- sync never resurrects a locally-removed entry (mirrors the price_alerts
-- `enabled` pattern). Fetches filter `deleted = false`.

create table if not exists public.collector_wishlist_entries (
  user_id uuid not null references auth.users(id) on delete cascade,
  portfolio_item_id text not null,
  title text,
  category text,
  status text not null default 'owned',
  deleted boolean not null default false,
  raw_json jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, portfolio_item_id),
  constraint collector_wishlist_status_check
    check (status in ('owned', 'wanted', 'missing'))
);

create index if not exists collector_wishlist_entries_user_idx
  on public.collector_wishlist_entries (user_id)
  where deleted = false;

drop trigger if exists set_collector_wishlist_entries_updated_at
  on public.collector_wishlist_entries;
create trigger set_collector_wishlist_entries_updated_at
before update on public.collector_wishlist_entries
for each row execute function public.set_updated_at();

alter table public.collector_wishlist_entries enable row level security;

drop policy if exists "Users can read own wishlist" on public.collector_wishlist_entries;
create policy "Users can read own wishlist"
on public.collector_wishlist_entries for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert own wishlist" on public.collector_wishlist_entries;
create policy "Users can insert own wishlist"
on public.collector_wishlist_entries for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update own wishlist" on public.collector_wishlist_entries;
create policy "Users can update own wishlist"
on public.collector_wishlist_entries for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own wishlist" on public.collector_wishlist_entries;
create policy "Users can delete own wishlist"
on public.collector_wishlist_entries for delete
using (auth.uid() = user_id);
