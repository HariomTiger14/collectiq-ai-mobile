# CollectIQ AI Current Project Status

Audit date: 2026-07-01

Scope: repository code, tests, docs, config, validation assets, and verification commands. No chat history or assumed roadmap state was used.

## A. Executive Summary

CollectIQ AI is a Flutter local-first collectible scanning and portfolio app with a supporting FastAPI backend. The app currently provides onboarding, bottom-tab navigation, Home, Scan, Portfolio, Detail, and Settings surfaces. Users can select or capture images, run analysis, save results to a local portfolio, browse/search/filter/sort saved collectibles, view details, see dashboard analytics, manage local price-alert settings, and inspect cloud/AI diagnostics.

The project is in an advanced MVP / pre-beta foundation stage. The UI and local persistence paths are substantial, and there are broad widget/domain tests. However, several production capabilities remain opt-in foundations, mock-only, or unverified on real devices.

The app is local-first by default. Cloud service flags default to off, Supabase and Firebase are skipped in local mode, and production cloud wiring is explicitly disabled in the newer cloud registry. Supabase and Firebase code exists for non-production/dev-staging experiments, but the default runnable behavior is not production cloud-connected.

Important code finding: Flutter's `AI_ANALYSIS_PROVIDER=mock` path returns a built-in sample result for `sample://` scans, but for normal camera/gallery image paths it calls `BackendAIRecognitionService`, which posts to the local FastAPI `/scanner/analyze` endpoint through `ApiClient`. The separate `openai_vision` Flutter provider path calls only a configured backend endpoint and is disabled unless explicitly selected.

## B. Feature Status Table

| Feature | Status | Current evidence |
| --- | --- | --- |
| App navigation | Complete | `AppShell` has Home, Scan, Portfolio, Settings tabs, state restoration, onboarding gate. |
| Home screen | Partially implemented | Dashboard, metrics, recent activity, insights, wishlist/alert summaries are present; values are based on local portfolio/mock analytics. |
| Scan from camera | Partially implemented | Native picker flow, permission request, persistent copy, lost-data recovery, tests. Needs physical-device SIT. |
| Scan from gallery | Partially implemented | Native picker flow, validation, persistent copy, tests. Needs physical-device SIT. |
| AI analysis | Partially implemented | FastAPI mock/OpenAI backend exists; Flutter backend endpoint client exists. Real production AI is opt-in and not enabled by default. |
| Mock AI response | Complete | Sample `sample://sports-card` result and backend mock recognition/pricing are implemented. |
| Portfolio save | Complete | Saves `CollectibleItem` to SharedPreferences and refreshes UI. |
| Portfolio list | Complete | Local list, summary, grid, empty/error states. |
| Portfolio detail | Complete | Detail page and sync status labels/actions are implemented and tested. |
| Image persistence after restart | Partially implemented | Camera/gallery files are copied to app documents and paths are saved locally; covered by local tests, still needs real device force-stop/restart validation. |
| Local storage | Complete | SharedPreferences repositories for portfolio, onboarding, usage, entitlements, price alerts, wishlist, history, image sync queue. |
| Cloud auth | Partially implemented | Supabase anonymous/email auth code exists and Settings UI exposes email auth; disabled unless configured. Google/Apple are placeholders. |
| Cloud image storage | Partially implemented | Supabase storage upload implementations exist; default fallback/local mode does not upload. |
| Cloud portfolio sync | Partially implemented | Supabase sync repositories/coordinator and manual sync UI exist; disabled by default and requires config/auth. |
| Supabase integration | Partially implemented | Two Supabase paths exist: `core/cloud/supabase` registry services and older `core/supabase` Dio gateway. Requires dart defines and migrations. |
| Firebase integration | Foundation only | Dependencies and wrappers for analytics/crash reporting exist. Default is no-op; native config not present in repo. |
| Analytics | Foundation only | Telemetry abstraction and Firebase/no-op implementations exist; disabled by default. |
| Crash reporting | Foundation only | Flutter error hooks and Firebase/no-op crash services exist; disabled by default. |
| Remote config | Foundation only | Service interface and no-op implementation exist; no real Firebase Remote Config service is selected in registry. |
| Settings screen | Partially implemented | Rich diagnostics, auth, sync, plan, notifications, AI status. Many controls are placeholders or config-gated. |
| Manual sync | Partially implemented | Manual sync path exists in Settings for dev/staging cloud flags; default local mode cannot run cloud sync. |
| Sync status display | Partially implemented | Settings and detail labels exist; true cloud status needs configured Supabase verification. |
| Dataset/validation lab | Partially implemented | Backend scripts, manifests, local sample images, reports, docs, and tests exist. |
| Global collectibles dataset | Not started | No committed production-grade reference database; only local sample/placeholder validation data and source docs. |
| Search | Partially implemented | Portfolio local search/filter exists. Global collectible/reference search is not implemented. |
| Trending collectibles | Mock/local only | Home/dashboard trend-style analytics and mock pricing trends exist; no live trending dataset/service. |
| Subscription system | Partially implemented | Usage limits, entitlement repositories, Google Play billing repository, Settings UI. Billing disabled unless configured and not production-validated. |
| Marketplace | Foundation only | Pricing provider boundaries and backend provider integrations exist; no marketplace buying/selling UI. |
| Multi-language/currency/time zone | Not started | UI and pricing mostly assume English/AUD; no localization or currency/time-zone preference system. |
| Automated tests | Complete for local MVP | `flutter test` passes; broad unit/widget tests. Integration tests exist but are not run by `flutter test`. |
| Device/SIT testing | Broken/needs verification | Scripts/docs exist, but this audit did not run physical-device, native picker, Firebase, Supabase, or backend live-provider SIT. |

