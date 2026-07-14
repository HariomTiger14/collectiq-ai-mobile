# Settings Phase 6B Measurements

Authority crop size is 140 x 375 px for S01-S09 and 133 x 375 px for S10. Runtime adapts to Flutter phone widths, so measurements are recorded as ratios and structural relationships.

## Settings Home

- Top inset: authority places content below status bar at about 8% of crop height.
- Header: single-line title, about 5% crop height.
- Section order: Account/Profile card, Account & Profile, Preferences, Notifications, Privacy & Security, Backup & Sync, Support & Help, About PackLox, Danger Zone.
- Rows: compact 36-44 px authority rows, adapted to 48+ logical px tap targets in Flutter.
- Icons: authority icon footprint about 12-14 px; runtime uses existing `ModernSettingsRow` icon container for accessible touch hierarchy.
- First viewport: Settings title, account summary, and first row group.
- Bottom navigation: authority shows five tabs including Search; runtime preserves frozen four-tab shell and does not add Search.

## Account / Profile

- Signed out: identity block says Guest mode and preserves local collection access.
- Signed in: identity block uses real `AuthState.user.email`/display name only.
- Manage Account: represented as status/summary; profile editing is deferred.
- Sign In: opens separate `AuthSignInScreen`.
- Create Account: available through Sign In screen only, matching unresolved direct-entry clarification.
- Sign Out: visible only as supported auth-controller action; local data remains.

## Appearance / Preferences

- Theme state: System only; app currently owns light/dark through `MaterialApp` theme and system mode.
- Selected state: text label `System`; no duplicate theme controller added.
- Scanner preferences: represented as supported ownership notes, not active unsupported toggles.

## Notifications

- Toggle layout: only real price-alert notification preference is interactive.
- Unsupported push/marketing delivery: shown as unavailable, not active.
- Permission state: uses `PriceAlertNotificationState.permissionStatus`.

## Backup / Sync

- Signed out: local-only copy, no backup success claim.
- Signed in: cloud availability depends on existing cloud registry and auth state.
- Last sync: omitted unless runtime state provides it; no fabricated `Today, 9:41 AM`.
- Action: `Sync Now` disabled unless signed in and configured.
- Warning/info: local collection remains available.

## About & Help

- About row: version/build displayed as real current app constants, `1.0.0 (1)`.
- Help/support: unavailable destinations are `Soon`, not dead links.
- Legal: privacy/local state shown; terms/licenses destinations remain conservative.

## Danger Zone

- Destructive placement: final section after Legal.
- Supported actions: Reset Onboarding and Clear Local Collection, both confirmed.
- Unsupported action: Delete Account shown unavailable and not tappable.
- Confirmation: shared `AlertDialog` with Cancel and explicit confirm button.
