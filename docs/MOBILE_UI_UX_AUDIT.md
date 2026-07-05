# Mobile UI/UX Audit

Audit date: 2026-07-05  
Scope: Flutter mobile app screens, navigation flows, UI components, loading/error/empty states, and release-readiness design risks in `lib/`.  
Result: audit/planning only. No app code was changed.

## Executive Summary

CollectIQ AI / PackLox has a substantial mobile UI foundation, not a thin prototype. The app already covers onboarding, bottom-tab navigation, Home, Scan, Portfolio, Collectible Detail, Settings, Account Access, Cloud Sync, and About. It also includes empty/error/loading states for the main local workflows.

The core design direction is premium and modern, with strong use of Material 3, constrained layouts, typography tokens, icons, glass cards, gradients, and motion. The main risk is that the visual language is currently over-applied: many surfaces use gradients, blur, glow, animated reveals, shimmer, pulse, and nested cards. That can make important actions less obvious, make Settings feel more like a diagnostics console than a polished consumer screen, and create release-mode performance risk on lower-end phones.

Design changes are recommended before beta, mostly to simplify the first-run and scan flows, make analysis results easier to trust, make portfolio items feel more tangible, and reduce heavy UI composition.

## Screens Reviewed

| Area | Screen / Flow | Primary file paths |
| --- | --- | --- |
| App shell | Onboarding gate, bottom tabs, tab reset behavior | `lib/main.dart`, `lib/core/navigation/app_shell.dart`, `lib/core/ui/navigation/glass_bottom_nav_bar.dart` |
| First run | Onboarding / about-app introduction | `lib/features/onboarding/presentation/onboarding_screen.dart` |
| Home | Dashboard, quick actions, recent activity, system/status widgets | `lib/features/home/presentation/home_screen.dart`, `lib/core/ui/home/home_ui.dart`, `lib/features/home/presentation/widgets/home_dashboard_widgets.dart`, `lib/features/home/presentation/widgets/portfolio_visual_analytics.dart` |
| Scan | Camera/gallery/sample entry, selected-image preview, analysis status, errors | `lib/features/scanner/presentation/pages/scanner_screen.dart`, `lib/core/ui/scan/scan_ui.dart`, `lib/features/scanner/presentation/widgets/scanner_widgets.dart` |
| Camera | Full-screen capture surface | `lib/features/scanner/presentation/pages/camera_capture_page.dart` |
| Analysis result | AI result, pricing, matches, confidence, save-to-portfolio | `lib/features/scanner/presentation/widgets/scanner_widgets.dart`, `lib/features/scanner/presentation/controllers/scanner_controller.dart` |
| Portfolio | Portfolio list/grid, search, sort, filter, empty/error states | `lib/features/portfolio/presentation/portfolio_screen.dart`, `lib/features/portfolio/presentation/widgets/portfolio_widgets.dart`, `lib/core/ui/portfolio/portfolio_ui.dart` |
| Detail | Collectible detail, edit dialog, AI insights, price alerts, actions | `lib/features/portfolio/presentation/pages/collectible_detail_page.dart`, `lib/core/ui/item_details/item_details_ui.dart` |
| Settings | Account, cloud, AI, notifications, onboarding reset, developer diagnostics, help/about | `lib/features/settings/presentation/settings_screen.dart`, `lib/core/widgets/modern_settings_row.dart` |
| Auth | Sign in, sign up, email confirmation resend, forgot password | `lib/features/auth/presentation/widgets/auth_access_panel.dart`, `lib/features/auth/presentation/controllers/auth_controller.dart`, `lib/features/auth/services/auth_deep_link_service.dart` |
| Reset password | Web reset-password target and mobile callback support | `web/auth/reset-password/`, `web/auth/callback/`, `lib/features/auth/services/auth_deep_link_service.dart` |
| Cloud sync | Sync dashboard, diagnostics, manual sync action | `lib/features/cloud/presentation/cloud_sync_screen.dart`, `lib/core/ui/cloud_sync/cloud_sync_ui.dart` |
| About/help | App info, links, support placeholders, brand card | `lib/features/about/presentation/about_screen.dart`, `lib/core/ui/about/about_ui.dart` |
| Premium/subscription | Usage limits, plan state, billing foundation, premium placeholders | `lib/features/subscription/**`, `lib/features/settings/presentation/settings_screen.dart`, `lib/features/scanner/presentation/widgets/scanner_widgets.dart` |
| Shared states | Placeholder screen, glass/card/header components | `lib/shared/widgets/app_placeholder_screen.dart`, `lib/core/design_system/layout_components.dart`, `lib/core/widgets/glass_card.dart`, `lib/core/widgets/gradient_header.dart` |