## C. Architecture Summary

The Flutter app is organized by `lib/core`, `lib/features`, and `lib/shared`.

Core contains navigation, theme/design system, network helpers, environment/feature flags, cloud service abstractions, Supabase/Firebase adapters, telemetry, and errors. Feature modules include AI, auth, cloud sync, diagnostics, home, image storage/sync, market, onboarding, portfolio, price alerts, scanner, settings, subscription, and wishlist. Shared domain models include `CollectibleItem`, pricing, and sorting.

State management uses Riverpod 3 providers and `Notifier` controllers. Major presentation state lives in controllers such as `ScannerController`, `PortfolioController`, `AuthController`, `SyncController`, `ImageSyncController`, `SubscriptionController`, and price-alert/wishlist providers.

Repositories and services are used heavily. Examples: `PortfolioRepository` with `SharedPreferencesPortfolioRepository`, auth repositories, cloud portfolio repositories, image storage repositories, AI analysis providers, market/pricing providers, and scanner camera/gallery services.

Environment handling has two tracks:

- New cloud environment config: `core/config/AppEnvironment`, `EnvironmentConfig`, and `FeatureFlags`; defaults to local and all cloud flags false.
- Older API config: `core/network/api_constants.dart` and `core/supabase/supabase_config.dart`; used by local FastAPI and Supabase HTTP gateway paths.

Feature flags are compile-time `--dart-define` booleans. Production cloud services are disabled in the newer `EnvironmentConfig.allowsProductionServices`, `SupabaseBootstrap`, and `FirebaseBootstrap` paths.

Cloud abstraction exists through `CloudServiceRegistry`, `AuthService`, `CloudStorageService`, `CloudPortfolioSyncService`, `AnalyticsService`, `CrashReportingService`, and `RemoteConfigService`. Defaults are no-op services unless dev/staging flags select Supabase/Firebase adapters.

The backend is a FastAPI app under `backend/` with routers for health, scanner analysis, API analysis, and portfolio. It uses provider factories for AI recognition and pricing. Backend defaults are `AI_PROVIDER=mock` and `PRICING_PROVIDER=mock`, with OpenAI/eBay/TCGPlayer/PriceCharting provider code guarded by environment configuration and mocked tests.

## D. Backend / Cloud Status

Active backend in code:

- Mobile scanner selected-image analysis currently posts to the local FastAPI scanner endpoint via `BackendAIRecognitionService` unless using the built-in `sample://` scan.
- FastAPI exposes `GET /health`, `POST /scanner/analyze`, `POST /api/analyze`, and portfolio endpoints.
- Backend default provider settings are mock AI and mock pricing.

Firebase status:

