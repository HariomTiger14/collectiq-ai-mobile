# Screen reconstruction sprint contract

## 1. Target screen and route

Stable ID, current route/widget, entry/exit contracts.

## 2. Authoritative design sources

Release IDs, Studio composition, Bible evidence and approved revisions.

## 3. Product behavior

User goal, success/failure outcomes, analytics.

## 4. State model

Loading, populated, empty, error, offline, permission, session and transitions.

## 5. Existing business dependencies

Controllers/providers/repositories/services/models and callbacks to preserve.

## 6. Approved Product Language components

Names, versions and allowed variants.

## 7. New component gaps

Required approval work; do not improvise production components.

## 8. Presentation files allowed to change

Exact paths.

## 9. Files prohibited from change

Domain/data/backend/config/deep-link/storage/schema/signing paths.

## 10. Responsive requirements

Widths, orientation, text scaling, safe areas, keyboard/insets.

## 11. Accessibility requirements

Semantics, focus/order, contrast, touch sizes, reduced motion.

## 12. Functional tests

Exact behavior/state/navigation tests.

## 13. Visual tests

Golden/reference matrix and tolerances.

## 14. Samsung runtime validation

Device/OS, clean install, flavour, flow and system bars.

## 15. QA evidence package

Fresh screenshots, hierarchy, provenance, smoke record and reviewer notes.

## 16. Safe Git staging

Exact files, clean diff/check, focused commit, no unrelated work.

## 17. Approval/freeze decision

Status, design reviewer, product owner, date, source/implementation commits.

### Reusable Codex task

`Reconstruct [ID/name] at [route] using [approved sources/components]. Preserve [controllers/contracts]. Change only [paths]; prohibit [paths]. Implement [states/responsive/accessibility]. Run [focused/full/analyze/SIT]. Validate on Samsung with fresh screenshot, hierarchy and smoke evidence. Stage exact files only. Stop at awaiting_visual_review; freeze only after explicit design and product-owner approval.`