## Design Principle Evaluation

| Principle | Rating | Notes |
| --- | --- | --- |
| Engaging but not cluttered | Partial | Visual polish is strong, but Home, Scan, Detail, Auth, Settings, and About all use similar high-energy glass/gradient/motion treatments. This can feel busy. |
| Premium and trustworthy | Partial | Palette, typography, and spacing feel premium. Trust is weakened by visible "mock", "soon", diagnostics, and placeholder language in user-facing flows. |
| Simple navigation | Good | Four bottom tabs are understandable. Pushed About, Detail, Cloud Sync, and Camera flows are conventional. |
| Clear primary action on every screen | Partial | Scan and Portfolio empty states have clear CTAs. Home has several "Soon" quick actions near the primary scan action. Settings has many rows with equal weight. |
| Fast first-time understanding | Partial | Onboarding explains local-first and scanning, but it exposes implementation language like "Mock AI mode" too early. |
| Empty/loading/error states | Good | Portfolio, scan preparation, scan errors, auth messages, cloud status, and visual analytics empty states exist. Some states need clearer recovery actions. |
| Camera/gallery flow obvious | Partial | Actions exist and are named clearly. The invisible low-opacity "Analyze with AI" compatibility button is a design smell and should not remain in product UI. |
| Analysis results easy to trust | Partial | Confidence, pricing confidence, sources, comps, alternatives, and reasoning exist. Need clearer source freshness, estimate range, and "AI estimate, verify before sale" hierarchy. |
| Portfolio valuable/motivating | Partial | Metrics, value, confidence, alerts, and wishlist support are present. Grid cards currently use category icons instead of actual item thumbnails, reducing emotional value. |
| Settings/about polished but not overdesigned | Partial | Visual polish is high, but Settings includes too much diagnostic/config content for normal users. About links are placeholders. |
| Light/dark mode support | Good | App theme supports light/dark and most components read color scheme. Some gradient/blur contrast should be device-tested. |
| Small/large screen support | Good with caveats | Many responsive constraints, wraps, and ellipses exist. Dense rows and badges can still overflow or truncate important values on small phones/text scale. |
| No cartoonish/childish styling | Good | Styling is modern, not childish. Icons are generic Material icons; use of sparkle/AI icons is acceptable but should be restrained. |

## Screen-Level Audit

### App Shell & Navigation

File paths: `lib/main.dart`, `lib/core/navigation/app_shell.dart`, `lib/core/ui/navigation/glass_bottom_nav_bar.dart`

Current purpose: bootstraps the app, applies light/dark themes, gates onboarding, and provides Home / Portfolio / Scan / Settings bottom navigation.

What works well: the tab model is simple; Scan is reachable from Home and Portfolio; saved scan state resets when leaving Scan; bottom nav uses recognizable icons and labels.

Issues or friction: active Scan gets special gradient treatment, but the overall bottom bar is large and visually decorative. There is no route table/deep link structure for in-app screens beyond `MaterialPageRoute`, so flows are understandable but not very inspectable.

Design change required: Yes.  
Recommended improvement: keep the four-tab model, but simplify bottom nav effects and ensure Scan remains visibly primary without making the nav feel heavy.  
Priority: P2.

### Onboarding / First Screen

File paths: `lib/features/onboarding/presentation/onboarding_screen.dart`, `lib/core/navigation/app_shell.dart`

Current purpose: explains PackLox, local-first behavior, scan/analyze/save/track steps, and offers `Start Scanning` or `Explore Dashboard`.

