-- CollectIQ AI Supabase readiness checks.
-- Read-only validation queries. No secrets belong in this file.

with expected_tables(table_name) as (
  values
    ('user_profiles'),
    ('portfolio_items')
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
    ('user_profiles'),
    ('portfolio_items')
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
    ('user_profiles', 'Users can read own profile'),
    ('user_profiles', 'Users can insert own profile'),
    ('user_profiles', 'Users can update own profile'),
    ('portfolio_items', 'Users can read own portfolio items'),
    ('portfolio_items', 'Users can insert own portfolio items'),
    ('portfolio_items', 'Users can update own portfolio items'),
    ('portfolio_items', 'Users can delete own portfolio items')
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
  'collectiq-portfolio-images' as object_name,
  exists (
    select 1
    from storage.buckets
    where id = 'collectiq-portfolio-images'
      and public = false
  ) as passed;

with expected_storage_policies(policy_name) as (
  values
    ('Users can read own portfolio images'),
    ('Users can upload own portfolio images'),
    ('Users can update own portfolio images'),
    ('Users can delete own portfolio images')
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
