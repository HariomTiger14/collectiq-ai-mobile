# Detail Approved Visual Contract

Date: 2026-07-13
Authority: `C:/Users/hario/Desktop/projects/packlox-design-platform/releases/v1.0/design_bible/Volume_07_Collectible_Detail/images/collectible_detail_flow_master.png`
Runtime device: Samsung SM E625F, Android 13 / API 33, `RZ8R213M8ZL`
Runtime evidence: `qa/screenshots/approved_authority_recovery/detail/current_runtime/`

## 1. Authority Identity

Primary authority is Design Bible v1.0 `Volume_07_Collectible_Detail`, master file `collectible_detail_flow_master.png`, imported 2026-07-11 from `collectible detail flow.png`. The master image is 1536x1024, SHA256 `9fb59e44d860b17b9c3e5671062857087543ef2614b7987625dac6e2c0d924b7`.

## 2. Approval And Freeze Evidence

The release manifest records Design Bible v1.0 as an approved release with 11 master images and 96 extracted application screens. The Detail visual inventory status is Approved contractual reference. The volume README states the master board is contractual and must not be treated as inspiration. This is sufficient freeze evidence for visual authority; current Flutter Detail conformance is not proven.

## 3. Target Viewport

Approved crops are bounded mobile references, 137x368 for S01 through S09 and 165x368 for S10. Runtime evidence was captured at 1080x2400 physical pixels with density 450. Remediation must preserve approved proportions after responsive scaling, not absolute crop pixel dimensions.

## 4. Root Background

Approved Detail uses a dark product-board root. Runtime uses `Scaffold(backgroundColor: colorScheme.surface)` and app theme surfaces. Remediation must ensure the Detail root reads as the approved dark Detail surface and must not inherit a light or generic Material surface.

## 5. Safe Areas

Approved crops keep content inside mobile safe bounds with a compact header/detail tab system. Runtime evidence shows status bar height 92px and content beginning under a standard app bar at about y=250 on Detail. Remediation must account for Android status and gesture bars without changing the approved vertical hierarchy.

## 6. Header Placement And Content

Approved Detail uses the board-specific Detail header treatment and persistent Detail navigation. Runtime uses a standard Material `AppBar` titled `Collectible Details` plus an embedded `PackLoxHeader` reading `Collectible record` and `Detail`. Remediation must remove the duplicate/generic header stack and use the approved Detail header hierarchy.

## 7. Image Hero And Gallery Placement

Approved S01/S02 place the collectible hero and gallery as part of a compact Detail flow. Runtime first viewport uses a large rounded hero card with a 16:11 image surface and a filmstrip below it. The runtime treatment is functionally rich but visually not board-equivalent.

## 8. Hero Dimensions

Approved hero proportions must follow S01/S02 after scaling. Runtime hero consumes a large share of the first 1080x2400 viewport. Remediation should size the hero according to the approved crop proportions and preserve title/value/tabs visibility in the first viewport.

## 9. Image Aspect Ratio

Runtime uses a fixed 16:11 `AspectRatio`. The approved crop controls image treatment visually and may not be exactly 16:11. Remediation must derive the final ratio from S01/S02, not from the current widget.

## 10. Primary Image Treatment

Approved primary image treatment is integrated into the Detail board. Runtime uses `buildLocalPortfolioImage`, placeholders for `sample://`, rounded card clipping, and optional AI-enhanced badge. Retain robust local/network/sample behavior but restyle the surface to match the approved crop.

## 11. Thumbnail Strip

Approved S02 includes gallery/thumbnail behavior as part of the Detail visual system. Runtime exposes a horizontal filmstrip immediately under the hero. Retain multi-image selection and primary image updates, but resize and restyle thumbnails to match S02.

## 12. Full-Screen Review

Approved S02 covers Image Gallery. Runtime full-screen review is a dark modal/dialog with index, primary state, edit/delete/use-primary actions. Because the approved crops do not separately show the Flutter modal, keep the behavior but align chrome, spacing, and action hierarchy to the approved gallery vocabulary.

## 13. Image Count

Approved S02 visually represents a gallery state. Runtime seed captured a three-image item. Remediation must preserve image count semantics and make count/selected-state visible only where approved.

## 14. Item Identity And Title

