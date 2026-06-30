# Google Play Data Safety Draft

Draft status: internal planning copy. This mapping should be reviewed against
the exact production build, Google Play Console wording, and final privacy
policy before submission.

## Summary

CollectIQ AI is local-first. Core scan, save, portfolio, wishlist, goals, and
alerts can work without sign-in. Optional features may collect or transmit data
when configured:

- Supabase auth/cloud sync.
- Backend AI recognition.
- Backend pricing providers.
- Google Play Billing.
- Optional telemetry/crash analytics.

## Data Type Mapping

| Data category | Collected? | Shared? | Purpose | Notes |
| --- | --- | --- | --- | --- |
| Email address | Optional | Yes, with Supabase if sign-in enabled | Account management, optional sync | Not required for local mode |
| User IDs | Optional | Yes, with Supabase if sync enabled | Auth-linked cloud records | Supabase user ID |
| Photos/images | Optional | Optional, backend/storage when enabled | Scan analysis, thumbnails, cloud backup | Local by default |
| Files/docs | Optional | Optional, storage/backend when enabled | Image storage for portfolio | User-selected/captured images |
| App activity | Optional | Optional, telemetry provider if configured | Diagnostics, app reliability | Sanitized event names/properties only |
| App diagnostics | Optional | Optional, telemetry/crash provider if configured | Crash and non-fatal error triage | No secrets or personal content |
| Purchase history | Optional | Google Play Billing | Subscription entitlement | Test products in beta |
| Financial info | No direct collection | Google Play may process payments | Billing | App does not collect card data |
| Location | No | No | Not used | No location feature planned |
| Contacts | No | No | Not used | Not requested |
| Health/fitness | No | No | Not used | Not requested |
| Messages | No | No | Not used | Not requested |
| Audio | No | No | Not used | Not requested |

## Data Purposes

### App Functionality

- Account sign-in and optional sync.
- Camera/gallery scanning.
- Portfolio storage.
- Price alerts and local notifications.
- Billing entitlement display.

### Analytics

Only if configured. Events may include app open, scan flow, analyze status,
save, sync, billing, and alert events. Events must be sanitized and must not
include image paths, emails, raw images, API keys, URLs with secrets, or
personal collectible content.

### Developer Communications

Not currently implemented in-app. Support contact is a placeholder until final
launch processes are set.

### Fraud Prevention, Security, and Compliance

Google Play Billing and Supabase may provide their own security and abuse
prevention mechanisms. Backend logs may be used for reliability and abuse
triage in configured environments.

## Data Sharing

Data may be processed by service providers only when the corresponding feature
is configured and used:

- Supabase: auth, database, cloud storage.
- CollectIQ AI backend: AI/pricing request processing.
- OpenAI via backend: optional AI recognition.
- eBay, TCGPlayer, PriceCharting via backend: optional pricing.
- Google Play Billing: purchase/subscription state.
- Optional crash/analytics provider: sanitized diagnostics.

No direct third-party AI/pricing API keys are stored in the Flutter app.

## Security Practices

| Question | Draft answer |
| --- | --- |
| Is data encrypted in transit? | Yes for configured HTTPS backend/Supabase/Google services. Release backend endpoints should require HTTPS. |
| Can users request deletion? | Draft yes: local item deletion exists; cloud/account deletion requires support/manual process until production tooling exists. |
| Is data collection optional? | Core app works locally without sign-in. Backend/sync/telemetry/billing are optional/configured. |
| Does app follow Families policy? | Not assessed. Review before public launch if targeting children. |

## Collection Details by Feature

### Local-first Portfolio

Collected locally:

- Portfolio item data.
- Local image references.
- Wishlist status and goals.
- Price alerts and notification preferences.
- Onboarding completion.

Shared:

- Not shared unless cloud/backend features are enabled.

### Supabase Auth and Cloud Sync

Collected/shared when enabled:

- Email address.
- User ID.
- Portfolio records.
- Image storage paths or uploaded images.
- Sync status/timestamps.

Purpose:

- Authentication.
- Backup/sync.
- Multi-device foundation.

### Backend AI and Pricing

Collected/shared when enabled:

- Image payload or image metadata.
- Requested category/source metadata.
- AI recognition response.
- Pricing results/comparable sales.

Purpose:

- Identify collectibles.
- Estimate value.
- Provide market intelligence.

### Google Play Billing

Collected/shared:

- Purchase/subscription state handled by Google Play Billing.
- App stores entitlement state.

Purpose:

- Plan and usage display.
- Future monetization.

### Telemetry/Crash Analytics

Collected/shared only if configured:

- Sanitized events.
- Sanitized non-fatal error reasons.
- Crash/diagnostic metadata.

Purpose:

- Beta reliability.
- Crash triage.
- Product quality measurement.

## Data Safety Form Draft Answers

- Data collected: Yes, optional depending on feature configuration and use.
- Data shared: Yes, with service providers for optional configured features.
- Data encrypted in transit: Yes for HTTPS-enabled backend/provider services.
- Users can request data deletion: Draft yes, with local delete in app and
  support/manual cloud deletion pending production account deletion tooling.
- Data collection required: No for local-first core app; yes for optional
  cloud/account/backend/billing features.

## Pre-submission Review Checklist

- Verify actual production Supabase, backend, billing, and telemetry settings.
- Confirm HTTPS-only backend endpoint for release builds.
- Confirm final support email and deletion process.
- Confirm if cloud sync is enabled in the submitted beta build.
- Confirm if telemetry/crash reporting is enabled in the submitted beta build.
- Confirm whether images are uploaded in the submitted beta build.
- Confirm Play Billing products are test/internal or production.