What works well: clear step-by-step education; two obvious actions; local-first privacy positioning is valuable; layout is constrained for larger screens.

Issues or friction: copy exposes beta implementation details such as "Mock AI mode identifies..." before the user has any product context. The "Explore Dashboard" path can land first-time users on an empty dashboard with many non-primary actions and "Soon" items.

Design change required: Yes.  
Recommended improvement: rewrite onboarding as user-value copy, not implementation copy. Make `Start Scanning` the dominant path, and if `Explore Dashboard` remains, show an empty-dashboard coach mark or a simple first-scan CTA.  
Priority: P1.

### Home

File paths: `lib/features/home/presentation/home_screen.dart`, `lib/core/ui/home/home_ui.dart`, `lib/features/home/presentation/widgets/home_dashboard_widgets.dart`, `lib/features/home/presentation/widgets/portfolio_visual_analytics.dart`

Current purpose: collection dashboard with hero metrics, quick actions, portfolio snapshot, recent activity, starter categories, AI insight, collection value, and system status.

What works well: dashboard content is comprehensive; empty portfolio messaging exists; recent items open details; constrained width is good for tablets; metrics make the app feel valuable.

Issues or friction: many separate sections compete with the primary action. Three quick actions are disabled/soon, which makes the first screen feel unfinished. System status and local-first implementation labels are useful for beta but less motivating for normal users. Heavy hero motion/glass cards are repeated through the screen.

Design change required: Yes.  
Recommended improvement: for beta, make Home a focused collector dashboard: hero value, primary `Scan`, recent items, portfolio health, and one insight. Move disabled future actions behind a "More" or remove them until real.  
Priority: P1.

### Scan Entry & Selected Image Flow

File paths: `lib/features/scanner/presentation/pages/scanner_screen.dart`, `lib/core/ui/scan/scan_ui.dart`, `lib/features/scanner/presentation/widgets/scanner_widgets.dart`, `lib/features/scanner/presentation/controllers/scanner_controller.dart`

Current purpose: entry point for camera, gallery, sample scan, selected image preview, analysis status, errors, and recent scans.

What works well: camera/gallery/sample are available; selected image preview is prominent; scan status shows category/confidence/model status; preparation and error states exist; lost picker recovery is handled.

Issues or friction: there is a hidden low-opacity `Analyze with AI` button kept for compatibility, which is not product-grade UI. Action row labels shift between `Scan with Camera`, `Analyze`, and reset states, so the primary next action can be missed. The scan surface has animated ambient gradients, scanner waves, blur, glow, and parallax together.

Design change required: Yes.  
Recommended improvement: replace the action row with a simple state machine layout: no image = Camera/Gallery/Sample; image selected = large `Analyze` plus secondary `Retake`/`Choose another`; result ready = `Save to Portfolio` primary. Remove invisible controls.  
Priority: P0.

### Camera Capture

File paths: `lib/features/scanner/presentation/pages/camera_capture_page.dart`, `lib/features/scanner/services/camera_service.dart`

Current purpose: full-screen native-style camera capture with close, flash, capture, loading, and permission/error messaging.

What works well: full-screen black camera surface is appropriate; close and flash controls are familiar; capture button is clear; permission failure is handled.

Issues or friction: no framing guide, edge/corner overlay, or short instruction for collectible photos. Permission error has no direct Settings/retry action. If camera preview aspect ratio differs, visual framing should be device-tested.

Design change required: Yes.  
Recommended improvement: add a subtle collectible framing guide, a one-line tip such as "Fit the item inside the frame", and clear retry/open-settings handling for permission denial.  
Priority: P1.

### Gallery Flow

File paths: `lib/features/scanner/presentation/pages/scanner_screen.dart`, `lib/features/scanner/services/gallery_service.dart`, `lib/features/scanner/presentation/controllers/scanner_controller.dart`

Current purpose: choose image, validate it, copy it to app storage, then show selected-image preview.

What works well: uses system picker; validates/persists selected images; shows preparing state while copying; handles cancellation and missing file errors.

