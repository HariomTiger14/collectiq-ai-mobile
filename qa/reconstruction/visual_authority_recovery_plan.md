# Visual Authority Recovery Plan

Date: 2026-07-13

## Group 1 - Authoritative Visual Reference Exists And Is Usable Now

Screens: Home, Scanner, Portfolio, Detail, Settings, Search, Notifications.

Next action: create board-to-runtime mapping reports and decide whether Flutter must remediate to Design Bible v1.0 or whether a Flutter-derived surface needs new approval.

Owner: design owner plus Flutter owner.

Expected artifact: per-screen mapping report with approved reference path, runtime screenshot path, deviations, and decision.

Approval step: product owner confirms whether v1.0 Design Bible remains binding or a new version is needed.

Freeze step: screen-specific freeze that references both design-platform authority and Flutter runtime comparison.

Flutter impact: runtime should remain unchanged until mapping identifies approved remediations.

Current runtime unchanged until approval: yes.

## Group 2 - Candidate Reference Exists But Needs Formal Approval/Freeze

Screens/states: Scanner Capture System beyond Scan Hub; Portfolio item cards and filter/sort controls; Detail gallery/lightbox, notes/actions, and metadata groups; shared dialogs, sheets, and overlays.

Next action: promote or reject candidate treatments through Design Studio approval workflow.

Owner: Design Studio owner and product owner.

Expected artifact: approval records, evidence manifests, and component/state specs.

Approval step: explicit product-owner approval record.

Freeze step: release under Product Language or screen-specific visual contract.

Flutter impact: defect fixes only until candidate status is resolved.

Current runtime unchanged until approval: yes.

## Group 3 - No Complete Screen Reference Exists; New Screen Design Required

Screens/states: Bootstrap transient/splash; exact three-stage reconstructed Onboarding; complete App Shell state matrix; cross-screen shared empty/loading/error matrix.

Next action: create new screen/state boards or formally exclude the state from visual freeze.

Owner: design owner.

Expected artifact: approved boards/crops and visual inventory.

Approval step: product-owner visual approval.

Freeze step: versioned release manifest or sprint freeze record that points to the approved board.

Flutter impact: pause visual redesign; keep current runtime unless a defect is found.

Current runtime unchanged until approval: yes.

## Group 4 - Reference Likely Exists Outside Repository And Must Be Imported/Versioned

Screens/states: any sprint decision that relied on prior chat images, uncommitted local images, external files, or screenshots embedded in discussion but absent from `packlox-design-platform` or `collectiq_ai_reconstruction`.

Next action: recover the external image, import it into the design platform, attach metadata, and record approval status. If it cannot be recovered, mark it non-authoritative.

Owner: product owner or design archive owner.

Expected artifact: versioned file in `packlox-design-platform` plus manifest and approval record.

Approval step: product-owner review.

Freeze step: add to a release manifest or create a new visual-authority version.

Flutter impact: do not implement from unrecovered references.

Current runtime unchanged until approval: yes.
