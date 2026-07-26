-- PackLox cloud push notification foundation.
-- Device registrations are used by backend jobs to send price alert pushes.

create table if not exists public.push_device_registrations (
  user_id uuid not null references auth.users(id) on delete cascade,
  device_token text not null,
  provider text not null default 'fcm',
  platform text not null,
  enabled boolean not null default true,
  last_seen_at timestamptz not null default now(),
  disabled_at timestamptz,
  raw_json jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, device_token),
  constraint push_device_provider_check check (provider in ('fcm', 'apns')),
  constraint push_device_platform_check
    check (platform in ('android', 'ios', 'web', 'macos', 'windows', 'linux', 'fuchsia'))
);

create index if not exists push_device_registrations_enabled_idx
on public.push_device_registrations(enabled, provider, platform, last_seen_at desc);

drop trigger if exists set_push_device_registrations_updated_at
on public.push_device_registrations;
create trigger set_push_device_registrations_updated_at
before update on public.push_device_registrations
for each row execute function public.set_updated_at();

alter table public.push_device_registrations enable row level security;

drop policy if exists "Users can read own push devices"
on public.push_device_registrations;
create policy "Users can read own push devices"
on public.push_device_registrations for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert own push devices"
on public.push_device_registrations;
create policy "Users can insert own push devices"
on public.push_device_registrations for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update own push devices"
on public.push_device_registrations;
create policy "Users can update own push devices"
on public.push_device_registrations for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own push devices"
on public.push_device_registrations;
create policy "Users can delete own push devices"
on public.push_device_registrations for delete
using (auth.uid() = user_id);

create table if not exists public.push_notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  price_alert_id text,
  portfolio_item_id text,
  provider text not null default 'fcm',
  platform text,
  title text not null,
  body text not null,
  status text not null default 'queued',
  provider_message_id text,
  error_message text,
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  raw_json jsonb not null default '{}',
  constraint push_delivery_status_check
    check (status in ('queued', 'sent', 'failed', 'skipped'))
);

create index if not exists push_notification_deliveries_user_created_idx
on public.push_notification_deliveries(user_id, created_at desc);

create index if not exists push_notification_deliveries_backend_idx
on public.push_notification_deliveries(status, created_at desc);

alter table public.push_notification_deliveries enable row level security;

drop policy if exists "Users can read own push deliveries"
on public.push_notification_deliveries;
create policy "Users can read own push deliveries"
on public.push_notification_deliveries for select
using (auth.uid() = user_id);
