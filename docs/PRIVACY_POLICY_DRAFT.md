# CollectIQ AI Privacy Policy Draft

Draft status: internal review copy. This document is not final legal advice and
must be reviewed by the product owner and qualified counsel before public
launch.

Last updated: 2026-06-30

## Overview

CollectIQ AI helps collectors scan, analyze, save, and track collectibles. The
app is designed to be local-first: users can use core functionality without
creating an account. Optional cloud sync, backend AI/pricing, billing, local
notifications, and telemetry may be enabled for beta or production builds.

## Data We May Process

### Account Email

If a user signs in with email/password, the account email may be processed by
Supabase to authenticate the user and associate optional cloud sync records with
that account.

Purpose:

- Account sign-in and sign-out.
- Optional cloud sync identity.
- Account support and troubleshooting.

### Collectible Images

Users may capture or select collectible photos through Camera or Gallery. Images
are saved locally first. If cloud sync or backend AI is enabled, images or image
metadata may be sent to the configured backend or storage provider.

Purpose:

- Show scan preview and portfolio thumbnails.
- Run collectible recognition through the backend when configured.
- Upload portfolio images to optional cloud storage when sync is enabled.

### Portfolio Items

Portfolio records may include item title, category, condition, confidence,
estimated value, pricing fields, AI review, rich profile fields, wishlist
status, goals, alerts, saved date, and local/cloud image references.

Purpose:

- Save and display a user's collection.
- Calculate dashboard insights and portfolio analytics.
- Evaluate local price alerts and wishlist/goal progress.
- Sync portfolio records when cloud sync is enabled.

### Usage and Subscription Status

The app may store scan usage, subscription plan, entitlement state, billing
availability, and purchase/restore status.

Purpose:

- Track development-safe usage limits.
- Show plan and usage in Settings.
- Support future Google Play Billing entitlement checks.

### Diagnostics, Crash, and Analytics Events

CollectIQ AI includes a telemetry abstraction. The default implementation is
no-op unless a provider is explicitly configured. When enabled, events may
include app open, scan started, image selected, analyze success/failure, save to
portfolio, price alert triggered, subscription purchase status, and cloud sync
status.

Telemetry must not include API keys, image paths, file paths, account emails,
personal collectible content, or raw image data.

Purpose:

- Diagnose beta crashes and non-fatal errors.
- Measure reliability of scan, sync, billing, and alert flows.
- Improve app stability and usability.

### Cloud Sync Data

When cloud sync is configured and enabled, portfolio items, image storage paths,
sync status, timestamps, and user IDs may be stored in Supabase.

Purpose:

- Backup portfolio records.
- Prepare multi-device sync.
- Track pending, synced, failed, or retryable upload state.

### Local-only Data

The app stores data locally by default, including portfolio items, image paths,
wishlist status, collection goals, price alerts, onboarding completion, usage
counts, and settings preferences.

Purpose:

- Enable offline/local-first use.
- Preserve portfolio and app state across restarts.
- Avoid requiring sign-in for core features.

## Permissions

See `docs/PERMISSIONS_DISCLOSURE.md` for a complete permission explanation.

Summary:

- Camera: capture collectible photos.
- Photos/media: select collectible images from the device.
- Internet: optional backend, cloud sync, auth, billing, diagnostics, and
  pricing/AI validation through backend services.
- Notifications: local price alert notifications on supported Android versions.

## Third-party Services

### Supabase

Supabase may be used for optional authentication, database sync, and storage.
Supabase configuration must come from environment/build configuration and not
from hardcoded secrets.

### OpenAI via Backend

If backend AI is configured, images or image payload metadata may be sent from
the app to the CollectIQ AI backend, which may call OpenAI using server-side API
keys. Flutter must never store or expose OpenAI API keys.

### eBay, TCGPlayer, and PriceCharting via Backend

Pricing providers are backend-only. The app may receive normalized pricing
results from the backend. Flutter must never call third-party pricing APIs
directly or store provider keys.

### Google Play Billing

Google Play Billing may process purchase and subscription status for Android
plans. Purchase handling is optional and free/local mode remains available if
billing is unavailable.

### Optional Crash/Analytics Provider

Future crash or analytics providers may be added behind the telemetry
abstraction. Providers must be disabled unless configured and must use sanitized
events only.

## Data Sharing

CollectIQ AI should not sell personal data. Data may be shared with configured
service providers only to provide app functionality, such as optional auth,
cloud sync, backend AI recognition, backend pricing, billing, diagnostics, or
crash reporting.

## Security

- API keys and provider secrets must remain server-side.
- Release backend endpoints should use HTTPS.
- Supabase production setup should use Row Level Security.
- Telemetry should sanitize sensitive fields before any external reporting.
- Local data remains on the device unless sync/backend features are enabled.

## User Choices and Rights

### Local Mode and Sign-out

Users can use the app without signing in. Signing out should not delete local
portfolio data.

### Data Export

Portfolio export is planned but not finalized. Until a production export feature
is available, internal beta users can request manual support.

### Data Deletion

Users may delete local portfolio items in the app. For cloud data deletion,
users should contact support until full account deletion tooling is available.

### Notifications

Users can allow or deny Android notification permission. Price alert
notifications can be disabled in Settings.

## Children's Privacy

CollectIQ AI is intended for collectors and beta testers. A final public policy
should define age requirements before public launch.

## Contact

Support contact placeholder:

```text
support@collectiq.ai
```

Replace this placeholder with the production support contact before launch.

## Review Notes Before Launch

- Confirm actual production providers and data flows.
- Confirm privacy policy URL for Play Console.
- Confirm retention/deletion processes.
- Confirm jurisdiction-specific requirements.
- Confirm support/contact details.
