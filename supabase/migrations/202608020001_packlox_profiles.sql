-- PackLox cloud-backed collector profile (display name + avatar), linked to the
-- authenticated user so it follows the account across devices/reinstalls.
-- On-device SharedPreferences remains the offline cache; this is the source of
-- truth when signed in. Avatar binaries live in the existing
-- `collectiq-portfolio-images` storage bucket at users/<uid>/profile/avatar.jpg.

create table if not exists public.collector_profiles (
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text,
  avatar_path text,
  country_code text,
  preferred_currency text,
  raw_json jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id)
);

drop trigger if exists set_collector_profiles_updated_at on public.collector_profiles;
create trigger set_collector_profiles_updated_at
before update on public.collector_profiles
for each row execute function public.set_updated_at();

alter table public.collector_profiles enable row level security;

drop policy if exists "Users can read own profile" on public.collector_profiles;
create policy "Users can read own profile"
on public.collector_profiles for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert own profile" on public.collector_profiles;
create policy "Users can insert own profile"
on public.collector_profiles for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update own profile" on public.collector_profiles;
create policy "Users can update own profile"
on public.collector_profiles for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own profile" on public.collector_profiles;
create policy "Users can delete own profile"
on public.collector_profiles for delete
using (auth.uid() = user_id);
