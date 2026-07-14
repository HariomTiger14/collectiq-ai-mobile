# Detail Visual Freeze Amendment

This amendment freezes the Phase 3 Detail runtime direction.

Frozen Detail runtime:
- Single compact Detail authority header; no duplicated app bar/header stack.
- Overview hero/value composition above section tabs.
- Sectioned Detail states: Overview, Gallery, Details, Market, Insights, Notes, Actions.
- Existing portfolio, gallery, notes, wishlist, sync, price alert, edit, share, favorite, delete, and return navigation contracts remain intact.

Not frozen as a new product behavior:
- No new valuation engine.
- No generated AI insight text.
- No synthetic price-history series.
- No similar-item recommendations.
- No backend/auth/sync lifecycle changes.

Regression amendment, 2026-07-14:
- The reported `565 passed, 17 failed` blocker was not reproduced at current HEAD `3a90d00f76345daa456d4e4af1a9a632500c559e`.
- Complete failure inventory found 15 current failures, all outside the Phase 3 Detail visual contract.
- Final validation: `flutter analyze` passed; final `flutter test --reporter=compact` completed with `567 passed, 15 failed`.
- Regression approval is final for Phase 3 because the result is below the accepted Phase 2 ceiling of `562 passed, 16 failed`.
- `portfolio carousel edit updates image enhancement metadata`, previously documented as Detail-adjacent baseline debt, passes in the current suite.

Future phases must treat this file plus `detail_approved_visual_contract.md` as the Detail visual freeze baseline.
