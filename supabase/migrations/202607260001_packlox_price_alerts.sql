-- PackLox cloud-backed price alert rules.
-- These rules are user-owned and are the backend-ready source for future push
-- notification jobs. Device-local notifications remain a fallback.

create table if not exists public.price_alerts (
  id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  portfolio_item_id text not null,
  item_title text not null,
  rule_type text not null,
  target_amount numeric(12, 2),
  percentage numeric(8, 6),
  baseline_value numeric(12, 2),
  stale_after_days integer,
  status text not null default 'active',
  enabled boolean not null default true,
  triggered_at timestamptz,
  message text,
  raw_json jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id, user_id),
  constraint price_alerts_rule_type_check
    check (rule_type in (
      'priceRisesAboveAmount',
      'priceDropsBelowAmount',
      'percentageIncrease',
      'percentageDecrease',
      'stalePricingReminder'
    )),
  constraint price_alerts_status_check
    check (status in ('active', 'triggered', 'paused'))
);

create index if not exists price_alerts_user_created_idx
on public.price_alerts(user_id, created_at desc);

create index if not exists price_alerts_user_item_idx
on public.price_alerts(user_id, portfolio_item_id);

create index if not exists price_alerts_backend_scan_idx
on public.price_alerts(enabled, status, rule_type, updated_at);

drop trigger if exists set_price_alerts_updated_at on public.price_alerts;
create trigger set_price_alerts_updated_at
before update on public.price_alerts
for each row execute function public.set_updated_at();

alter table public.price_alerts enable row level security;

drop policy if exists "Users can read own price alerts"
on public.price_alerts;
create policy "Users can read own price alerts"
on public.price_alerts for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert own price alerts"
on public.price_alerts;
create policy "Users can insert own price alerts"
on public.price_alerts for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update own price alerts"
on public.price_alerts;
create policy "Users can update own price alerts"
on public.price_alerts for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own price alerts"
on public.price_alerts;
create policy "Users can delete own price alerts"
on public.price_alerts for delete
using (auth.uid() = user_id);
