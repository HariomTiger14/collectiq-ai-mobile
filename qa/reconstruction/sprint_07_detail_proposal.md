# Sprint 07 Detail proposal

Status: proposal only. Sprint 07 is not started by this document.

Branch: `rebuild/product-language-v1`

Proposed sprint title: Detail Presentation Reconstruction

## Proposed scope

Sprint 07 should own only the existing collectible Detail screen presentation if separately approved.

Potential presentation ownership:

- Detail header and visual hierarchy;
- primary image and gallery carousel presentation;
- gallery thumbnail states and image-count presentation;
- value, confidence, category, market summary, and partial-data presentation;
- notes and profile editing presentation around existing actions;
- delete confirmation presentation;
- favorite/wishlist presentation only where existing state supports it;
- empty/missing optional-field states;
- responsiveness, accessibility, and performance for Detail routes.

## Required preservation

Sprint 07 must preserve:

- Portfolio item identity;
- `CollectibleItem` serialization and gallery data;
- primary-image ownership;
- existing Detail route entry from Portfolio and Home;
- edit, update, delete, notes, favorite, and gallery callbacks;
- Portfolio repository/controller ownership;
- scanner-to-portfolio saved data;
- backend, analyzer, Supabase, cloud sync, and native contracts;
- frozen Sprint 01-06 behaviour.

## Explicit non-goals

- no Portfolio reconstruction;
- no Scanner reconstruction;
- no Settings reconstruction;
- no Authentication redesign;
- no Home redesign;
- no App Shell redesign;
- no backend/Supabase contract change;
- no analyzer contract change;
- no data migration;
- no router migration;
- no speculative marketplace, sharing, or export workflow;
- no Sprint 07 implementation without explicit approval.

## Validation expectation

If approved, Sprint 07 should include focused Detail tests, frozen Sprint 01-06 regression suites, full-suite comparison against the Sprint 06 ceiling of 534 passed and 16 failed, Android local debug build, physical-device Detail runtime evidence, log capture, and a freeze record only after runtime approval.
