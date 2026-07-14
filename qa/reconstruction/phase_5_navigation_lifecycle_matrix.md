# Phase 5 Navigation And Lifecycle Matrix

Date: 2026-07-14
Device: Samsung SM-E625F, Android 13/API 33, physical device RZ8R213M8ZL
Package: com.collectiq.ai.local

| Flow | Result | Evidence |
| --- | --- | --- |
| Clear app data then cold launch | Passed; app launched to onboarding without app-attributable crash | `home/phase5_cold_launch.png`, `hierarchy/phase5_cold_launch.xml` |
| Complete onboarding to Home | Passed; owner-approved Home rendered | `home/phase5_home_after_onboarding_final.png` |
| Home to Portfolio empty | Passed; Portfolio empty state visible | `portfolio/phase5_portfolio_empty.png` |
| Portfolio to Scan Hub | Passed; approved Scan Hub visible | `scanner/phase5_scan_hub.png` |
| Sample scan to workspace | Passed; one-photo workspace visible | `scanner/phase5_scanner_workspace.png` |
| Analyze sample scan | Passed; result rendered and save CTA visible | `scanner/phase5_scanner_result.png`, `scanner/phase5_scanner_save_area.png` |
| Save result | Passed; approved confirmation card visible | `scanner/phase5_scanner_saved_confirmation.png` |
| Return to Portfolio populated | Passed; saved item and total value visible | `portfolio/phase5_portfolio_populated.png` |
| Open Detail from Portfolio | Passed; approved Detail overview visible | `detail/phase5_detail_overview.png` |
| Android back to Portfolio | Passed; returned to Portfolio | `portfolio/phase5_detail_back_to_portfolio.png` |
| Repeated Home/Portfolio/Scan switching | Passed; no duplicated tabs, no blank shell | `shared/phase5_post_stress.png` |
| Background/foreground relaunch | Passed; app resumed to stable shell | `shared/phase5_post_stress.png` |

Log evidence: `qa/screenshots/approved_authority_remediation/integration/logs/phase5_integration_logcat.txt`.
