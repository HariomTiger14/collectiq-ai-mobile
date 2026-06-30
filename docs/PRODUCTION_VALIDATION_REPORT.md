# CollectIQ AI Production Validation Report

- Generated: 2026-07-01T00:17:41.8548099+10:00
- Duration: 00:03:32.3218356
- Report source: `scripts/run_production_validation_dashboard.ps1`
- Validation manifest: `C:\Users\hario\Desktop\projects\collectiq_ai\validation\manifests\sample_manifest.json`
- Validation endpoint: `http://127.0.0.1:8000/api/analyze`

## Executive Summary

- Overall readiness score: **75 / 100**
- Recommendation for beta: **Conditionally ready for closed beta after resolving high-priority validation gaps.**

## Validation Dashboard

| Metric | Current Status |
| --- | --- |
| AI accuracy | No images available |
| Pricing provider agreement | No images available |
| Average confidence | No images available |
| Average latency | No images available |
| Sync success rate | Covered by Flutter sync tests; live Supabase rate requires configured project run. |
| Billing status | Google Play Billing foundation tested; production products require Play Console setup. |
| Crash-free sessions | Telemetry/Crashlytics integration available; live crash-free sessions require Firebase configuration and beta traffic. |
| Backend health | PASS |
| Test status | Flutter: PASS; Backend: PASS |
| Release readiness | Android builds: PASS |

## QA Lanes

| Lane | Status | Notes |
| --- | --- | --- |
| flutter_quality | PASS |  |
| backend_quality | PASS |  |
| validation_lab | PASS |  |
| android_builds | PASS |  |

## Critical Blockers

- None from automated local validation.

## High-Priority Fixes

- Run Validation Lab with licensed/user-owned collectible images to measure AI accuracy.
- Run backend in real-provider mode locally to measure pricing provider agreement.

## Evidence

- Flutter QA summary: `build/test_reports/production_validation/flutter_quality_summary.md`
- Backend QA summary: `build/test_reports/production_validation/backend_quality_summary.md`
- Validation Lab report: `validation/reports/latest_validation_report.md`
- Android build summary: `build/test_reports/production_validation/android_builds_summary.md`

## Notes

- Automated validation runs in mock/default mode and does not call paid OpenAI/eBay/TCGPlayer/PriceCharting APIs.
- Real AI accuracy and pricing agreement require manual/local validation with configured backend providers and licensed or user-owned images.
- Crash-free sessions are not a local metric; they become meaningful after Firebase Crashlytics is configured and beta testers generate sessions.

