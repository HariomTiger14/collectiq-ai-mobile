# PackLox SIT Cloud Foundation Audit

Baseline: `ec7ba66` (`fix: stabilize Android release shell tab switching`)

Scope: cloud/auth/storage/sync foundation only. No UI redesign, Analyzer API,
pricing APIs, marketplace, or subscriptions.

## Current Architecture

The app is local-first and uses `SharedPreferencesPortfolioRepository` as the
canonical local cache for portfolio metadata. Portfolio create/update/delete
flows write locally first, then `CloudPortfolioSyncCoordinator` attempts cloud
upload and metadata sync when non-local cloud flags are enabled.

Supabase is the intended cloud provider:

- Auth gateway: `lib/core/supabase/supabase_service.dart`
- Auth repository: `lib/features/auth/data/repositories/supabase_auth_repository.dart`
- Deep links: `lib/features/auth/services/auth_deep_link_service.dart`
- Storage adapter: `lib/core/cloud/supabase/supabase_cloud_storage_service.dart`
- Metadata sync adapter:
  `lib/core/cloud/supabase/supabase_cloud_portfolio_sync_service.dart`
- Bucket/path contract: `collectiq-portfolio-images` and
  `users/{userId}/portfolio_images/{itemId}.{ext}`
- Schema/RLS/storage policies:
  `supabase/migrations/202607010001_collectiq_portfolio_items_schema.sql`

The app also contains duplicate Firebase cloud implementations that can confuse
the production architecture:

- Firebase auth
- Firebase storage
- Firebase portfolio sync / Firestore
- Firebase remote config
- Firebase analytics/crash implementations

There is also an older image-storage repository abstraction that currently only
returns local paths. The real upload path is the queue/coordinator path, not
`ImageStorageRepository`.

## Recommended Architecture

Use one production cloud architecture:

```text
Flutter UI
  |
  v
Riverpod controllers
  |
  +--> AuthRepository
  |      |
  |      v
  |    SupabaseService / Supabase Auth
  |
  +--> SharedPreferencesPortfolioRepository
  |      |
  |      v
  |    CloudPortfolioSyncCoordinator
  |      |
  |      +--> SupabaseCloudStorageService
  |      |      bucket: collectiq-portfolio-images
  |      |
  |      +--> SupabaseCloudPortfolioSyncService
  |             table: public.portfolio_items
  |
  +--> No-op analytics/crash/reporting placeholders
```

Supabase remains the only auth, cloud storage, and portfolio sync provider.
Analytics and crash reporting remain placeholders until a future observability
sprint explicitly selects and configures a provider.

## Files To Remove

- `lib/core/cloud/firebase/firebase_auth_service.dart`
- `lib/core/cloud/firebase/firebase_cloud_storage_service.dart`
- `lib/core/cloud/firebase/firebase_cloud_portfolio_sync_service.dart`
- `lib/core/cloud/firebase/firebase_remote_config_service.dart`
- `lib/core/cloud/firebase/firebase_analytics_service.dart`
- `lib/core/cloud/firebase/firebase_crash_reporting_service.dart`
- `lib/core/cloud/firebase/firebase_bootstrap.dart`

Dependency cleanup:

- `firebase_core`
- `firebase_auth`
- `firebase_storage`
- `cloud_firestore`
- `firebase_remote_config`
- `firebase_analytics`
- `firebase_crashlytics`

## Files To Keep

- `lib/core/supabase/supabase_config.dart`
- `lib/core/supabase/supabase_service.dart`
- `lib/core/supabase/supabase_auth_response_normalizer.dart`
- `lib/core/cloud/supabase/supabase_bootstrap.dart`
- `lib/core/cloud/supabase/supabase_auth_service.dart`
- `lib/core/cloud/supabase/supabase_cloud_storage_service.dart`
- `lib/core/cloud/supabase/supabase_cloud_portfolio_sync_service.dart`
- `lib/core/cloud/cloud_service_registry.dart`
- `lib/core/cloud/cloud_portfolio_sync_coordinator.dart`
- `lib/core/cloud/cloud_storage_paths.dart`
- `lib/features/portfolio/data/repositories/shared_preferences_portfolio_repository.dart`
- `lib/features/image_sync/**`
- `supabase/migrations/202607010001_collectiq_portfolio_items_schema.sql`
- `supabase/setup/production_readiness_checks.sql`

## Migration Impact

Expected low UI impact: controllers and screens already depend on provider
interfaces and local repositories. The cleanup removes obsolete provider
implementations and prevents accidental Firebase selection.

Expected test impact: tests asserting Firebase analytics/crash selection should
be updated to assert no-op placeholders. Supabase foundation tests should remain
focused on registry selection, session handling, storage paths, metadata row
mapping, and RLS-compatible user-scoped paths.

Known limitation for this Codex session: live Supabase SIT and Android device
end-to-end flows require real `SUPABASE_URL`, `SUPABASE_ANON_KEY`, email access,
camera/gallery permissions, and network/device control. Automated local tests
can verify the app foundation and contracts, but cannot prove live email
delivery or bucket policy behavior without those credentials and a device.
