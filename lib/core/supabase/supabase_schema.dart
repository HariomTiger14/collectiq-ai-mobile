class SupabaseTables {
  const SupabaseTables._();

  static const users = 'users';
  static const collections = 'collections';
  static const collectibles = 'collectibles';
  static const scanHistory = 'scan_history';
  static const pricingSnapshots = 'pricing_snapshots';
  static const favorites = 'favorites';
  static const wishlist = 'wishlist';
}

class SupabaseStorageBuckets {
  const SupabaseStorageBuckets._();

  static const collectibleImages = 'collectible-images';
}

class SupabaseSchemaDefinition {
  const SupabaseSchemaDefinition._();

  static const tables = {
    SupabaseTables.users: '''
create table users (
  id uuid primary key,
  email text,
  display_name text,
  created_at timestamptz not null default now()
);
''',
    SupabaseTables.collections: '''
create table collections (
  id uuid primary key,
  user_id uuid references users(id),
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
''',
    SupabaseTables.collectibles: '''
create table collectibles (
  id uuid primary key,
  user_id uuid references users(id),
  collection_id uuid references collections(id),
  title text not null,
  category text not null,
  condition text,
  image_path text,
  image_storage_path text,
  estimated_value numeric,
  confidence numeric,
  metadata jsonb,
  ai_review jsonb,
  pricing jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
''',
    SupabaseTables.scanHistory: '''
create table scan_history (
  id uuid primary key,
  user_id uuid references users(id),
  collectible_id uuid references collectibles(id),
  image_storage_path text,
  recognition_result jsonb,
  created_at timestamptz not null default now()
);
''',
    SupabaseTables.pricingSnapshots: '''
create table pricing_snapshots (
  id uuid primary key,
  collectible_id uuid references collectibles(id),
  estimated_market_value numeric,
  low_estimate numeric,
  high_estimate numeric,
  currency text not null,
  pricing_source text,
  pricing_confidence numeric,
  created_at timestamptz not null default now()
);
''',
    SupabaseTables.favorites: '''
create table favorites (
  id uuid primary key,
  user_id uuid references users(id),
  collectible_id uuid references collectibles(id),
  created_at timestamptz not null default now()
);
''',
    SupabaseTables.wishlist: '''
create table wishlist (
  id uuid primary key,
  user_id uuid references users(id),
  title text not null,
  category text,
  target_price numeric,
  notes text,
  created_at timestamptz not null default now()
);
''',
  };
}
