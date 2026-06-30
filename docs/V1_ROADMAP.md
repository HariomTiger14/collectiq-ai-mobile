# CollectIQ AI v1.0 Product Plan + Technical Roadmap

## 1. Current App Status

CollectIQ AI has a stable Android MVP foundation. The app can scan from camera
or gallery, analyze with mock AI, save to a local-first portfolio, display
portfolio detail pages, show home dashboard analytics, and expose developer
diagnostics for future providers. Auth, cloud sync, subscription, AI provider,
pricing provider, and backend client foundations are in place, but production
AI, pricing, payments, and backend services are not enabled yet.

Current known baseline:

- Android MVP is stable.
- GitHub `main` is up to date.
- 151 Flutter tests are passing.
- Debug/release build paths have been verified previously.
- Mock AI and mock pricing remain the default.
- No paid AI, pricing, payment, or marketplace API is called from Flutter.

## 2. Completed Features

### Core Mobile Experience

- Home dashboard with portfolio analytics, recent activity, and scan CTA.
- Scan flow with camera/gallery selection.
- Stable Android picker return behavior.
- Selected image preview, analysis loading state, result view, and save flow.
- Post-save UX with saved state, View Portfolio, and Scan Another actions.
- Portfolio screen with premium cards, search, filters, sorting, and delete.
- Collectible detail page with image, profile fields, pricing, AI review, and
  delete confirmation.
- Settings screen with app, account, cloud, subscription, and diagnostics areas.

### Local Data + Stability

- Local-first portfolio persistence.
- Persistent local images for camera and gallery.
- Canonical newest-first ordering across Portfolio, Home Recent Activity, and
  Scan Recent Scans.
- Defensive image path handling.
- Back navigation and tab-state stability.

### Architecture Foundations

- AI provider abstraction.
- Mock AI provider.
- OpenAI/Gemini backend-only placeholders.
- Backend AI request/response/error models.
- Backend contract validation.
- Dio HTTP backend client structure, disabled by default.
- Market pricing provider abstraction.
- Mock pricing provider.
- Market comps and market summary models.
- Scan enrichment pipeline combining AI and pricing.
- Auth abstraction and local/anonymous default.
- Supabase/cloud sync foundation and queue hardening.
- Subscription, entitlement, and usage-limit foundation.
- Developer diagnostics for providers, backend endpoint status, and pipeline
  state.

## 3. Remaining v1.0 Features

The remaining v1.0 work should focus on real services, production safety, and
launch readiness rather than new UI surface area.

### Must Have

- Production backend service for image analysis.
- Real AI recognition through backend-only providers.
- Real market pricing data through backend-only provider integrations.
- Production Supabase auth and cloud sync.
- Production subscription/payment implementation.
- Launch-grade privacy, terms, and data handling.
- Release telemetry and crash monitoring.
- Production QA on physical Android devices.

### Should Have

- Confidence and review workflow for low-confidence scans.
- Editable portfolio notes and correction fields.
- Manual re-sync and retry controls.
- Import/export portfolio backup path.
- Basic onboarding explaining mock versus real scan limits.

### Later

- iOS release.
- Web dashboard.
- Advanced valuation history.
- Collection folders or custom lists.
- Sharing/export reports.

## 4. Free / Pro / Premium Plan Breakdown

### Free

- Limited daily scans.
- Local portfolio storage.
- Basic AI identification.
- Basic value estimate.
- Limited recent comparable sales.
- Manual cloud backup disabled or limited.

### Pro

- Higher scan limit.
- Full AI identification.
- Expanded market comps.
- Cloud sync and backup.
- Portfolio search/filter/sort.
- Rich collectible profile fields.
- Export portfolio.

### Premium

- Highest scan limit or unlimited fair-use tier.
- Priority AI processing.
- Advanced pricing blend across multiple sources.
- Price trend monitoring.
- Collection insights and alerts.
- Premium support.
- Early access to new categories/providers.

Implementation note: v1.0 should keep the free plan useful enough for trust and
activation, while making Pro the natural plan for serious collectors.