Issues or friction: cancellation currently surfaces as an error-style message, which can feel punitive for normal back/cancel behavior. Preparing copy text says "CollectIQ storage" while the product brand in UI is PackLox, creating naming inconsistency.

Design change required: Yes.  
Recommended improvement: treat cancellation as neutral/no-op or a light toast. Align copy to PackLox/CollectIQ naming decision.  
Priority: P1.

### Analysis Result

File paths: `lib/features/scanner/presentation/widgets/scanner_widgets.dart`, `lib/features/scanner/presentation/controllers/scanner_controller.dart`, `lib/features/scanner/domain/entities/scan_result.dart`

Current purpose: displays item identity, value, confidence, condition, primary/alternative matches, pricing details, market summary, AI reasoning, recommendation, save/view portfolio/scan another actions.

What works well: rich result data exists; confidence and pricing confidence are visible; alternative matches and comparable sales help trust; saved state prevents duplicate saves.

Issues or friction: result content is information-dense and visually similar across sections. Trust hierarchy should be clearer: what is known, what is estimated, where the price came from, and how fresh it is. The save action appears after a lot of explanatory content.

Design change required: Yes.  
Recommended improvement: restructure result into a top trust summary: item name, estimated range, confidence, sources, last updated, and primary `Save to Portfolio`; then expandable detail sections for reasoning, alternatives, and comps.  
Priority: P0.

### Save-To-Portfolio Flow

File paths: `lib/features/scanner/presentation/widgets/scanner_widgets.dart`, `lib/features/scanner/presentation/controllers/scanner_controller.dart`, `lib/features/portfolio/presentation/controllers/portfolio_controller.dart`

Current purpose: converts scan result into `CollectibleItem`, saves locally, enqueues image upload when configured, and marks saved.

What works well: duplicate save is prevented; user gets a snackbar; `View Portfolio` and `Scan Another` options exist after save; local-first save is functional.

Issues or friction: save confirmation is a transient snackbar and the user may not notice that the portfolio now contains the item. There is no lightweight editable confirmation before saving if the AI title/category/value is wrong.

Design change required: Yes.  
Recommended improvement: after save, show a persistent success panel with `View in Portfolio`, `Edit details`, and `Scan another`. Consider a compact pre-save review for title/category/value.  
Priority: P1.

### Portfolio List

File paths: `lib/features/portfolio/presentation/portfolio_screen.dart`, `lib/features/portfolio/presentation/widgets/portfolio_widgets.dart`, `lib/core/ui/portfolio/portfolio_ui.dart`

Current purpose: displays portfolio summary, search, sort, category filter, item grid, empty/error/no-results states, and delete/share/edit affordances.

What works well: search/sort/filter are present; empty and no-results states have useful actions; aggregate value and average confidence make the collection feel meaningful; delete confirmation exists.

Issues or friction: the active grid card uses a category icon thumbnail rather than the saved item image, despite image rendering helpers existing. This makes the collection less personal and less premium. Row actions include edit/share/delete even when some are placeholders or indirect.

Design change required: Yes.  
Recommended improvement: use real saved thumbnails in grid cards; demote per-card edit/share/delete into an overflow menu; keep tap-to-open dominant.  
Priority: P0.

### Collectible Detail

File paths: `lib/features/portfolio/presentation/pages/collectible_detail_page.dart`, `lib/core/ui/item_details/item_details_ui.dart`

Current purpose: shows saved item hero image, metadata, attributes, AI insights, value, wishlist status, detailed pricing/market sections, price alerts, edit/share/delete actions.

What works well: rich detail surface; edit dialog is functional; price alert creation is useful; hero image can display local/network/asset images; empty "Not specified" values are handled.

Issues or friction: multiple premium cards and animated effects make the page long and visually dense. Some quick actions (`Re-analyze`, `Sell Item`, `Share`) are placeholders/snackbars, which makes the detail screen feel less finished. Attribute rows include blank/unused fields such as `Model`.

Design change required: Yes.  
Recommended improvement: prioritize hero, value/trust summary, editable attributes, and alerts. Hide placeholder actions until real. Only show populated fields or clear add-field affordances.  
Priority: P1.