- Flutter dependencies and service wrappers exist for Firebase Core, Analytics, Auth, Remote Config, Storage, Firestore, and Crashlytics.
- The new cloud registry uses Firebase only for analytics and crash reporting when dev/staging flags are enabled.
- Firebase is skipped in local mode and disabled in production by `FirebaseBootstrap`.
- Auth/storage/portfolio sync are not selected from Firebase in the registry.

Supabase status:

- Supabase is the intended cloud auth/storage/portfolio sync direction in current code.
- Supabase migrations exist under `supabase/migrations`.
- Supabase is disabled unless configured with dart defines and/or dev/staging feature flags.
- The repo has both a newer `core/cloud/supabase` adapter set and an older `core/supabase` Dio gateway used by auth/sync/image storage paths.

No-op services:

- Default auth, cloud storage, portfolio sync, analytics, crash reporting, and remote config are no-op in local mode.
- `NoopAiBackendClient` and `NoopAiBackendApiService` are selected unless backend OpenAI Vision mode is configured.

Real implementations:

- Local FastAPI backend mock analysis/pricing is real runnable backend code.
- Supabase auth/storage/sync implementations are real but config-gated and not default.
- Firebase analytics/crash wrappers are real but config-gated.
- Backend OpenAI/pricing provider integrations are implemented but require server-side credentials and were not live-validated in this audit.

Production status:

- Production cloud service wiring is disabled in the newer cloud bootstrap code.
- Release backend endpoint safety blocks unsafe local HTTP endpoints for Flutter backend AI.
- Production credentials/config files required before cloud use include Supabase URL/anon key, Supabase SQL migrations/storage policies, optional Firebase native config or dart defines, backend `.env` provider keys, and Android signing variables for release distribution.

## E. Data Status

Mock responses are available in:

- Flutter sample mock scan result for `sample://sports-card`.
- Backend `MockRecognitionProvider`.
- Backend and Flutter mock pricing providers.
- Local dashboard/wishlist/alert analytics derived from saved local items.

Validation data exists under `validation/`:

- Local sample images are present under `validation/images/local_sample`.
- Manifests exist under `validation/manifests`.
- Latest validation report/result CSV files exist under `validation/reports`.
- Docs describe public/open dataset rules and validation lab workflow.

Dataset status:

- There is no committed production-grade global collectible reference database.
- The validation lab can prepare/import manifests and run against a backend endpoint, but dataset images are mostly local/sample and not a complete recognition corpus.
- Production-grade recognition still needs licensed/user-owned image datasets, category-specific ground truth, live-provider validation, accuracy metrics, model/prompt iteration, and ongoing regression baselines.

## F. Testing Status

Flutter/Dart tests:

- `flutter test` result: passed, `252` tests.
- Dart test declarations found in `test/` plus `integration_test/`: `256` total; integration tests are not part of the `flutter test` command run here.
- Dart test files in `test/`: `cloud_portfolio_sync_foundation_test.dart`, `cloud_sync_status_widget_test.dart`, `domain_unit_test.dart`, `non_prod_cloud_foundation_test.dart`, `price_alert_notifications_test.dart`, `telemetry_test.dart`, `widget_test.dart`.
- Integration test file: `integration_test/collectiq_app_flow_test.dart`.

Backend tests:

- Python backend test methods found: `89`.
- Backend test files: `test_api_endpoints.py`, `test_dataset_importer.py`, `test_ebay_pricing_provider.py`, `test_mock_pricing_provider.py`, `test_mock_recognition_service.py`, `test_openai_recognition_provider.py`, `test_pricecharting_pricing_provider.py`, `test_pricing_aggregation_service.py`, `test_pricing_intelligence_engine.py`, `test_tcgplayer_pricing_provider.py`, `test_validation_lab.py`, `test_validation_toolkit.py`.
- Backend tests were inspected but not run by the requested verification commands.

Coverage includes navigation, onboarding, scanner states, mock/sample analysis, portfolio save/list/delete/detail/search/sort/filter, local persistence, cloud foundation/no-op behavior, Supabase foundation, AI/backend contract validation, image sync queue, subscription foundations, analytics/telemetry, price alerts, wishlist, dashboard analytics, backend API/provider contracts, pricing providers, and validation lab helpers.