## 5. Launch Collectible Categories

Launch with categories that have recognizable item data and practical pricing
sources.

### Pokémon / TCG Cards

- Key fields: year, brand, set name, card number, character, rarity, language,
  edition, estimated grade.
- Pricing sources: TCGplayer, eBay sold listings, PriceCharting, PSA where
  available.

### Sports Cards

- Key fields: year, brand, set name, player, team, card number, rookie status,
  estimated grade.
- Pricing sources: eBay sold listings, PriceCharting, PSA, COMC.

### Coins

- Key fields: country, year, denomination, mint, material, condition, estimated
  grade.
- Pricing sources: eBay sold listings, numismatic references, custom market
  provider.

### Comics

- Key fields: title, issue number, publisher, year, variant, grade, key issue
  notes.
- Pricing sources: eBay sold listings, PriceCharting, custom provider.

### Memorabilia

- Key fields: item type, subject, team/franchise, era, authentication status,
  condition.
- Pricing sources: eBay sold listings, custom market provider.

## 6. Backend Architecture Plan

The mobile app should call only the CollectIQ AI backend. All provider keys and
marketplace credentials must remain server-side.

Recommended backend modules:

- `auth`: validates Supabase user/session tokens.
- `uploads`: accepts image upload or signed storage references.
- `recognition`: routes images to AI providers.
- `pricing`: enriches recognized items with market data.
- `portfolio`: persists cloud portfolio records.
- `sync`: handles upload/download queues and conflict metadata.
- `billing`: validates subscriptions and entitlements.
- `observability`: logs request IDs, provider latency, errors, and cost.

Recommended API endpoints:

- `POST /v1/analyze`: image analysis and pricing enrichment.
- `GET /v1/providers/status`: backend provider health.
- `POST /v1/portfolio/sync`: upload local portfolio changes.
- `GET /v1/portfolio`: download cloud portfolio.
- `POST /v1/billing/verify`: verify app store purchase token.

Backend requirements:

- Never trust client-provided entitlement state.
- Enforce per-user rate limits.
- Store provider request/response metadata without leaking secrets.
- Return Flutter-compatible response schema.
- Use idempotency keys for analysis and sync operations.
- Keep AI and pricing provider failures recoverable.

## 7. Real AI Integration Plan

Real AI should be enabled only through the backend endpoint.

### Provider Strategy

- Start with one production AI provider.
- Keep mock provider available for development and tests.
- Keep OpenAI/Gemini providers behind backend config flags.
- Normalize every provider response into the existing backend response contract.

### Recognition Output

The backend should return:

- Primary match.
- Top alternatives.
- Confidence score.
- Confidence explanation.
- Detection quality.
- AI reasoning.
- Recommendation.
- Rich profile fields.
- Category-specific metadata.

### Safety + Quality

- Reject unsupported image types and oversized payloads.
- Add provider timeouts and retries with backoff.
- Return partial result if pricing fails after recognition succeeds.
- Log low-confidence cases for review.
- Add golden backend fixtures per launch category.

## 8. Market Pricing Integration Plan

Pricing should remain independent from recognition. AI identifies the item;
pricing providers value it.

### Provider Priority

1. eBay completed/sold listings through backend provider.
2. TCGplayer for TCG categories.
3. PriceCharting for cards/comics/games where applicable.
4. PSA/graded-card references.
5. Custom fallback pricing provider.

### Pricing Output

- Estimated market value.
- Low/high range.
- Currency.
- Pricing confidence.
- Market trend label.
- Recent comparable sales.
- Source labels.
- Last updated timestamp.

### Matching Rules

- Use category-specific search query builders.
- Normalize title, year, set, number, grade, and condition.
- Filter out active listings when using sold-comps logic.
- Prefer recent sold comps.
- Flag sparse data as low pricing confidence.

## 9. Cloud Sync/Auth Production Plan

The app should stay local-first. Cloud sync must enhance the experience without
blocking scan/save.

### Auth

