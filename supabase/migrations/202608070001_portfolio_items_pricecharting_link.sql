-- Links a portfolio item to its matched pricecharting_catalog row (which
-- lives in the backend repo's migration history, same live database) so
-- repricing can read a price directly instead of always calling a live
-- pricing-provider API. Nullable/additive: unmatched items are unaffected
-- and keep today's live-API repricing behavior.

alter table public.portfolio_items
    add column if not exists pricecharting_id text
        references public.pricecharting_catalog (pricecharting_id)
        on delete set null,
    add column if not exists pricecharting_match_score integer,
    add column if not exists pricecharting_matched_at timestamptz,
    add column if not exists pricecharting_match_attempted_at timestamptz;

create index if not exists portfolio_items_pricecharting_id_idx
    on public.portfolio_items (pricecharting_id)
    where pricecharting_id is not null;

-- Drives the matching job's queue: unattempted items first, then oldest
-- attempt first, so a never-matched item isn't retried every single cycle.
create index if not exists portfolio_items_match_queue_idx
    on public.portfolio_items (pricecharting_match_attempted_at nulls first)
    where pricecharting_id is null;
