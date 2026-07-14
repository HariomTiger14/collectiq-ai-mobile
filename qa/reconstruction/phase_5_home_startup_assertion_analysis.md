# Phase 5 Home Startup Assertion Analysis

Date: 2026-07-14
Branch: rebuild/product-language-v1
Starting HEAD: aa65d03483c2d64bcf1ac9b4491557a73dccccee
Scope: diagnostic evidence only; no Home source or business logic changes were made.

## Result

The Phase 4-reported Home debug startup assertion was not reproduced during the Phase 5 physical-device pass using the installed local debug package (`com.collectiq.ai.local`) on Samsung SM-E625F, Android 13/API 33.

Tested sequence:
- `pm clear com.collectiq.ai.local`
- cold launch into onboarding
- complete onboarding into Home
- Home, Portfolio, Scan Hub, Scanner workspace, Scanner result, save confirmation, populated Portfolio, Detail, Android back
- repeated Home/Portfolio/Scan switching
- Detail open/back
- Portfolio scroll
- Android home background and foreground relaunch

Evidence:
- `qa/screenshots/approved_authority_remediation/integration/home/phase5_cold_launch.png`
- `qa/screenshots/approved_authority_remediation/integration/home/phase5_home_after_onboarding_final.png`
- `qa/screenshots/approved_authority_remediation/integration/shared/phase5_post_stress.png`
- `qa/screenshots/approved_authority_remediation/integration/logs/phase5_integration_logcat.txt`
- `qa/screenshots/approved_authority_remediation/integration/logs/phase5_logcat_app_marker_scan.txt`

## Log Assessment

No app-attributable `FATAL EXCEPTION`, `E/flutter`, `RenderFlex`, overflow, ANR, OOM, `Process: com.collectiq.ai.local`, or app force-finish stanza was found for the tested ADB runtime path. The broad marker scan is noisy because Android system components include unrelated scan/anr strings; the app-focused scan did not show a CollectIQ crash or Flutter assertion.

## Classification

Status: not reproduced in Phase 5 ADB-installed debug-package runtime.

The prior observation remains classified as a debug-console-only or tooling-path observation until an exact Flutter console stack is captured. Flutter console reproduction was blocked during this pass by a temporary Flutter wrapper/tooling hang, then recovered for tests. No narrow production fix was applied because the runtime evidence did not reproduce a user-visible Home defect and no exact owning stack was available.
