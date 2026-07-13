# Phase 0 Shared Foundations Implementation Notes

Date: 2026-07-13
Branch: rebuild/product-language-v1
Starting HEAD: 3e51ee734990f8ee0ff009d2bf7561788f7af72d
Scope: Shared Visual Foundations Remediation only.

## Current Ownership Trace

| Foundation | Current source | Notes |
|---|---|---|
| App background | `lib/core/theme/app_theme.dart`, screen scaffolds, `PackLoxTokens.background` | Home, Portfolio, and Scan Hub already pin dark roots locally; shared Material dark defaults previously came from seeded Material colors rather than approved PackLox surfaces. |
| Raised surface | `AppTheme` color scheme, `AppElevation`, screen-local containers, Product Language primitives | Product Language tokens define approved `surface` and `surfaceRaised`; theme-level Card/default surfaces did not consistently use them. |
| Elevated surface | `AppTheme`, `AppElevation.level1/2/3`, local cards | Elevation shadows are shared primitives; Phase 0 configured default Card/SnackBar surfaces without changing screen-specific card hierarchy. |
| Modal surface | `showModalBottomSheet` call sites plus `ThemeData.bottomSheetTheme` | Portfolio sheets already use transparent modal backgrounds and a local sheet surface; shared default modal sheet theme now uses approved dark raised surface. |
| Dialog surface | `AlertDialog` call sites plus `ThemeData.dialogTheme` | Portfolio and Detail delete confirmations use standard `AlertDialog`; shared dialog theme now prevents default light/seeded leakage. |
| Header surface | `PackLoxHeader` | Header does not own a `SafeArea`; parent screen scaffolds own system insets. No Header content or Product Language definition was changed. |
| Sheet scrim | `showModalBottomSheet` call sites and `BottomSheetThemeData.modalBarrierColor` | Existing call sites may still override scrim; default theme now supplies a dark approved scrim. |
| Border colours | `PackLoxTokens.border`, `ColorScheme.outlineVariant`, local borders | Dark theme now maps outlines to `PackLoxTokens.border`. |
| Shadow/elevation | `AppElevation`, Theme card/sheet/dialog/snack shadows | Defaults now use dark-safe shadows and transparent Material surface tint. |
| Dark-theme defaults | `AppTheme.dark` | Replaced seeded Material surface defaults with explicit approved PackLox dark board tokens. |
| Light-theme defaults | `AppTheme.light` | Light scaffold background remains `AppColors.canvas`; shared card/sheet/dialog themes use existing light tokens. |

## Implemented Corrections

- Dark `ColorScheme.surface` and `scaffoldBackgroundColor` now map to `PackLoxTokens.background`.
- Dark raised/elevated Material defaults now map to `PackLoxTokens.surfaceRaised`.
- Default `CardThemeData`, `BottomSheetThemeData`, `DialogThemeData`, `DividerThemeData`, `InputDecorationTheme`, and `SnackBarThemeData` are configured to avoid default white or seeded Material leakage.
- Material surface tint is disabled for shared app bars, cards, sheets, and dialogs so dark surfaces do not brighten unexpectedly.
- Non-scanner App Shell system bars now use light icons over the approved dark background and preserve the four-tab shell.
- Header SafeArea ownership remains parent-owned; no duplicate SafeArea was introduced.
- Bottom navigation SafeArea ownership remains inside `GlassBottomNavBar`; gesture and three-button bottom insets remain preserved by `SafeArea`.

## Classification

| Changed treatment | Classification | Reason |
|---|---|---|
| `AppTheme.dark` surface mapping | B. Approved primitive composition correction | Existing approved Product Language tokens were mapped into shared Material primitives. |
| Card/default raised surface theme | C. Shared Flutter implementation correction | Prevents Material defaults from leaking unapproved surfaces. |
| Bottom sheet theme | C. Shared Flutter implementation correction | Provides approved dark default surface/scrim without changing sheet content or callbacks. |
| Dialog theme | C. Shared Flutter implementation correction | Provides approved dark default surface without changing dialog behaviour. |
| Divider/input/snack defaults | C. Shared Flutter implementation correction | Keeps shared Material defaults inside the dark board language. |
| App Shell system overlay | C. Shared Flutter implementation correction | Aligns system UI icon/background treatment with the dark App Shell surface without changing navigation. |
| Product Language tokens/components | No change | Phase 0 did not create, redesign, or promote Product Language components. |

## Deferred Product Language Gaps

No D-class Product Language gap was implemented in this phase. Shared empty/no-results states, overlay matrices, Detail tabs, Scanner Capture System, Portfolio item-card semantics, and Search navigation remain deferred to product/design clarification or screen-specific phases.

## Screen-Specific Deferrals

- Home hierarchy, empty-card content, sample action, categories, populated states, and no-valuation states remain Phase 1.
- Portfolio summary hierarchy, search visibility, sort/filter content, item cards, and populated/no-results states remain Phase 2.
- Detail header replacement, tabbed structure, gallery, valuation, AI, notes, and actions remain Phase 3.
- Scanner camera, workspace, review, analysis, result, and save confirmation alignment remain Phase 4.

## Validation Plan

Focused tests are in `test/shared_visual_foundations_test.dart`. Runtime evidence should be captured under `qa/screenshots/approved_authority_remediation/shared/` and must be read as shared-foundation evidence only, not screen-level authority alignment.
