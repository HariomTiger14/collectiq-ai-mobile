# Core Screen Visual Test Strategy

Date: 2026-07-13
Current baseline: 540 passed, 16 failed. Do not describe the full suite as passing until this baseline changes.

## Goals

- Prove visual contract structure with focused widget tests.
- Preserve frozen behaviour and data flow while visual composition changes.
- Capture runtime evidence on physical Android hardware for freeze amendments.
- Record full-suite status honestly, including known failures.

## Focused Tests Per Screen

| Screen | Focused visual/widget tests |
|---|---|
| Home | Empty S02 order, primary/secondary actions, categories/summary position, populated fixture, no-valuation fixture, scan/import/portfolio callbacks, focus order |
| Portfolio | Empty order/surface, populated grid, search/no-results, filter/sort controls, valuation unavailable/zero, gallery indicator if approved, initial scroll, Detail handoff |
| Detail | Approved tab/state order, first viewport, gallery switching/review, use-primary, notes persistence, favorite/share feedback, delete confirmation, unavailable/zero value, missing image |
| Scanner | Scan Hub, camera permission/ready, lifecycle pause/resume, review Original/AI Enhance, multi-image workspace, analysis, result, save confirmation, tab return |

## Frozen Behaviour Tests

- App Shell selected-tab ownership and active-destination lifecycle.
- Home scan/import/portfolio handoffs.
- Scanner controller ownership, image ordering, selected/primary image, analyzer payload, portfolio save path.
- Portfolio search/filter/sort semantics, delete guard, Detail navigation.
- Detail gallery actions, notes persistence, delete safeguards, valuation status semantics.

## Full-Suite Baseline

Before each freeze amendment, run the focused test set and then run the full suite. Report the result as delta from the current known baseline of 540 passed and 16 failed. A remediation phase must not hide, rename, or reclassify existing failures without a separate explanation.

## Golden/Screenshot Comparison Strategy

- Use Design Bible crops as approved references.
- Use physical-device screenshots for runtime evidence.
- Create side-by-side comparisons for every implemented state.
- Pixel-perfect thresholds are valid only after viewport normalization is defined; otherwise use proportion, hierarchy, and state-presence review.
- Save comparisons under `qa/screenshots/approved_authority_remediation/<screen>/comparison/`.

## Semantic And Key Assertions

- Assert primary actions by semantics and text.
- Assert approved section order through keys or text hierarchy.
- Assert unavailable valuation and zero valuation with explicit text/state helpers.
- Assert selected image, selected thumbnail, current tab, and bottom navigation state.

## Surface/Token Assertions

- Assert dark root background where screen authority requires it.
- Assert sheets/dialogs use approved dark surfaces or documented adaptations.
- Assert raised cards use approved surface roles rather than generic light Material defaults.
- Avoid brittle exact color assertions unless the token is the authority.

## First-Viewport Assertions

- Home S02 must show header, empty card, primary/secondary action decisions, next approved section, and nav.
- Portfolio first viewport must show approved summary/search hierarchy for the selected state.
- Detail first viewport must not be dominated by duplicate app bars or oversized hero.
- Scanner workspace/result must avoid long Material page dominance when the board is compact.

## Scroll And Inset Tests

- Verify bottom nav does not cover required content.
- Verify initial Portfolio scroll remains at top.
- Verify Detail tab/section navigation does not hide content behind nav.
- Verify Scanner camera/review controls remain reachable with status/nav bars.

## Runtime Device Matrix

| Tier | Device/runtime |
|---|---|
| Required | Samsung SM E625F, Android 13/API 33, `RZ8R213M8ZL`, 1080x2400, density 450, text scale 1.0 |
| Secondary | Narrow 360 logical px widget sizing |
| Optional | Wider Android or emulator after required device passes |

## Regression Thresholds

- No app crash signature in logcat for focused runtime path.
- No new focused test failures in remediated screen.
- Full-suite failures must not increase without documented unrelated cause.
- Critical/High deviations must be fixed or explicitly accepted/deferred with authority before freeze amendment.

## Freeze Amendment Acceptance

A screen can amend its visual freeze only after focused tests, full-suite status, physical-device evidence, XML hierarchy, side-by-side comparison, logcat scan, and updated deviation closure notes are complete.
