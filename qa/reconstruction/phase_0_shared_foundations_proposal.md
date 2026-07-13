# Phase 0 Shared Foundations Proposal

Date: 2026-07-13
Recommended first implementation task: establish shared visual foundations for dark surfaces, safe areas, header composition rules, raised surfaces, and modal sheet surfaces without adding Search navigation or changing screen-specific layouts.

## Proposed Scope

- Map existing Flutter token usage to approved dark-board roots and raised surfaces.
- Add or configure a shared dark sheet/dialog treatment only if existing theme hooks support it safely.
- Document Header composition rules so screen pages stop treating generic Header usage as screen conformance.
- Define safe-area and bottom-nav clearance rules for screen scroll containers.
- Do not add Search as a tab until the product contract clarification is resolved.

## Exact Files Likely To Change

- `lib/core/theme/app_theme.dart`
- `lib/core/design_system/design_system.dart`
- `lib/core/ui/product_language/product_language_tokens.dart`
- A small shared sheet/dialog wrapper only if one already exists or can be added without changing business behavior
- Focused shared visual tests
- Screen files only for minimal configuration adoption if the shared token already exists and the change is required to prevent light surfaces

## Tests

- Shared token/surface tests.
- Bottom-sheet/dialog surface smoke tests.
- App Shell navigation regression tests.
- Existing Home/Portfolio/Detail/Scanner focused smoke tests if any shared theme changes are made.

## Risks

| Risk | Mitigation |
|---|---|
| Broad visual change affects all screens | Keep first commit small, use existing tokens, capture before/after evidence |
| Product Language component redesign by accident | Do not edit component anatomy unless approved authority proves a component defect |
| App Shell Search scope creep | Explicitly exclude Search tab from Phase 0 implementation |
| Sheet/dialog behaviour regression | Change styling only; keep interaction callbacks and dismissal semantics unchanged |

## Commit Structure

1. `fix: align shared visual foundations with approved authority`
2. `test: validate shared visual foundations`
3. `chore: add shared visual foundation evidence`
4. `docs: record phase 0 shared foundation decisions`

## Acceptance Criteria

- No production business logic changes.
- No backend/router/auth changes.
- No Product Language component redesign unless separately approved.
- Dark surfaces and sheets no longer contradict approved boards where shared tokens are used.
- Four-tab App Shell remains unchanged unless a separate clarification approves Search.
- Full-suite status is recorded honestly against the 540 passed, 16 failed baseline.
