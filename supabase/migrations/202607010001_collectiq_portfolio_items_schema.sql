-- CollectIQ SIT Supabase schema.
-- Chosen architecture:
-- - metadata table: public.portfolio_items
-- - image bucket: collectiq-portfolio-images
-- - image object path: users/{userId}/portfolio_images/{itemId}.jpg
--
-- No secrets belong in this file.

create extension if not exists "pgcrypto";

create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.portfolio_items (
  id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null,
  title text not null,
  manufacturer text,
  series text,
  year integer,
  country text,
  estimated_value_low numeric(12, 2),
  estimated_value_high numeric(12, 2),
  image_local_path text,
  image_storage_path text,
  cloud_image_url text,
  sync_status text not null default 'synced',
  last_synced_at timestamptz,
  raw_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id, user_id),
  constraint portfolio_items_sync_status_check
    check (sync_status in (
      'localOnly',
      'pendingUpload',
      'synced',
      'failed',
      'deleted'
    ))
);

create index if not exists portfolio_items_user_created_idx
on public.portfolio_items(user_id, created_at desc);

create index if not exists portfolio_items_user_status_idx
on public.portfolio_items(user_id, sync_status);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_user_profiles_updated_at on public.user_profiles;
create trigger set_user_profiles_updated_at
before update on public.user_profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_portfolio_items_updated_at on public.portfolio_items;
create trigger set_portfolio_items_updated_at
before update on public.portfolio_items
for each row execute function public.set_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.user_profiles (id, email, display_name, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'name'),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do update
  set
    email = excluded.email,
    display_name = coalesce(excluded.display_name, public.user_profiles.display_name),
    avatar_url = coalesce(excluded.avatar_url, public.user_profiles.avatar_url),
    updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

alter table public.user_profiles enable row level security;
alter table public.portfolio_items enable row level security;

drop policy if exists "Users can read own profile"
on public.user_profiles;
create policy "Users can read own profile"
on public.user_profiles for select
using (auth.uid() = id);

drop policy if exists "Users can insert own profile"
on public.user_profiles;
create policy "Users can insert own profile"
on public.user_profiles for insert
with check (auth.uid() = id);

drop policy if exists "Users can update own profile"
on public.user_profiles;
create policy "Users can update own profile"
on public.user_profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "Users can read own portfolio items"
on public.portfolio_items;
create policy "Users can read own portfolio items"
on public.portfolio_items for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert own portfolio items"
on public.portfolio_items;
create policy "Users can insert own portfolio items"
on public.portfolio_items for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update own portfolio items"
on public.portfolio_items;
create policy "Users can update own portfolio items"
on public.portfolio_items for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own portfolio items"
on public.portfolio_items;
create policy "Users can delete own portfolio items"
on public.portfolio_items for delete
using (auth.uid() = user_id);

insert into storage.buckets (id, name, public)
values ('collectiq-portfolio-images', 'collectiq-portfolio-images', false)
on conflict (id) do update set public = false;

drop policy if exists "Users can read own portfolio images"
on storage.objects;
create policy "Users can read own portfolio images"
on storage.objects for select
to authenticated
using (
  bucket_id = 'collectiq-portfolio-images'
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = auth.uid()::text
);

drop policy if exists "Users can upload own portfolio images"
on storage.objects;
create policy "Users can upload own portfolio images"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'collectiq-portfolio-images'
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = auth.uid()::text
);

drop policy if exists "Users can update own portfolio images"
on storage.objects;
create policy "Users can update own portfolio images"
on storage.objects for update
to authenticated
using (
  bucket_id = 'collectiq-portfolio-images'
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = auth.uid()::text
)
with check (
  bucket_id = 'collectiq-portfolio-images'
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = auth.uid()::text
);

drop policy if exists "Users can delete own portfolio images"
on storage.objects;
create policy "Users can delete own portfolio images"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'collectiq-portfolio-images'
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = auth.uid()::text
);
