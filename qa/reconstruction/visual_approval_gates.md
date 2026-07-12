# Visual approval gates

Allowed statuses: `planned`, `design_ready`, `implementation_in_progress`, `runtime_ready`, `awaiting_visual_review`, `revision_required`, `approved`, `frozen`, `superseded`.

Promotion requires, in order: Studio composition or approved source → implementation → focused tests → full suite → `flutter analyze` → SIT build → clean Samsung install → fresh screenshot + hierarchy capture → functional smoke → design review → product-owner review → explicit `approved` → explicit `frozen`. Evidence records device/model, OS, build commit, flavour, date, source revision and reviewer. Build/test success can reach only `runtime_ready`; it never implies visual approval.

