# Non-Production Cloud Foundation

CollectIQ AI is local-first by default. This foundation prepares the app for future cloud integrations without enabling production services, committing credentials, or changing the current mock/local workflows.

## Environment Structure

The cloud environment layer lives in:

- `lib/core/config/app_environment.dart`
- `lib/core/config/environment_config.dart`
- `lib/core/config/feature_flags.dart`

Supported environments:

- `local` - default; local/mock services only
- `dev` - future developer cloud sandbox
- `staging` - future pre-production validation
- `prod` - future production environment

Set the environment with:

```powershell
flutter run --dart-define=COLLECTIQ_ENV=dev
```

If `COLLECTIQ_ENV` is missing or unknown, the app uses `local`.

## Feature Flags

All cloud flags default to `false`:

- `COLLECTIQ_USE_CLOUD_AUTH`
- `COLLECTIQ_USE_CLOUD_PORTFOLIO_SYNC`
- `COLLECTIQ_USE_CLOUD_IMAGE_STORAGE`
- `COLLECTIQ_USE_CRASH_REPORTING`
- `COLLECTIQ_USE_ANALYTICS`
- `COLLECTIQ_USE_REAL_AI_PROVIDER`

Example non-production opt-in:

```powershell
flutter run `
  --dart-define=COLLECTIQ_ENV=dev `
  --dart-define=COLLECTIQ_USE_CLOUD_AUTH=true
```

These flags do not contain credentials. They only control whether future adapters may be selected.

## Cloud Service Abstractions

Cloud-facing interfaces are defined under `lib/core/cloud/services/`:

- `AuthService`
- `CloudStorageService`
- `AnalyticsService`
- `CrashReportingService`
- `RemoteConfigService`

The app should depend on these contracts, not directly on Firebase, Supabase, or any other vendor SDK inside UI/controllers.

## No-Op Local Implementations

Local no-op implementations are provided:

- `NoOpAuthService`
- `NoOpCloudStorageService`
- `NoOpAnalyticsService`
- `NoOpCrashReportingService`
- `NoOpRemoteConfigService`

These allow the app to run with no cloud configuration. Local scan, portfolio, settings, navigation, mock AI, and local persistence continue working.

## Service Registry

`CloudServiceRegistry` in `lib/core/cloud/cloud_service_registry.dart` is the dependency switchboard.

Current behavior:

- `local` returns no-op services.
- Missing cloud config still returns no-op services.
- Production services are not enabled by default.

Future behavior:

- `dev` can resolve Firebase/Supabase sandbox adapters.
- `staging` can resolve pre-production adapters.
- `prod` can resolve production adapters only after explicit feature flags and credentials are configured.

## Where Credentials Go Later

Credentials must never be committed to the repo.

Future credentials should come from platform-safe environment/configuration mechanisms such as:

- Flutter `--dart-define` values for non-sensitive public IDs
- Native Firebase config files generated per environment
- Supabase public anon keys only when intentionally configured
- Backend-only secrets for AI/pricing/payment providers
- CI/CD secret storage for release builds

Production secrets, service role keys, OpenAI keys, eBay keys, TCGPlayer keys, PriceCharting keys, and payment secrets must stay server-side.

## Why Production Is Protected

The default environment is `local`, and every cloud feature flag defaults to `false`. A production build cannot accidentally use cloud services unless a future sprint explicitly wires a production adapter and the release process supplies the required configuration.

This sprint does not enable real cloud traffic. It creates the architecture required for safe non-production integration later.
