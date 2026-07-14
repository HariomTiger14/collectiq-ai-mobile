# Detail Phase 3 Runtime Comparison

Before Phase 3:
- Detail used a standard app bar plus a second embedded PackLox header.
- Detail rendered as a long generic scroll containing hero, AI, attributes, notes, actions, wishlist, market, and alerts in one pass.
- Approved Design Bible states were not represented as compact task sections.

After Phase 3:
- Detail opens directly into an approved compact dark surface.
- The first viewport contains the authority header, image/value overview, and section tabs.
- Gallery, details, market/value, AI insights, notes/status, and actions are reachable through compact tabs.
- Full-screen gallery review and edit/primary/delete image controls remain available from the same image ownership model.

Regression comparison, 2026-07-14:
- Phase 2 accepted ceiling: `562 passed, 16 failed`.
- Current final Phase 3 suite: `567 passed, 15 failed`.
- The claimed `565 passed, 17 failed` regression state was not reproduced at current HEAD.
- The previously documented Detail-adjacent failure `portfolio carousel edit updates image enhancement metadata` now passes; remaining failures are non-Detail baseline debt.

Runtime evidence references:
- Previous current runtime captures: `qa/screenshots/ui_conformance/detail/current_runtime/`
- Approved reference recovery captures: `qa/screenshots/approved_authority_recovery/detail/approved_reference/`
- Phase 3 remediation evidence root: `qa/screenshots/approved_authority_remediation/detail/`
- Regression analysis: `qa/reconstruction/phase_3_detail_test_regression_analysis.md`