### Settings

File paths: `lib/features/settings/presentation/settings_screen.dart`, `lib/core/widgets/modern_settings_row.dart`

Current purpose: account overview, auth access, cloud sync, AI scanning status, theme/onboarding/notifications, developer diagnostics, and help/about.

What works well: thorough beta surface; rows have consistent structure; diagnostics are collapsible; onboarding reset and notification controls exist; cloud state is transparent.

Issues or friction: Settings is overloaded. Normal users see implementation details like Supabase, AI providers, mock mode, developer tools, SIT readiness, API backend, and "requires setup". Many rows are informational but tappable only to show a snackbar. This makes the app feel like a test harness rather than a premium product.

Design change required: Yes.  
Recommended improvement: split Settings into user sections (`Account`, `Sync`, `Notifications`, `Appearance`, `Help`) and hide developer diagnostics behind a debug flag or long-press/dev build entry. Make non-action rows visually non-tappable.  
Priority: P0.

### Auth / Login / Signup

File paths: `lib/features/auth/presentation/widgets/auth_access_panel.dart`, `lib/features/auth/presentation/controllers/auth_controller.dart`, `lib/features/settings/presentation/settings_screen.dart`

Current purpose: email/password sign in, sign up, confirmation resend, forgot password, password strength, signed-in panel, sign out.

What works well: inline validation exists; password visibility toggle exists; loading, error, success, resend cooldown, and forgot-password cooldown are handled; signed-in state is distinct.

Issues or friction: auth is embedded deep in Settings rather than having a dedicated account entry flow. Visual treatment is heavy compared with the seriousness of auth. The copy mixes optional local mode, Supabase, SIT auth, and sync in ways that may confuse public users.

Design change required: Yes.  
Recommended improvement: keep optional sign-in, but present it as a focused account screen/sheet with minimal copy: "Sign in to sync and restore your collection." Move provider/build details to diagnostics.  
Priority: P1.

### Forgot / Reset Password

File paths: `lib/features/auth/presentation/widgets/auth_access_panel.dart`, `lib/features/auth/presentation/controllers/auth_controller.dart`, `lib/features/auth/services/auth_deep_link_service.dart`, `web/auth/reset-password/`, `web/auth/callback/`

Current purpose: mobile sends password reset email; web reset-password page handles update flow; callback/deep link services support auth completion.

What works well: forgot password button exists; tests cover reset email behavior and web reset page presence; cooldown/rate-limit handling exists.

Issues or friction: mobile UI does not provide an in-app reset-password screen; the reset flow depends on web/deep-link handoff. That can be acceptable, but the mobile user experience needs release validation and clearer "check your email" next step.

Design change required: Yes.  
Recommended improvement: polish the forgot-password success state with explicit next steps and confirm the web reset page visually matches PackLox. Add a simple in-app callback result screen if deep link returns to app.  
Priority: P1.

### Cloud Sync

File paths: `lib/features/cloud/presentation/cloud_sync_screen.dart`, `lib/core/ui/cloud_sync/cloud_sync_ui.dart`, `lib/features/cloud_sync/presentation/controllers/sync_controller.dart`

Current purpose: displays cloud sync status, items backed up/pending, diagnostics, Supabase project/storage usage, and manual `Sync Now`.

What works well: status and pending/backed-up counts are visible; manual sync disabled state is explicit; local portfolio remains safe on failure; back navigation is clear.

Issues or friction: too much provider-specific language leaks into the user experience. Disabled `Sync Now` can feel like a broken feature when cloud is not configured. Diagnostics are useful for testers but not public users.

Design change required: Yes.  
Recommended improvement: public version should frame this as "Backup & sync" with simple states: off, sign in required, syncing, backed up, attention needed. Provider diagnostics should be hidden.  
Priority: P1.

### About / Help

File paths: `lib/features/about/presentation/about_screen.dart`, `lib/core/ui/about/about_ui.dart`

Current purpose: app version/build, Flutter/Supabase/storage info, privacy/terms/contact/docs placeholders, brand card.

