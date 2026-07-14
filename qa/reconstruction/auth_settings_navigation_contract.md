# Authentication and Settings Navigation Contract

## Routing Decision
Use the smallest safe navigation change for implementation: local Flutter `Navigator.push` with `MaterialPageRoute` is sufficient unless an implementation phase separately proves a router migration is necessary. Do not add a Search tab or alter the Phase 0-5 shell destinations.

## Current Shell Contract
The shell keeps Home, Portfolio, Scan, and Settings. Onboarding remains the entry gate. Authentication is not a shell destination and is not a mandatory app-entry gate.

## Allowed Paths

| Source | Destination | Behavior |
| --- | --- | --- |
| Settings account entry | Sign In / choose sign-in method | Push auth flow without replacing shell |
| Sign In | Sign Up | Push or switch within auth flow |
| Sign In | Forgot Password | Push or switch within auth flow |
| Sign Up | Email Verification | Show confirmation-required state after request |
| Auth success | Previous destination, normally Settings fallback | Preserve selected shell tab unless product explicitly changes it |
| Settings signed-in account card | Manage Account | Allowed only for approved account-management scope |

## Prohibited Paths
Do not route every signed-out app launch into Authentication. Do not make Sign In completion force Home unless a later product decision approves that behavior. Do not route password recovery callbacks into mobile reset UI while current parser/web recovery authority remains unchanged.

## Deep Link Contract
Keep the existing deep-link coordinator active from app startup. Email confirmation callbacks may update auth state. Password recovery callbacks remain ignored by the mobile parser because reset completion is web-hosted today.
