# Git strategy

Use `rebuild/product-language-v1` as the integration branch created from committed baseline `c6bf080`. Because the current main worktree is dirty, create a separate worktree after current work ownership is resolved; do not switch this directory. Optional branches `rebuild/<screen-id>-<slug>` start from the integration branch and merge only after runtime approval.

Use one screen-sized commit per approved screen and explicit path staging (`git add -- qa/reconstruction/... docs/PACKLOX_FRONTEND_RECONSTRUCTION_PLAN.md` for this audit; analogous exact presentation/test/evidence paths later). Never broad-stage. Keep generated, backend and unrelated QA changes outside commits. Prefer reviewed no-ff merges or cherry-picks into integration, then a reviewed integration merge to main. Roll back by reverting the focused screen commit. Tag frozen milestones such as `plx-rebuild-phase0-frozen`. Push only after local validation and owner authorization; nothing was pushed in this sprint.

This audit cannot safely commit in the current worktree until its documentation can be isolated from the pre-existing untracked `docs/`/`qa/` estate and branch ownership is confirmed.