What works well: visually polished; back behavior is clear; version/build and storage mode are surfaced; links are grouped.

Issues or friction: public-facing About shows internal technology details and placeholder link snackbars. Version is hardcoded to `1.0.0` while Settings has a different visible `0.1.0` string in a settings-about card snippet, creating consistency risk.

Design change required: Yes.  
Recommended improvement: use package metadata for version/build, make Privacy/Terms/Contact real links before launch, and move technical stack details to diagnostics.  
Priority: P1.

### Premium / Subscription Placeholders

File paths: `lib/features/subscription/**`, `lib/features/settings/presentation/settings_screen.dart`, `lib/features/scanner/presentation/widgets/scanner_widgets.dart`, `lib/features/home/presentation/widgets/home_dashboard_widgets.dart`

Current purpose: usage limits, entitlement state, Google Play billing foundation, unavailable billing fallback, and premium/pro labels/placeholders.

What works well: domain/controller foundation exists; free/pro/premium concepts are modeled; scanner checks usage before analysis.

Issues or friction: premium UI is not a complete purchase experience; several upgrade/promotional elements are placeholders or not wired into a polished paywall. Public users should not see paywall or upgrade promises until products, pricing, restore, and entitlement behavior are verified.

Design change required: Yes.  
Recommended improvement: hide upgrade prompts for beta unless billing is being tested. If shown, create a dedicated paywall with product loading/error/restore states.  
Priority: P2 for beta if hidden, P0 if monetization is enabled.

### Loading / Error / Empty States

File paths: `lib/features/portfolio/presentation/widgets/portfolio_widgets.dart`, `lib/features/scanner/presentation/widgets/scanner_widgets.dart`, `lib/features/cloud/presentation/cloud_sync_screen.dart`, `lib/features/auth/presentation/widgets/auth_access_panel.dart`, `lib/features/home/presentation/widgets/portfolio_visual_analytics.dart`

Current purpose: communicate loading, empty content, errors, no results, auth status, sync status, and visual analytics absence.

What works well: broad state coverage exists; messages are generally human-readable; portfolio empty and no-results states include actions.

Issues or friction: some recoverable states lack direct next actions; cancellation is treated like an error in scanner flow; cloud disabled states can read like failures; some loading states are generic spinners without expected wait time.

Design change required: Yes.  
Recommended improvement: standardize states into neutral empty, busy, recoverable error, and blocked/setup-required patterns. Include direct CTAs where the user can act.  
Priority: P1.

## Specific Checks

| Check | Finding |
| --- | --- |
| Inconsistent spacing | Spacing tokens are used, but screens mix `20`, `22`, `24`, `32`, `AppSpacing`, and multiple custom radii. Recommend tightening to design tokens. |
| Too many gradients/glow effects | Yes. Gradients/glows/blur are heavily used across nearly every major screen. Reduce to hero/primary moments. |
| Unclear buttons | Some rows are tappable only to show snackbars; Scan action state changes can be clearer; hidden analyze button must be removed. |
| Missing empty states | Major empty states exist. Detail sub-sections should hide empty fields instead of showing many "Not specified" rows. |
| Weak CTA hierarchy | Home, Settings, and result flow need stronger primary action hierarchy. |
| Confusing About to Dashboard transition | First-run `Explore Dashboard` can land on an empty dashboard with "Soon" quick actions. Needs a clearer empty-dashboard first-run state. |
| Prototype-looking screens | Settings developer diagnostics, About placeholder links, premium placeholders, and "Soon" quick actions are the main prototype signals. |
| Text overflow risks | Many ellipses are present, which prevents crashes but can hide important data. Risks: long item names, market sources, auth emails, status rows, badges, and large text scale. |
| Release performance risks | Yes. Repeated `BackdropFilter`, large blurs, animated gradients, scanner waves, shimmer, pulse, and many animated reveal widgets can be costly on low-end devices. |

## Key Design Risks

