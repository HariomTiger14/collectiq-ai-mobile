# Authentication and Settings Implementation Program

## Phase A: Separate Authentication Presentation
Create dedicated authentication presentation surfaces for sign-in, sign-up, forgot password, confirmation-required, and signed-in success/account-linked states using Authentication authority screens S02-S06 and S10. Reuse existing `AuthController` and repository contracts. Preserve deep-link and web reset behavior.

Evidence required before freeze: widget tests for separate auth surfaces, controller-state coverage for sign-in/sign-up/confirmation/forgot-password, and visual comparison against authority crops.

## Phase B: Remediate Settings Presentation
Remove embedded credential forms from Settings. Replace them with an account/status entry area that shows signed-out, local-only, signed-in, sync unavailable, and sync active states honestly. Settings keeps preferences, notifications, privacy/security, backup/sync, support, about, legal, and danger-zone sections according to Settings authority.

Evidence required before freeze: Settings signed-out and signed-in widget tests without `settings-auth-*` credential fields, visual comparison against Settings S01/S02/S06/S10 as relevant, and regression checks that Home/Scanner/Portfolio/Detail still work signed out.

## Phase C: Integration QA
Validate navigation from Settings to auth and back, email confirmation callback behavior, password reset email flow, sign-out data retention, local-only access, and Supabase-unconfigured fallback. Replace legacy Settings-embedded auth tests with separated tests.

Evidence required before freeze: analyzer pass, targeted tests, and runtime screenshots or measured evidence for any screen being frozen.

## Prohibited During These Phases
Do not rewrite Supabase contracts, migrate routing globally, add a mandatory auth guard, add Search navigation, change onboarding entry, delete local data on sign-out, implement account deletion, or replace web password reset without a separate approval.

## Rollback Strategy
Each phase should be independently revertible. Phase A may coexist behind Settings entry navigation before Phase B removes embedded forms. Phase B should not depend on backend changes.
