# Visual Freeze Amendment Policy

Date: 2026-07-13
Scope: applies to Home, Scanner, Portfolio, Detail visual remediation.

## Freeze Boundaries

Architecture, business, data-flow, backend, router, auth, cloud, controller, and repository freezes remain valid unless a future approved visual remediation proves a narrow, documented conflict. Visual freezes may be reopened narrowly for Design Bible conformance.

## Controlling Authority

Approved Design Bible screen composition is the controlling authority for visual freeze claims. A screen is not visually frozen merely because it uses Product Language components. Product Language components support implementation but do not approve whole-screen composition unless that composition itself is approved and frozen.

## Required For Each Remediation

- Implementation commits scoped to the screen or shared foundation.
- Focused tests for visual structure and frozen behaviour.
- Full-suite regression check reported against the current baseline.
- Physical-device screenshots and XML hierarchy.
- Android log capture and app-crash scan.
- Approved-vs-runtime side-by-side comparisons.
- Deviation closure notes.
- Amended freeze record with exact authority path and commit hash.

## Reopen Rules

- Reopen only the visual surface needed to close approved authority deviations.
- Do not reopen business logic to implement a visual-only state unless product approval says the state is in scope.
- Do not add Search, Notifications, export/share, backend state, or camera lifecycle changes as side effects of visual remediation.
- Shared foundation commits must be independently reversible.

## Amendment Decision

A visual freeze can be restored only when all Critical and High deviations for that screen are fixed, accepted by new approved authority, or explicitly deferred as out of product scope. Medium/Low deviations must have a disposition and evidence plan.