1. The app can look more complex than it is because almost every screen uses premium effects.
2. User-facing beta/build details reduce trust, especially "Mock AI", "Supabase", "SIT", "Not configured", and "Soon".
3. The scan-to-result-to-save flow needs a sharper primary-action sequence before beta.
4. Analysis results include trust data, but the trust story is not summarized clearly enough.
5. Portfolio grid not showing actual saved images makes the collection feel less valuable.
6. Settings currently mixes user settings, account access, cloud setup, developer diagnostics, and placeholders.
7. Heavy blur/motion composition may hurt release performance on lower-end Android devices.

## Redesign Roadmap

### Must Fix Before Beta

- Remove invisible/near-invisible controls from Scan and make the scan state machine explicit.
- Make `Analyze` and `Save to Portfolio` the unmistakable primary actions at the right moments.
- Use actual saved item thumbnails in the Portfolio grid.
- Simplify Settings for normal users or hide developer diagnostics behind debug/SIT gating.
- Rewrite onboarding copy to remove "Mock AI mode" and beta implementation phrasing.
- Convert scanner cancellation into a neutral state, not an error.
- Reduce repeated blur/glow/motion on the longest scrolling surfaces.

### Should Fix Before Public Launch

- Rework analysis results into trust-first summary plus expandable details.
- Make About links real and version/build dynamic.
- Hide or complete all "Soon" and placeholder actions.
- Add camera framing guidance and stronger permission recovery.
- Polish reset-password handoff and callback result UX.
- Add a public-ready Backup & Sync screen that avoids provider-specific language.
- Verify large text scale, small-screen, and dark-mode contrast on real devices.

### Nice To Improve Later

- Add collector goals or milestones to make Portfolio more motivating.
- Add richer item imagery/fallbacks for sample scans.
- Add a compact edit-before-save review.
- Add skeleton states for network-backed analysis/pricing.
- Add optional reduced-motion behavior tied to platform accessibility settings.

## Recommended Next Implementation Sprint

1. `lib/features/scanner/presentation/pages/scanner_screen.dart`
   - Replace the current scan action row state logic with explicit `Select image`, `Analyze image`, and `Result ready` layouts.
   - Remove the low-opacity compatibility `Analyze with AI` button.
   - Treat camera/gallery cancellation as neutral.

2. `lib/features/scanner/presentation/widgets/scanner_widgets.dart`
   - Refactor `AiResultCard` into a trust summary section first: item title, value range, confidence, pricing source, last updated, and primary save CTA.
   - Move reasoning, alternatives, and comps into lower-priority sections.

3. `lib/features/portfolio/presentation/widgets/portfolio_widgets.dart`
   - Update `PortfolioGridTile` to render the saved image via existing local/network image helpers instead of `_PortfolioGridThumbnail`.
   - Move edit/share/delete into an overflow/menu pattern.

4. `lib/features/settings/presentation/settings_screen.dart`
   - Hide `_DeveloperToolsSection` outside debug/SIT builds.
   - Separate tappable actions from read-only status rows.
   - Remove public-facing Supabase/API/mock wording from default settings copy.

5. `lib/features/onboarding/presentation/onboarding_screen.dart`
   - Rewrite the "Analyze" and "Local-first" text for user value.
   - Make `Start Scanning` the primary first-run route and simplify the dashboard alternative.

6. `lib/core/ui/scan/scan_ui.dart`, `lib/core/widgets/glass_card.dart`, `lib/core/widgets/gradient_header.dart`, `lib/core/ui/motion/motion_widgets.dart`
   - Introduce a calmer surface variant without blur/glow for repeated list sections.
   - Respect platform reduced-motion settings before starting ambient/pulse/repeating animation controllers.

7. `lib/features/about/presentation/about_screen.dart`
   - Source version/build from package metadata.
   - Replace placeholder link snackbars with real URL launches or hide links until available.

## Verification

Verification commands requested:

- `flutter analyze`: passed. `No issues found!`
- `flutter test`: passed. `362` tests completed.

Both commands resolved dependencies first and reported that 23 packages have newer versions incompatible with current dependency constraints. This did not block analysis or tests.

## Code Change Status

No Flutter app code was changed for this audit. This document is the only intended artifact.
