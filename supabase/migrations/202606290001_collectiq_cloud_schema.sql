-- CollectIQ AI cloud schema foundation.
-- Run this in the Supabase SQL editor or through the Supabase CLI.
-- No secrets belong in this file.

create extension if not exists "pgcrypto";

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.collections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.collectibles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  collection_id uuid references public.collections(id) on delete set null,
  title text not null,
  category text not null,
  condition text,
  image_path text,
  image_storage_path text,
  estimated_value numeric(12, 2),
  confidence numeric(5, 2),
  metadata jsonb not null default '{}'::jsonb,
  ai_review jsonb not null default '{}'::jsonb,
  pricing jsonb not null default '{}'::jsonb,
  saved_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.scan_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  collectible_id uuid references public.collectibles(id) on delete set null,
  image_storage_path text,
  recognition_result jsonb not null default '{}'::jsonb,
  ai_provider text,
  processing_time_ms integer,
  created_at timestamptz not null default now()
);

create table if not exists public.pricing_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  collectible_id uuid not null references public.collectibles(id) on delete cascade,
  estimated_market_value numeric(12, 2),
  low_estimate numeric(12, 2),
  high_estimate numeric(12, 2),
  currency text not null default 'AUD',
  pricing_source text,
  pricing_confidence numeric(5, 2),
  last_updated timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  collectible_id uuid not null references public.collectibles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, collectible_id)
);

create table if not exists public.wishlist (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  category text,
  target_price numeric(12, 2),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists collections_user_id_idx on public.collections(user_id);
create index if not exists collectibles_user_id_idx on public.collectibles(user_id);
create index if not exists collectibles_collection_id_idx on public.collectibles(collection_id);
create index if not exists scan_history_user_id_idx on public.scan_history(user_id);
create index if not exists pricing_snapshots_user_id_idx on public.pricing_snapshots(user_id);
create index if not exists pricing_snapshots_collectible_id_idx on public.pricing_snapshots(collectible_id);
create index if not exists favorites_user_id_idx on public.favorites(user_id);
create index if not exists wishlist_user_id_idx on public.wishlist(user_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_users_updated_at on public.users;
create trigger set_users_updated_at
before update on public.users
for each row execute function public.set_updated_at();

drop trigger if exists set_collections_updated_at on public.collections;
create trigger set_collections_updated_at
before update on public.collections
for each row execute function public.set_updated_at();

drop trigger if exists set_collectibles_updated_at on public.collectibles;
create trigger set_collectibles_updated_at
before update on public.collectibles
for each row execute function public.set_updated_at();

drop trigger if exists set_wishlist_updated_at on public.wishlist;
create trigger set_wishlist_updated_at
before update on public.wishlist
for each row execute function public.set_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.users (id, email, display_name, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'name'),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do update
  set
    email = excluded.email,
    display_name = coalesce(excluded.display_name, public.users.display_name),
    avatar_url = coalesce(excluded.avatar_url, public.users.avatar_url),
    updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

alter table public.users enable row level security;
alter table public.collections enable row level security;
alter table public.collectibles enable row level security;
alter table public.scan_history enable row level security;
alter table public.pricing_snapshots enable row level security;
alter table public.favorites enable row level security;
alter table public.wishlist enable row level security;

create policy "Users can read own profile"
on public.users for select
using (auth.uid() = id);

create policy "Users can insert own profile"
on public.users for insert
with check (auth.uid() = id);

create policy "Users can update own profile"
on public.users for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "Users can delete own profile"
on public.users for delete
using (auth.uid() = id);

create policy "Users can read own collections"
on public.collections for select
using (auth.uid() = user_id);

create policy "Users can insert own collections"
on public.collections for insert
with check (auth.uid() = user_id);

create policy "Users can update own collections"
on public.collections for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own collections"
on public.collections for delete
using (auth.uid() = user_id);

create policy "Users can read own collectibles"
on public.collectibles for select
using (auth.uid() = user_id);

create policy "Users can insert own collectibles"
on public.collectibles for insert
with check (auth.uid() = user_id);

create policy "Users can update own collectibles"
on public.collectibles for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own collectibles"
on public.collectibles for delete
using (auth.uid() = user_id);

create policy "Users can read own scan history"
on public.scan_history for select
using (auth.uid() = user_id);

create policy "Users can insert own scan history"
on public.scan_history for insert
with check (auth.uid() = user_id);

create policy "Users can update own scan history"
on public.scan_history for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own scan history"
on public.scan_history for delete
using (auth.uid() = user_id);

create policy "Users can read own pricing snapshots"
on public.pricing_snapshots for select
using (auth.uid() = user_id);

create policy "Users can insert own pricing snapshots"
on public.pricing_snapshots for insert
with check (
  auth.uid() = user_id
  and exists (
    select 1
    from public.collectibles
    where collectibles.id = pricing_snapshots.collectible_id
      and collectibles.user_id = auth.uid()
  )
);

create policy "Users can update own pricing snapshots"
on public.pricing_snapshots for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own pricing snapshots"
on public.pricing_snapshots for delete
using (auth.uid() = user_id);

create policy "Users can read own favorites"
on public.favorites for select
using (auth.uid() = user_id);

create policy "Users can insert own favorites"
on public.favorites for insert
with check (
  auth.uid() = user_id
  and exists (
    select 1
    from public.collectibles
    where collectibles.id = favorites.collectible_id
      and collectibles.user_id = auth.uid()
  )
);

create policy "Users can delete own favorites"
on public.favorites for delete
using (auth.uid() = user_id);

create policy "Users can read own wishlist"
on public.wishlist for select
using (auth.uid() = user_id);

create policy "Users can insert own wishlist"
on public.wishlist for insert
with check (auth.uid() = user_id);

create policy "Users can update own wishlist"
on public.wishlist for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own wishlist"
on public.wishlist for delete
using (auth.uid() = user_id);
