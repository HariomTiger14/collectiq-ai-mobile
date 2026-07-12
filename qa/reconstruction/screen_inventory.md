# Screen and state inventory

This is an implementation inventory, not a claim that every Design Bible screen already exists. Route values are canonical contracts: `home` means `MaterialApp.home`; `tab:n` means shell state; `push`/`modal` are direct Navigator operations; `missing` means planned-only. Product Intelligence mapping is currently available only for Scanner S01 (`PLX-V03-S01`). Approved PL components for all rows are Header 1.0.1, Hero 1.0.1, Entry Tile 1.0.0 and Button System 1.0.0; other families are gaps.

| ID | Journey/state | Route/widget | Owner/dependencies | Bible / PI | Visual / functional / tests | Priority / risk / evidence |
|---|---|---|---|---|---|---|
| BOOT-01 | native launch | OS launch theme | Android/iOS config | V00 / none | legacy / works / none | P0 high / runtime yes |
| BOOT-02 | initialization | `home` loading scaffold in `AppShell` | onboarding provider/preferences | V00 / none | generic / works / shell tests | P0 medium / yes |
| BOOT-03 | offline init | shared with BOOT-02 | cloud startup no-op | V00 / none | missing distinct state / fallback works / partial | P0 medium / limited |
| BOOT-04 | fatal config | missing | bootstrap/config | V00 / none | missing / safe fallback only / config tests | P0 high / no |
| ONB-01 | welcome/features/permissions/dashboard entry | `home` `OnboardingScreen` (single scroll screen) | onboarding controller/preferences; scanner/shell callbacks | V01/V00 / none | legacy / works / onboarding tests | P0 medium / Samsung evidence |
| AUTH-01 | sign in | `tab:3` `AuthAccessPanel` | auth controller/repository/Supabase | V01 / none | legacy embedded panel / works / auth+settings | P1 high / yes |
| AUTH-02 | sign up | same panel/state | same | V01 / none | no separate screen / works / auth | P1 high / yes |
| AUTH-03 | email verification | Settings message only | deep-link coordinator/controller | V01 / none | no route / callback works / deep-link tests | P1 high / diagnostics |
| AUTH-04 | forgot password | Settings panel action | auth controller/Supabase | V01 / none | no separate screen / dispatch works / auth | P1 high / yes |
| AUTH-05 | reset/expired recovery | mobile `missing`; PackLox HTTPS web page exists | web auth page + Supabase contracts | V01 / none | mobile recovery intentionally ignored; web update flow works / web auth tests | P1 high / web evidence |
| AUTH-06 | sign-out confirmation | `missing` (direct action) | auth controller | V01 / none | missing / sign-out works / auth | P1 medium / yes |
| AUTH-07 | guest/local mode | implicit shell access | environment/auth | V01 / none | no dedicated screen / active / auth | P0 high / yes |
| SHELL-01 | Home tab/global nav/system bars | `tab:0` `AppShell` + `HomeScreen` | shell controller | V00,V02 / none | mixed legacy / works / shell+home | P2 high / yes |
| SHELL-02 | Portfolio tab | `tab:1` `PortfolioScreen` | portfolio controller/repos | V06 / none | legacy / works / portfolio | P6 high / yes |
| SHELL-03 | Scan tab | `tab:2` `ScanHubPage` | scanner controller/services | V03 S01 / PLX-V03-S01 | approved S01 / works / focused tests | frozen baseline / Samsung yes |
| SHELL-04 | Settings tab | `tab:3` `SettingsScreen` | many settings/auth/cloud providers | V10 / none | legacy / works / settings | P7 high / yes |
| HOME-01 | dashboard populated/empty/loading/error | `tab:0` `HomePage` via `HomeScreen` | portfolio/history/insights | V02 / none | legacy/mixed / works / home tests | P3 high / QA yes |
| SCN-01 | S01 scan hub | `tab:2` `ScanHubPage` | scanner controller | V03 S01 / PLX-V03-S01 | PL v1 approved / works / S01 tests | preserve/frozen / strong |
| SCN-02 | camera | `push` `CameraCapturePage` | `CameraService`, permissions | V03 S02 / none | dirty candidate / works / camera tests | P4 critical / Samsung yes |
| SCN-03 | guidance | camera overlay/widgets | scanner/capture plan | V03 S03 / none | embedded state / works / partial | P4 high / yes |
| SCN-04 | review photo | `push` `ImageEnhancementPreviewPage` | enhancement service | V03 S04 / none | dirty candidate / works / tests | P4 high / yes |
| SCN-05 | workspace | scanner state / `CaptureWorkspace` | scanner controller/session | V03 S05 / none | dirty candidate / works / widget tests | P4 critical / yes |
| SCN-06 | add photos | workspace state | scanner controller/gallery/camera | V03 S06 / none | embedded / works / widget tests | P4 critical / yes |
| SCN-07 | workspace ready | workspace state | quality gate/capture plan | V03 S07 / none | embedded / works / widget tests | P4 high / yes |
| SCN-08 | analyzing | scanner state / animation | analyzer providers/API | V03 S08,V04 / none | embedded / works / analyzer tests | P5 critical / yes |
| SCN-09 | result | scanner state/result widgets (`ScanResultScreen` also exists) | analyzer/result enrichment | V03 S09,V05 / none | duplicate implementations / works / scanner tests | P5 critical / yes |
| SCN-10 | save confirmation | scanner state/snackbar/view portfolio | portfolio persistence/image storage | V03 S10 / none | embedded / works / integration evidence | P5 critical / yes |
| PORT-01 | portfolio grid/list/empty/filter/sort/delete | `tab:1` `PortfolioScreen` + sheets/dialog | portfolio controller/repo | V06 / none | legacy / works / tests+QA | P6 critical / strong |
| DETAIL-01 | overview/gallery/edit/delete | `push` `CollectibleDetailPage` + dialogs | portfolio/market/images | V07 / none | legacy, dirty file / works / tests+QA | P6 critical / strong |
| SEARCH-01 | search/results/empty/error | `missing` | no feature owner found | V08 / none | missing / absent / none | P7 high / no |
| NOTIF-01 | notification hub/categories/read state | `missing`; settings permission/price-alert controls only | price-alert controllers/native channel | V09 / none | hub missing / partial service / tests partial | P7 high / settings QA |
| SET-01 | settings/account/cloud sync/about/help | `tab:3`, direct pushes | settings/auth/cloud/diagnostics/subscription | V10 / none | legacy monolith / works / tests+QA | P7 critical / strong |
| SYS-01 | loading/empty/error/offline/permission/service unavailable/session expired | feature-local widgets/messages | respective providers | V00 + journey volumes / none | inconsistent; no shared contract / mixed / scattered | P2 high / partial |

Count by journey rows: bootstrap 4; onboarding 1 composite; authentication 7; shell 4; Home 1; scanner 10; portfolio 1; detail 1; search 1; notifications 1; settings 1; shared states 1 composite. Total stable inventory rows: **32** (composite rows expand to more visual states during implementation).