Not covered or not fully verified by this audit: real camera/gallery OS pickers, real Android permission flows, physical-device force-stop image persistence, live Supabase auth/storage/sync, Firebase Analytics/Crashlytics delivery, real OpenAI/eBay/TCGPlayer/PriceCharting calls, release builds, app bundle signing, Play Billing purchases, and production dataset accuracy.

Verification commands:

- `dart format --output=none --set-exit-if-changed lib test`: passed; `Formatted 186 files (0 changed)`.
- `flutter analyze`: passed; `No issues found!`.
- `flutter test`: passed; `252` tests.

## G. Known Risks / Issues

- Cloud direction is split across newer `core/cloud/*` registry services and older `core/supabase/*` gateway/repositories, which increases integration risk.
- Firebase and Supabase dependencies both exist; Firebase is telemetry-only in the newer registry, while Supabase is auth/storage/sync. This should be documented as the intentional split or simplified.
- Flutter mock analysis for real camera/gallery images depends on a local FastAPI backend in current code, while some docs describe mock mode as no-network. This mismatch can confuse tester setup.
- Image persistence relies on local file paths copied to app documents. It needs physical-device force-stop/restart and OS cleanup validation.
- Cloud image upload queue marks local-only fallback as failed/retryable when Supabase is not configured, so Settings may show attention-needed states in local-only usage.
- Manual cloud sync requires specific dev/staging flags and Supabase sign-in; default Settings sync is mostly status/placeholder.
- Supabase production is documented but not enabled by default and requires migrations, Auth settings, storage bucket/policies, and dart defines.
- Firebase analytics/crash reporting requires native config or dart defines and has not been verified in this audit.
- Google/Apple sign-in are placeholders.
- Billing has local entitlement and Google Play repository code but needs Play Console/internal testing and receipt strategy before beta reliance.
- Global collectible recognition accuracy is not proven without a real reference dataset and validation corpus.
- Device/SIT scripts exist, but this audit did not run native picker, build, or attached-device workflows.

## H. Recommended Next 10 Tasks

1. Resolve and document the intended AI default: either keep camera/gallery mock mode backend-dependent and update docs, or make mock mode fully local.
2. Run a physical Android smoke test for camera, gallery, analyze, save, app restart, and portfolio image display.
3. Run `integration_test/collectiq_app_flow_test.dart` on emulator/device and record results.
4. Run backend unit tests with `py -m unittest discover tests` from `backend/`.
5. Choose one Supabase integration path for auth/sync/image upload and reduce duplicate gateway/registry ambiguity.
6. Validate Supabase dev/staging end to end: email sign-up/sign-in, image upload, portfolio row upload, sign-out, and local data preservation.
7. Decide how local-only image sync queue should behave when cloud is not configured so local users do not see false failure states.
8. Build a small licensed/user-owned validation dataset with ground truth and run the validation lab against mock and real backend modes.
9. Verify Firebase analytics/crash reporting in a dev build with safe config and confirm no sensitive fields are emitted.
10. Run Android debug/release build and Play Billing internal-test setup only after local/device scan flows are stable.

## I. Definition Of Done Before Beta

- Camera and gallery scan flows pass on target physical Android devices.
- Saved local portfolio items and images survive app restart, force-stop, and normal OS lifecycle transitions.
- The AI default mode and required backend setup are documented and match code behavior.
- Local-only users can scan, analyze, save, search, sort, view detail, delete, and manage settings without cloud errors that look like failures.
- Supabase dev/staging auth, image storage, and portfolio sync are validated or explicitly excluded from beta.
- Firebase analytics/crash reporting is either validated with beta-safe config or left disabled with no-op behavior confirmed.
- Backend mock mode, OpenAI opt-in mode, and pricing fallback behavior are validated against known images.
- A validation dataset with clear licensing/ownership and expected outputs exists.
- `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`, backend tests, integration tests, and Android builds pass for the beta candidate.
- Privacy, permissions, data safety, known limitations, tester feedback, and support docs are final enough for testers.
- Billing/subscription UI is either hidden/disabled for beta or validated with Google Play internal testing.
- No provider secrets, service-role keys, signing passwords, API keys, prompts with private data, or user images are committed.
