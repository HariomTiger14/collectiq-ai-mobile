# PackLox Authentication and Settings Visual Authority Matrix

## Purpose
This document establishes the authority mapping for future Authentication and Settings remediation. It is a contract record only. It does not approve production implementation and does not create a new visual freeze.

## Release Authorities

| Flow | Authority | Master | SHA-256 | Status |
| --- | --- | --- | --- | --- |
| Authentication | `packlox-design-platform/releases/v1.0/design_bible/Volume_01_Authentication` | `images/authentication_flow_master.png` | `aec184c2d1a01ed18778f034c7436cc2780b15e1a93ec80341c4712f629e13b3` | Approved contractual reference, not runtime freeze |
| Settings | `packlox-design-platform/releases/v1.0/design_bible/Volume_10_Settings` | `images/settings_flow_master.png` | `95b00667a6db3f7c3210eeeb890090060a78488de83750f845156220897b4645` | Approved contractual reference, not runtime freeze |

Settings repository mapping uses `Volume_10_Settings` even though the board title text references Volume 09.

## Screen Authority Rows

| Runtime surface | Authority classification | Exact authority | Current Flutter state | Target contract |
| --- | --- | --- | --- | --- |
| Settings home | Approved Settings reference | `screens/01_settings_home.png` | `SettingsScreen` is runtime implementation but includes embedded auth forms | Settings remains a preferences/account/status hub only |
| Account/Profile settings | Approved Settings reference | `screens/02_account_profile.png` | Account tiles and auth panel are mixed in one screen | Account card can show status and entry actions; no credential forms |
| Preferences | Approved Settings reference | `screens/03_preferences.png` | Existing settings sections may remain | Preserve settings-only behavior |
| Notifications | Approved Settings reference | `screens/04_notifications.png` | Existing settings sections may remain | Preserve settings-only behavior |
| Privacy/Security | Approved Settings reference | `screens/05_privacy_security.png` | Existing settings sections may remain | Preserve settings-only behavior |
| Backup/Sync | Approved Settings reference | `screens/06_backup_sync.png` | Sync controls exist in Settings/cloud flows | Show only honest configured/local state |
| Support/Help | Approved Settings reference | `screens/07_support_help.png` | Existing settings sections may remain | Preserve settings-only behavior |
| About PackLox | Approved Settings reference | `screens/08_about_packlox.png` | Existing settings sections may remain | Preserve settings-only behavior |
| Legal | Approved Settings reference | `screens/09_legal.png` | Existing settings sections may remain | Preserve settings-only behavior |
| Danger Zone | Approved Settings reference, clarification required for destructive account flows | `screens/10_danger_zone.png` | No final account-deletion authority | Do not implement account deletion/export semantics without separate approval |
| Welcome/Launch | Approved Authentication reference | `screens/01_welcome_launch.png` | App currently enters onboarding/shell, not auth | Do not introduce mandatory auth guard in this program |
| Choose Sign In Method | Approved Authentication reference | `screens/02_choose_sign_in_method.png` | No separate runtime screen | Candidate entry surface for account access |
| Sign In Email | Approved Authentication reference | `screens/03_sign_in_email.png` | Embedded in `AuthAccessPanel` inside Settings | Move to separate auth presentation before visual freeze |
| Email Verification | Approved Authentication reference | `screens/04_email_verification.png` | Controller status/snack messaging only | Separate confirmation state may be introduced, preserving callback behavior |
| Create Account | Approved Authentication reference | `screens/05_create_account.png` | Embedded sign-up action in Settings auth panel | Move to separate auth presentation before visual freeze |
| Forgot Password | Approved Authentication reference | `screens/06_forgot_password.png` | Embedded action sends web reset email | Preserve backend/web reset contract |
| Reset Password | Approved Authentication plus current web runtime | `screens/07_reset_password.png`; `web/auth/reset-password/*` | Password recovery is web-hosted and parser ignores recovery callbacks | Do not replace with mobile reset without new authority |
| Success/Onboarding | Approved Authentication reference | `screens/08_success_onboarding.png` | Onboarding is separate app-entry flow | Do not conflate auth success with onboarding completion |
| Guest Mode | Approved Authentication reference | `screens/09_guest_mode.png` | Local/guest access exists through repository fallback and shell access | Preserve local access for signed-out users |
| Linked Account | Approved Authentication reference | `screens/10_linked_account.png` | Signed-in panel exists inside Settings | Move account-linked status to Settings/account summary or separate account screen |

## Component Authorities

Approved component authorities available for reuse: `PLX-HEADER-1.0.1`, `PLX-HERO-1.0.1`, `PLX-ENTRY-TILE-1.0`, and `PLX-BUTTON-SYSTEM-1.0`. Approval JSON files are controlling where component prose still says candidate or awaiting review.

## Current Flutter Prior Use
Current Flutter usage is legacy runtime evidence, not visual authority. Phase 0-5 remediation did not approve embedded authentication forms inside Settings, did not create a Search tab, and did not require authentication before Home, Scanner, Portfolio, or Detail.