Approved S01 places item identity in the overview hierarchy. Runtime first viewport shows category/confidence/rarity chips, title, match label, and value inside a large card. Remediation must move identity into the approved overview hierarchy and avoid over-weighted chip rows if not present on the board.

## 15. Category And Metadata

Approved S03 Details & Info and S06 Condition use structured attribute rows. Runtime uses chip wraps and linear cards under `Key Attributes`. Remediation must map runtime fields to approved rows/sections without losing year, set, rarity, material, character, condition, or confidence.

## 16. Valuation Section

Approved S04 Market & Value controls value badge, market value layout, and trend/chart presentation. Runtime displays `$1,850` in the hero and later saved market/evidence sections. Remediation must move valuation into the approved S04 hierarchy and distinguish summary value from evidence and history.

## 17. Unavailable Valuation

The approved Detail crop list does not include a separate unavailable valuation state. Runtime minimal item shows `$0` for an item with `valuationStatus: unavailable`. Remediation must not present unavailable valuation as a true zero value; it should adapt S04 with explicit unavailable copy.

## 18. Zero Valuation

Zero value must be treated differently from unavailable. Runtime seed exposes a zero displayed value on the minimal item, but the source status is unavailable. A future zero-value fixture must validate true zero separately.

## 19. Stored AI Evidence

Approved S05 AI Insights controls the AI card and confidence-ring treatment. Runtime shows `AI Review`, reasoning, confidence explanation, and detection quality in a linear card. Retain stored AI evidence but replace the composition with S05 AI insight card and confidence-ring styling.

## 20. Missing AI Evidence

Approved crops do not separately show missing AI evidence. Runtime did not expose a distinct missing-AI Detail state beyond minimal sparse data. Remediation should define an S05-compatible empty AI adaptation before implementation.

## 21. Notes Section

Approved S09 Notes & Tags controls notes field and tag chips. Runtime uses a large `Notes` section with editable text and `Save notes`. Retain edit/persist behavior, but align field, save affordance, and tag chip placement to S09.

## 22. Favorite

Approved S10 Actions Menu controls action hierarchy. Runtime exposes Favorite as a large button in the body action section and snack feedback. Remediation should place favorite where S10/action hierarchy expects it and preserve feedback without visual over-weighting.

## 23. Share

Runtime Share currently shows `Sharing coming soon`. Approved S10 includes action menu behavior. Remediation should preserve disabled/coming-soon semantics if the feature is incomplete, but style and placement must follow S10.

## 24. Delete

Runtime Delete opens a standard Material `AlertDialog`. Approved S10 covers actions menu but not a separate confirmation dialog. Confirmation may remain an allowed runtime adaptation, but its surface, copy, destructive hierarchy, and dark treatment should be aligned with the approved system.

## 25. Action Hierarchy

Approved actions are menu/system actions. Runtime uses large body buttons: Edit full-width, Share/Favorite split, Delete separate. Remediation should reduce body action dominance and follow S10 menu ordering and destructive separation.

## 26. First Viewport

Approved S01 should show a compact overview and enough of the tabbed Detail structure. Runtime first viewport is dominated by a large hero and standard app bar. This is a non-negotiable mismatch.

## 27. Section Order

Approved order is progressive disclosure through bottom detail tabs: overview, gallery, details, market, AI, condition, similar items, price history, notes/tags, actions. Runtime order is hero, low confidence, AI, attributes, notes, actions, wishlist, detail sections, price alerts, similar items. Remediation must restore approved state/tab order.

## 28. Typography

Approved typography is whatever is visible in the v1.0 crop set. Runtime uses Material text theme, `headlineSmall`, labels, and large chip text. Remediation must map to Product Language tokens only where they reproduce the approved crop scale and weight.

## 29. Colour And Token Mapping

Approved Detail is dark. Runtime has dark root in app theme but uses generic `surface`, `surfaceContainerHighest`, outlines, and some light Material dialog behavior. Use Product Language tokens only after matching the approved dark surfaces, accents, value treatments, and destructive colors.

## 30. Surface Mapping

Approved surfaces are compact dark Detail panels and state cards. Runtime surfaces are large rounded Material cards and dialogs. Remediation must replace incompatible surfaces, not just recolor them.

## 31. Radius

Runtime uses `AppRadius.xl` and many 16-22px radii. Approved crop radii must be measured visually and expressed as Product Language radius tokens. Avoid oversized rounded surfaces where the approved crop uses tighter panels.

