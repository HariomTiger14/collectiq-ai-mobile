-- PackLox valuation storage and shared pricing cache.
--
-- Goals:
-- - portfolio_valuation_snapshots: immutable user-owned ledger entries
-- - pricing_cache_entries: shared cache for repeated scans of the same item
-- - no provider raw payload redistribution; store only normalized evidence

create table if not exists public.portfolio_valuation_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  portfolio_item_id text not null,
  value_aud numeric(12, 2),
  low_estimate_aud numeric(12, 2),
  high_estimate_aud numeric(12, 2),
  display_string text,
  valuation_status text not null,
  reason_code text,
  valuation_strategy text,
  pricing_provider text,
  attribution_text text,
  confidence_score numeric(5, 4),
  original_price numeric(12, 2),
  original_currency text,
  exchange_rate_used numeric(14, 8),
  exchange_rate_date timestamptz,
  match_reason text,
  condition_label text,
  priced_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  evidence_json jsonb not null default '{}'::jsonb,
  foreign key (portfolio_item_id, user_id)
    references public.portfolio_items(id, user_id)
    on delete cascade,
  constraint portfolio_valuation_status_check
    check (valuation_status in (
      'market_estimated',
      'provider_not_configured',
      'no_market_match',
      'lookup_failed',
      'unavailable',
      'ai_estimated'
    ))
);

create index if not exists portfolio_valuation_snapshots_item_priced_idx
on public.portfolio_valuation_snapshots(user_id, portfolio_item_id, priced_at desc);

create table if not exists public.pricing_cache_entries (
  cache_key text primary key,
  category text not null,
  normalized_identity text not null,
  condition_label text,
  valuation_status text not null,
  value_aud numeric(12, 2),
  low_estimate_aud numeric(12, 2),
  high_estimate_aud numeric(12, 2),
  display_string text,
  valuation_strategy text,
  pricing_provider text,
  attribution_text text,
  confidence_score numeric(5, 4),
  reason_code text,
  match_reason text,
  original_price numeric(12, 2),
  original_currency text,
  exchange_rate_used numeric(14, 8),
  exchange_rate_date timestamptz,
  checked_at timestamptz not null default now(),
  expires_at timestamptz not null,
  hit_count integer not null default 0,
  evidence_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pricing_cache_status_check
    check (valuation_status in (
      'market_estimated',
      'provider_not_configured',
      'no_market_match',
      'lookup_failed',
      'unavailable',
      'ai_estimated'
    ))
);

create index if not exists pricing_cache_entries_lookup_idx
on public.pricing_cache_entries(category, normalized_identity, condition_label);

create index if not exists pricing_cache_entries_expires_idx
on public.pricing_cache_entries(expires_at);

create or replace function public.increment_pricing_cache_hit(cache_key_arg text)
returns void
language sql
security definer set search_path = public
as $$
  update public.pricing_cache_entries
  set hit_count = hit_count + 1
  where cache_key = cache_key_arg;
$$;

drop trigger if exists set_pricing_cache_entries_updated_at
on public.pricing_cache_entries;
create trigger set_pricing_cache_entries_updated_at
before update on public.pricing_cache_entries
for each row execute function public.set_updated_at();

alter table public.portfolio_valuation_snapshots enable row level security;
alter table public.pricing_cache_entries enable row level security;

drop policy if exists "Users can read own valuation snapshots"
on public.portfolio_valuation_snapshots;
create policy "Users can read own valuation snapshots"
on public.portfolio_valuation_snapshots for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert own valuation snapshots"
on public.portfolio_valuation_snapshots;
create policy "Users can insert own valuation snapshots"
on public.portfolio_valuation_snapshots for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can read pricing cache entries"
on public.pricing_cache_entries;
create policy "Users can read pricing cache entries"
on public.pricing_cache_entries for select
to authenticated
using (true);

drop policy if exists "Service role can manage pricing cache entries"
on public.pricing_cache_entries;
create policy "Service role can manage pricing cache entries"
on public.pricing_cache_entries for all
using (auth.role() = 'service_role')
with check (auth.role() = 'service_role');
