# Scanner Phase 4 Contract Clarifications

Date: 2026-07-14

## Scope

Phase 4 reopens only Scanner visual alignment against the approved Volume 03 Scanner authority.

No changes were made to Home, Portfolio, Detail, Settings, Search, Notifications, App Shell architecture, backend, auth, routing, Product Language definitions, or Capture System definitions.

## Preserved Contracts

- Scanner controller ownership remains unchanged.
- Camera lifecycle remains `CameraService` owned.
- `captureImages`, `selectedImagePath`, and `primaryImagePath` semantics are unchanged.
- Gallery, lost-picker recovery, multi-image ordering, review, original and AI Enhance choices, analyzer payload, result rendering, Portfolio handoff, local persistence, and App Shell lifecycle remain unchanged.
- Capture System v1 remains candidate material only and was not promoted.
- No Search tab or new Scanner behavior was introduced.

## Visual Decisions

- S01 Scan Hub remains the strongest direct authority match and keeps the approved action order.
- S02 Camera now uses the shared Scanner dark visual theme, bounded viewfinder, bottom shutter row, and concise guidance.
- S04 Review Photo keeps Original and AI Enhance actions while adopting the approved dark review surface.
- S05-S07 Workspace states keep the existing capture plan behavior while compacting the active preview and filmstrip to better match the approved authority.
- S09-S10 Result and Save states keep existing result data while adding the approved saved confirmation treatment in Scanner result surfaces.

## Product Honesty

Phase 4 did not add fabricated readiness, confidence, provider status, pricing, percentages, or analysis progress. Runtime result values still come from the existing mock/local analyzer path used by the project.