- Keep anonymous/local mode as default.
- Add email/password sign-in.
- Add Google/Apple sign-in after email auth is stable.
- Link anonymous data to signed-in account when the user upgrades.

### Sync

- Local save always succeeds before cloud sync.
- Queue cloud operations in pending/syncing/synced/failed states.
- Retry failed uploads with backoff.
- Use newest-update-wins conflict policy for v1.0.
- Keep image storage local until cloud upload completes.
- Download cloud portfolio and cache images locally on new devices.

### Supabase

- Enforce RLS for user-owned rows.
- Use user-scoped storage paths.
- Keep private buckets unless public access is intentionally required.
- Validate schema compatibility before enabling production sync.

## 10. Subscription/Payment Plan

Payments should be added after real AI and pricing costs are measurable.

### Platform

- Android v1.0: Google Play Billing.
- Future web/backend billing: Stripe.
- Backend must verify purchase tokens and return entitlements.

### Entitlement Enforcement

- Client may display plan state, but backend must enforce usage limits.
- Backend should track scans used, billing state, and provider cost.
- Local app should degrade gracefully if billing status cannot refresh.

### Launch Plan

- Keep development unlimited or generous.
- Add configurable scan limits.
- Add upgrade UI only when payment verification is ready.
- Test expired, cancelled, refunded, grace period, and restored purchases.

## 11. Testing / Release Checklist

### Flutter

- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `flutter build apk --release`
- `flutter build appbundle --release`

### Android Manual QA

- Fresh install.
- Camera capture.
- Gallery selection.
- Picker cancellation.
- Permission denied.
- Analyze success.
- Analyze backend timeout.
- Save to portfolio.
- Delete item.
- Restart persistence.
- Cloud disabled.
- Cloud enabled.
- Offline mode.
- Low-confidence result.
- Subscription limit reached.

### Backend QA

- Unit tests for provider mappers.
- Contract tests using Flutter-compatible fixtures.
- Timeout and retry tests.
- Rate-limit tests.
- Auth/RLS tests.
- Storage upload/download tests.
- Pricing provider failure tests.
- Cost and latency logging tests.

### Release Readiness

- Privacy policy.
- Terms of service.
- Data deletion path.
- Crash reporting.
- Non-secret environment config.
- Play Store listing assets.
- Versioning and changelog.
- Internal testing track.

## 12. Recommended Sprint Order to v1.0

### Sprint 1: Backend Analyze Endpoint

- Build `POST /v1/analyze`.
- Accept image upload or storage reference.
- Return current backend response contract.
- Add fixture-based tests.
- Keep Flutter mock default.

### Sprint 2: Real AI Provider

- Implement one backend AI provider.
- Normalize response fields.
- Add confidence explanation and alternatives.
- Validate real examples from all launch categories.

### Sprint 3: Pricing Provider v1

- Implement eBay sold-comps backend provider or first available market source.
- Add category-specific query builders.
- Return pricing summary and comparable sales.

### Sprint 4: Flutter Backend Toggle

- Enable Flutter `openai_vision` backend path for internal builds.
- Test backend timeout, malformed response, and offline states.
- Keep mock available for development.

### Sprint 5: Production Auth + Cloud Sync

- Enable Supabase sign-in.
- Link anonymous/local portfolio to signed-in account.
- Validate storage and database RLS.
- Test sync on two devices.

### Sprint 6: Subscription + Entitlements

- Add Google Play Billing.
- Add backend entitlement verification.
- Enforce scan limits server-side.
- Add upgrade/restore flows.

### Sprint 7: v1.0 QA + Store Release

- Full Android regression pass.
- Backend load/error testing.
- Legal/policy assets.
- Internal testing release.
- Closed testing release.
- Production v1.0 rollout.

## Recommended Next Coding Sprint

Start with **Sprint 1: Backend Analyze Endpoint**. It unlocks real AI and real
pricing while keeping Flutter safe, because the mobile app already has the
contract models, endpoint readiness checks, diagnostics, and disabled-by-default
HTTP client path needed to consume it.