## 32. Elevation

Runtime uses `AppElevation.level2` and shadowed cards. Approved Detail appears flatter and darker in the crops. Remediation should reduce or reassign elevation according to the board.

## 33. Iconography

Runtime uses Material icons for edit, share, favorite, delete, category, verified, style placeholder. Approved iconography must be taken from the crop and Product Language icon set. Icons may be retained only if visually equivalent.

## 34. Spacing

Runtime spacing is `AppSpacing.lg` between most sections with 45px horizontal screenshot margins. Approved crops are denser. Remediation should measure section gaps from S01-S10 and avoid the current long-scroll expansion.

## 35. Alignment And Grid

Approved states use a compact mobile grid with tabbed sections. Runtime centers content in a max-width 960 container with long vertical stacking. Remediation must restore the approved mobile grid and tab alignment.

## 36. Scroll Behaviour

Approved Detail uses persistent detail tabs and state-specific scroll surfaces. Runtime uses one `CustomScrollView` with all sections in a single column. Behavioural scroll must be reworked to preserve data/actions while matching approved tabs.

## 37. Responsive Rules

Runtime adjusts horizontal padding below 360, below 600, and otherwise 20. Approved crops are mobile references. Responsive adaptation is allowed for larger screens only after the mobile contract is matched.

## 38. Accessibility

Runtime has semantic labels for image preview, nav, actions, and portfolio items. Remediation must preserve accessible names, button roles, focus order, and text scale support while changing visuals.

## 39. Motion

Runtime uses animated switchers, hero update animation, reveal, tap scale, and possible shimmer. Approved notes allow motion only when it does not change hierarchy. Remediation must disable or retune motion that conflicts with the board.

## 40. Approved Components

Visible approved components include Collectible hero, Image gallery, Thumbnail grid, Attribute row, Value badge, Trend chart, AI insight card, Confidence ring, Condition bar, Similar-item card, Chart/table toggle, Notes field, Tag chip, Actions menu, and Bottom detail tabs.

## 41. Primitive Compositions

Product Language primitives may be used only to reproduce the approved components. Generic Header, Hero, EntryTile, Material AppBar, and large body action buttons are not automatically approved whole-screen compositions.

## 42. Candidate Components

Candidate Flutter components include `_PremiumDetailHero`, `_DetailGalleryFilmstrip`, `_AiSummarySection`, `_KeyAttributeChipsSection`, `_NotesCard`, `_DetailActionSection`, `_DetailSections`, `_PriceAlertSection`, `_SimilarCollectiblesSection`, and `_PortfolioGalleryReview`. Most need reconfiguration or replacement.

## 43. Prohibited Legacy Elements

Do not retain the duplicate standard AppBar plus PackLoxHeader stack, large generic body action buttons, long-scroll-only structure, light/default dialogs, or `$0` display for unavailable valuation if those conflict with the approved Detail board.

## 44. Allowed Runtime Adaptations

Allowed adaptations: Android safe-area inset handling, local debug image placeholders, confirmation dialog for destructive delete, inaccessible external share disabled state, missing-image fallback, and unavailable valuation copy, provided they follow the approved dark Detail system.

## 45. Non-Negotiable Visual Requirements

Use the approved Detail master and ten crops as the whole-screen authority. Restore dark Detail root, compact overview, approved gallery, approved value/AI/notes/actions states, and persistent bottom detail tabs. Do not claim visual freeze until direct comparison evidence passes.

## 46. Behavioural Contracts Preserved

Preserve Portfolio entry/return, multi-image gallery switching, full-screen review, use-primary, delete safeguards, edit dialog, notes persistence, favorite state feedback, share disabled feedback, delete confirmation, valuation status semantics, and local-only debug seeding boundaries.

## 47. Evidence Requirements

Future remediation must include approved-vs-runtime comparisons for S01-S10, runtime screenshots/XML on `RZ8R213M8ZL`, logcat crash scan, focused Detail tests, and confirmation that no Home/Portfolio visual regressions occurred.

## 48. Acceptance Criteria

Detail visual freeze can be reinstated only when runtime first viewport, gallery, details, market/value, AI insights, condition, similar items, price history, notes/tags, and actions match the Design Bible v1.0 authority or any intentional difference is separately approved and recorded.
