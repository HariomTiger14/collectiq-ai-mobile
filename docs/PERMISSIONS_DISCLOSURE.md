# CollectIQ AI Permissions Disclosure

Draft status: internal review copy. Confirm the final Android manifest,
runtime permission prompts, and Play Store disclosures before launch.

## Camera

Permission:

```text
Camera
```

Why it is requested:

- Let users capture photos of collectibles.
- Show a selected image preview before analysis.
- Save captured images locally for portfolio display.

User impact if denied:

- Camera scan will not work.
- Gallery selection and existing local portfolio features should continue to
  work.

Disclosure copy:

```text
CollectIQ AI uses your camera only when you choose Scan with Camera, so you can
photograph collectibles for analysis and portfolio tracking.
```

## Photos and Media

Permission:

```text
Photos / media / photo picker access
```

Why it is requested:

- Let users choose an existing collectible image from the device.
- Copy or reference the selected image for preview, analysis, and portfolio
  display.

User impact if denied:

- Gallery upload will not work.
- Camera scan and existing local portfolio features should continue to work.

Disclosure copy:

```text
CollectIQ AI accesses photos only when you choose an image from your gallery for
collectible analysis.
```

## Internet

Permission:

```text
Internet / network access
```

Why it is requested:

- Optional backend AI analysis.
- Optional backend market pricing.
- Optional Supabase auth/cloud sync.
- Optional Google Play Billing.
- Optional telemetry/crash reporting if configured.

User impact if unavailable:

- Local-first mock scanning, local portfolio, alerts, wishlist, and goals should
  still work.
- Backend/cloud/billing features may show friendly unavailable or retry states.

Disclosure copy:

```text
CollectIQ AI uses internet access for optional account sync, backend AI/pricing,
billing, and diagnostics. Core local portfolio features remain available without
sign-in.
```

## Notifications

Permission:

```text
Post notifications
```

Why it is requested:

- Show local price alert notifications when a configured alert is triggered.
- Support Android 13+ notification permission requirements.

User impact if denied:

- Price alerts can still exist in the app.
- Local push-style notifications may not be shown.

Disclosure copy:

```text
CollectIQ AI can send local notifications for price alerts you create. You can
disable alert notifications in Settings.
```

## Permission Principles

- Ask only when the feature is used or when Android requires it.
- Keep local-first behavior working where possible if a permission is denied.
- Do not use permissions to collect unrelated data.
- Do not upload images or personal content unless a configured feature requires
  it and the user initiates the relevant flow.

## Manual QA Checklist

- Camera allowed: capture returns to Scan with preview.
- Camera denied: friendly error, no crash.
- Gallery allowed: selected image returns to Scan with preview.
- Gallery denied/cancelled: friendly state, no crash.
- Notifications allowed: local alert notification can be shown.
- Notifications denied: app remains usable and Settings shows denied status.
- Offline: local scan/save flow works in mock/default mode.
