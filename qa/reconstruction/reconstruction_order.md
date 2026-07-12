# Reconstruction order

1. Phase 0: App Bootstrap and Entry Routing Presentation. Preserve async startup, onboarding flag, guest/signed-out local access, auth behaviour, and password recovery; add focused first/following launch, error/offline tests; Samsung clean-install evidence; commit `feat: reconstruct PackLox bootstrap and entry presentation` after approval.
2. Phase 1: ONB-01 onboarding presentation. Preserve controller calls, `onboarding_completed_v1`, Start Scan and Explore Dashboard destinations; one approved screen per commit.
3. Phase 2: SHELL-01..04 and SYS-01. Prerequisites: shell/nav/system-state families. Preserve tab indices and scanner active-session behavior; navigation/accessibility/golden tests; Samsung system-bar validation.
4. Phase 3: AUTH-01..06 account access. Prerequisites: auth field/status component approvals plus callback contract decision. Preserve session/deep links; test all auth states; authentication remains outside app entry.
5. Phase 4: HOME-01. Prerequisites: dashboard/card/list/data-state families and product contract; preserve portfolio/history callbacks.
6. Phase 5: SCN-01..07. Keep S01 frozen; begin implementation work at S02 only after entry phases. Preserve controller/session/permission/camera/gallery behavior; device validation is mandatory.
7. Phase 6: SCN-08..10 analysis/result/save. Preserve analyzer and persistence contracts; network/error/result tests.
8. Phase 7: PORT-01 then DETAIL-01. Preserve repository/image/cloud behavior; migration and destructive-action tests.
9. Phase 8: SEARCH-01, NOTIF-01, SET-01. Search/notification require product and route contracts before UI implementation; Settings follows auth extraction.

Router migration is out of scope for Phase 0 unless implementation evidence proves the existing navigation structure prevents safe reconstruction.

Every item requires: approved prerequisite components/product contract; presentation-only scope; focused + full tests; analyze; SIT build; Samsung clean install/screenshots/hierarchy/smoke; design and owner approval; explicit status; one focused commit. Gate statuses and template are linked from the README.
