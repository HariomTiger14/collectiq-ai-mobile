# Home and Portfolio Visual Defect Audit

Date: 2026-07-13
Branch: rebuild/product-language-v1
Start HEAD: a440a13ce6edab5b580e7fd646faa92c37363550

## Scope

- Home presentation.
- Portfolio presentation.
- App Shell integration directly affecting Portfolio tab entry.
- Shared PackLox Product Language tokens/components used by these screens.

No business logic, search/filter/sort semantics, router behavior, backend, cloud sync, scanner behavior, or original dirty worktree files were changed.

## Before Evidence

Captured on Android device RZ8R213M8ZL before remediation:

- `qa/screenshots/reconstruction/visual_defect_audit_before/01_home_first_viewport.png`
- `qa/screenshots/reconstruction/visual_defect_audit_before/02_home_collection_snapshot.png`
- `qa/screenshots/reconstruction/visual_defect_audit_before/03_home_recent_collectibles.png`
- `qa/screenshots/reconstruction/visual_defect_audit_before/04_home_lower_content.png`
- `qa/screenshots/reconstruction/visual_defect_audit_before/05_portfolio_immediate_entry.png`
- `qa/screenshots/reconstruction/visual_defect_audit_before/06_portfolio_after_scroll.png`
- `qa/screenshots/reconstruction/visual_defect_audit_before/07_portfolio_after_tab_return.png`
- `qa/screenshots/reconstruction/visual_defect_audit_before/08_portfolio_after_restart.png`
- `qa/screenshots/reconstruction/visual_defect_audit_before/09_portfolio_empty_state.png`

The before XML for populated Portfolio showed the header beginning at `bounds="[45,34][308,90]"`, inside the Android status bar range `bounds="[0,0][1080,92]"`.

## Root Causes

- Home `Collection snapshot`, top collectible, grounded insight, and `Recent collectibles` rows still used Material `surfaceContainer*` colors. In light mode those resolved to pale/white surfaces instead of the frozen PackLox raised surface.
- Portfolio root used `colorScheme.surface` for the scaffold background, exposing a white app background in light mode.
- Portfolio `CustomScrollView` was not wrapped in a top `SafeArea`, so the first header could render under the Android status bar.
- Portfolio scroll state used `PageStorageKey('portfolio-scroll-position')` with the App Shell `PageStorageBucket`, allowing stale scroll offsets to be restored when re-entering the tab.
- Portfolio empty and no-results surfaces used Material `surfaceContainerHighest`, which kept the same light-mode white-surface risk in empty/no-results states.

## Fixes

- Home section, top collectible, grounded insight, and recent collectible surfaces now use `PackLoxTokens.surfaceRaised` with PackLox border token opacity.
- Portfolio scaffold and root body surface now use `PackLoxTokens.background`.
- Portfolio scroll content is wrapped in `SafeArea(top: true, bottom: false)`.
- Portfolio scroll controller disables PageStorage restoration with `keepScrollOffset: false`, and the scroll view key is a normal `ValueKey`.
- Portfolio empty and no-results states now use the same PackLox raised surface and border token treatment.

## After Evidence

Captured on Android device RZ8R213M8ZL after remediation:

- `qa/screenshots/reconstruction/visual_defect_audit_after/01_home_first_viewport.png`
- `qa/screenshots/reconstruction/visual_defect_audit_after/02_home_collection_snapshot.png`
- `qa/screenshots/reconstruction/visual_defect_audit_after/03_home_recent_collectibles.png`
- `qa/screenshots/reconstruction/visual_defect_audit_after/04_portfolio_immediate_entry.png`
- `qa/screenshots/reconstruction/visual_defect_audit_after/05_portfolio_after_scroll.png`
- `qa/screenshots/reconstruction/visual_defect_audit_after/06_portfolio_after_tab_return.png`
- `qa/screenshots/reconstruction/visual_defect_audit_after/07_portfolio_after_restart.png`
- `qa/screenshots/reconstruction/visual_defect_audit_after/08_portfolio_empty_state.png`
- `qa/screenshots/reconstruction/visual_defect_audit_after/android_logcat_after.txt`

After XML confirms Portfolio first-entry and tab-return headers begin at `bounds="[45,126][308,182]"`, below the Android status bar `bounds="[0,0][1080,92]"`.

## Validation

- `flutter analyze`: passed, no issues.
- `flutter test test/home_page_test.dart`: passed, 14 tests.
- Focused Portfolio visual tests in `test/widget_test.dart`: passed, 4 tests.
- Frozen Sprint 01-07 focused regression files: 202 passed, 13 failed. Failures are the existing scanner/enhancement/detail baseline area; new Home/Portfolio tests passed in this batch.
- Full suite: 540 passed, 16 failed. This matches the prior failure count while adding six passing Home/Portfolio tests.
- Android local debug build: `flutter build apk --debug --flavor local --dart-define=APP_ENV=local` passed.
- Android install and launch on RZ8R213M8ZL passed.
