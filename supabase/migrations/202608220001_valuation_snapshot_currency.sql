-- Records which currency each snapshot's value_aud/low_estimate_aud/
-- high_estimate_aud columns are actually denominated in. Those columns are
-- historically misnamed -- they hold whatever display currency was active
-- at write time (per portfolio_catalog_matching_service.py's
-- _display_currency_from_item), not necessarily AUD. Without this column
-- there was no reliable way to convert a historical snapshot to a
-- different display currency, since the currency it was written in was
-- never recorded.
--
-- Existing rows are backfilled to 'AUD': the app's default_display_currency
-- has always been AUD (app/core/config.py) and the build was AUD-only for
-- most of its history, so this is the correct value for the overwhelming
-- majority of pre-existing rows, not a guess made up for convenience.
alter table public.portfolio_valuation_snapshots
add column if not exists currency text;

update public.portfolio_valuation_snapshots
set currency = 'AUD'
where currency is null;

alter table public.portfolio_valuation_snapshots
alter column currency set default 'AUD';

alter table public.portfolio_valuation_snapshots
alter column currency set not null;
