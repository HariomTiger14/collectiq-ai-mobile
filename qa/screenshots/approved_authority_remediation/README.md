# Approved Authority Remediation Evidence

This directory is the evidence skeleton for future coordinated visual remediation. No screenshots, comparisons, logs, or hierarchy dumps were generated for this planning task.

## Screens

- `shared/`: shared foundations, sheets/dialogs, App Shell integration, token/surface evidence.
- `home/`: Home authority remediation evidence.
- `portfolio/`: Portfolio authority remediation evidence.
- `detail/`: Detail authority remediation evidence.
- `scanner/`: Scanner authority remediation evidence.
- `integration/`: cross-screen QA, tab switching, scroll stress, and final freeze evidence.

## Subfolders

Each screen folder uses:

- `before/`: current runtime evidence before a remediation phase.
- `approved/`: copied approved crop references or reference index files.
- `after/`: runtime evidence after implementation.
- `comparison/`: side-by-side approved-vs-runtime comparisons.
- `logs/`: Android logcat, command output summaries, and validation notes.
- `hierarchy/`: XML/UI hierarchy dumps and semantic inspection notes.

## Naming Convention

Use two-digit ordering and state names:

- `01_<state>_before.png`
- `01_<state>_before.xml`
- `01_<state>_after.png`
- `01_<state>_after.xml`
- `01_<state>_approved.png`
- `01_<state>_comparison.png`
- `01_<state>_logcat.txt`

Every evidence set should record device model, Android version/API, viewport, density, text scale, theme, branch, commit, approved authority path, and validation date.
