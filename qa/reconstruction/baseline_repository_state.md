# Repository baseline — 2026-07-12 AEST

| Repository | Branch | HEAD | State |
|---|---|---|---|
| Flutter | `main` (ahead of `origin/main` by 7) | `c6bf0808360fbe58363737f212b842bc60ab0d05` | Dirty: 0 staged; 34 tracked unstaged; extensive untracked assets/design/docs/QA evidence |
| Engineering Platform | `master` | `f286dd8120dc8322f50097a00b9300dc83595042` | Clean |
| Standalone backend | `main` | `5cf8b9392130017a3550ea0988427fdfdc200bab` | Clean |

Product Language release commit `2995e1a` is available in the platform history. Validated Scanner S01 commit `c6bf080` is the Flutter HEAD.

## Safety decision

`rebuild/product-language-v1` does not exist locally in the inspected repositories. No matching remote-tracking branch is present. It was **not created**: switching/branching in a worktree containing scanner, analyzer, portfolio, generated registrant, embedded-backend and QA changes would mix ownership and make the branch baseline ambiguous.

Safe prerequisite: identify the owner/status of every current Flutter change, commit each coherent body to its intended branch or copy the committed `c6bf080` baseline into a separate Git worktree, then create with `git switch -c rebuild/product-language-v1 c6bf0808360fbe58363737f212b842bc60ab0d05`. Prefer the separate-worktree approach because it preserves the current directory byte-for-byte. Do not stash, reset, clean, restore, or broadly stage.

Unrelated protected work includes all current tracked changes, `assets/`, `design/`, `docs/PACKLOX_CURRENT_STATE_AUDIT.md`, and the existing `qa/` evidence trees. `git diff --check` reported no whitespace errors (only line-ending warnings). No push occurred.

