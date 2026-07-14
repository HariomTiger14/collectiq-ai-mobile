# Authentication and Settings Separation Contract

## Product Decision
Authentication and Settings are separate product flows. Settings is not the sign-in screen. Authentication screens are not general settings screens.

## Final Contract
Settings may show account status, local/cloud state, sync status, and entry actions that navigate to authentication or account management. Settings must not embed Sign In, Sign Up, Forgot Password, Email Verification, Reset Password, or credential entry forms.

Authentication owns sign-in, sign-up, confirmation, resend confirmation, forgot-password initiation, and auth success states. Password reset completion remains governed by the existing web recovery runtime unless a later authority changes it.

## Required Runtime Separation

| Concern | Owner after remediation | Notes |
| --- | --- | --- |
| Account status row/card | Settings | May show signed out, local-only, signed in, sync status, and Manage Account entry |
| Sign In form | Authentication | Uses Authentication S03 as authority |
| Sign Up form | Authentication | Uses Authentication S05 as authority |
| Forgot Password | Authentication | Uses Authentication S06; preserves web reset redirect |
| Email Verification | Authentication | Uses Authentication S04 and existing callback semantics |
| Reset Password completion | Web recovery runtime | Uses existing `web/auth/reset-password` unless separately approved |
| Sign Out | Settings/account management | Must preserve local data behavior |
| Account deletion/export/destructive account actions | Blocked | Requires separate product/security authority |

## Non-Goals
This contract does not authorize production UI implementation, backend rewrite, Supabase contract changes, router migration, mandatory authentication, Search navigation, cloud data migration, local/cloud merge changes, account deletion, or replacement of onboarding.

## Guest and Local Access
Signed-out access remains supported. Home, Scanner, Portfolio, Detail, onboarding, and local portfolio behavior must continue to work without a cloud account. Authentication may offer cloud sync or account benefits, but must not imply local data is unavailable when signed out.

## Settings Copy Rules
Settings language must distinguish local-only, signed-out, cloud unavailable, and signed-in states honestly. It must not claim backup/sync is active unless the runtime state supports that claim.

## Superseded Runtime Pattern
The current `AuthAccessPanel` embedded in `SettingsScreen` is legacy composition. It may be used as a source inventory during implementation, but it is not approved as the future product structure.
