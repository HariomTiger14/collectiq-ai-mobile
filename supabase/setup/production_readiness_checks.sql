-- CollectIQ AI Supabase production readiness checks.
-- Read-only validation queries. No secrets belong in this file.

with expected_tables(table_name) as (
  values
    ('users'),
    ('collections'),
    ('collectibles'),
    ('scan_history'),
    ('pricing_snapshots'),
    ('favorites'),
    ('wishlist')
)
select
  'table_exists' as check_type,
  expected_tables.table_name,
  (information_schema.tables.table_name is not null) as passed
from expected_tables
left join information_schema.tables
  on information_schema.tables.table_schema = 'public'
 and information_schema.tables.table_name = expected_tables.table_name
order by expected_tables.table_name;

with expected_tables(table_name) as (
  values
    ('users'),
    ('collections'),
    ('collectibles'),
    ('scan_history'),
    ('pricing_snapshots'),
    ('favorites'),
    ('wishlist')
)
select
  'rls_enabled' as check_type,
  expected_tables.table_name,
  coalesce(pg_class.relrowsecurity, false) as passed
from expected_tables
left join pg_class
  on pg_class.relname = expected_tables.table_name
left join pg_namespace
  on pg_namespace.oid = pg_class.relnamespace
 and pg_namespace.nspname = 'public'
order by expected_tables.table_name;

with expected_policies(table_name, policy_name) as (
  values
    ('users', 'Users can read own profile'),
    ('users', 'Users can insert own profile'),
    ('users', 'Users can update own profile'),
    ('users', 'Users can delete own profile'),
    ('collections', 'Users can read own collections'),
    ('collections', 'Users can insert own collections'),
    ('collections', 'Users can update own collections'),
    ('collections', 'Users can delete own collections'),
    ('collectibles', 'Users can read own collectibles'),
    ('collectibles', 'Users can insert own collectibles'),
    ('collectibles', 'Users can update own collectibles'),
    ('collectibles', 'Users can delete own collectibles'),
    ('scan_history', 'Users can read own scan history'),
    ('scan_history', 'Users can insert own scan history'),
    ('scan_history', 'Users can update own scan history'),
    ('scan_history', 'Users can delete own scan history'),
    ('pricing_snapshots', 'Users can read own pricing snapshots'),
    ('pricing_snapshots', 'Users can insert own pricing snapshots'),
    ('pricing_snapshots', 'Users can update own pricing snapshots'),
    ('pricing_snapshots', 'Users can delete own pricing snapshots'),
    ('favorites', 'Users can read own favorites'),
    ('favorites', 'Users can insert own favorites'),
    ('favorites', 'Users can delete own favorites'),
    ('wishlist', 'Users can read own wishlist'),
    ('wishlist', 'Users can insert own wishlist'),
    ('wishlist', 'Users can update own wishlist'),
    ('wishlist', 'Users can delete own wishlist')
)
select
  'rls_policy_exists' as check_type,
  expected_policies.table_name || ':' || expected_policies.policy_name as object_name,
  (pg_policies.policyname is not null) as passed
from expected_policies
left join pg_policies
  on pg_policies.schemaname = 'public'
 and pg_policies.tablename = expected_policies.table_name
 and pg_policies.policyname = expected_policies.policy_name
order by object_name;

select
  'storage_bucket_exists' as check_type,
  'collectible-images' as object_name,
  exists (
    select 1
    from storage.buckets
    where id = 'collectible-images'
      and public = false
  ) as passed;

with expected_storage_policies(policy_name) as (
  values
    ('Users can read own collectible images'),
    ('Users can upload own collectible images'),
    ('Users can update own collectible images'),
    ('Users can delete own collectible images')
)
select
  'storage_policy_exists' as check_type,
  expected_storage_policies.policy_name as object_name,
  (pg_policies.policyname is not null) as passed
from expected_storage_policies
left join pg_policies
  on pg_policies.schemaname = 'storage'
 and pg_policies.tablename = 'objects'
 and pg_policies.policyname = expected_storage_policies.policy_name
order by object_name;
