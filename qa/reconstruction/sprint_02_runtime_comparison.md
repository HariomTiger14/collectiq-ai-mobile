# Sprint 02 onboarding runtime comparison

Date: 2026-07-13  
Worktree: `C:\Users\hario\Desktop\projects\collectiq_ai_reconstruction`  
Branch: `rebuild/product-language-v1`  
Baseline HEAD before Sprint 02 changes: `6f16c59495014309427c1244ec20d8e0f555fd67`  
Device: Samsung SM E625F, Android 13 / API 33, device id `RZ8R213M8ZL`  
Flavor/build: local debug APK, `com.collectiq.ai.local`

## Runtime steps

1. Built local debug APK with:
   - `flutter build apk --debug --flavor local`
2. First build attempt failed during `:app:mergeLocalDebugJavaResource` because C: had about 0.27 GB free.
3. Ran project-local `flutter clean`, recovering about 4 GB from generated build output.
4. Rebuilt successfully:
   - `build\app\outputs\flutter-apk\app-local-debug.apk`
5. Installed with `adb install -r`.
6. Cleared app data with:
   - `adb shell pm clear com.collectiq.ai.local`
7. Launched via package monkey intent.
8. Captured onboarding stages and dashboard handoff.
9. Reset app data again and captured onboarding hierarchy.

## Evidence

Screenshots and hierarchy are stored in:

- `qa/screenshots/reconstruction/sprint_02_onboarding/stage_01_welcome.png`
- `qa/screenshots/reconstruction/sprint_02_onboarding/stage_02_flow.png`
- `qa/screenshots/reconstruction/sprint_02_onboarding/stage_03_local_first.png`
- `qa/screenshots/reconstruction/sprint_02_onboarding/dashboard_handoff.png`
- `qa/screenshots/reconstruction/sprint_02_onboarding/stage_01_hierarchy.xml`

## Observed behavior

- Fresh install/data-clear starts at reconstructed onboarding Stage 1.
- Stage 1 presents `Welcome to PackLox`, guest access, local-first positioning, progress `Step 1 of 3`, and `Next`.
- Stage 2 presents the Scan / Analyze / Save / Track loop with Back and Next controls.
- Stage 3 presents local-first/privacy/cloud-optional messaging and final actions:
  - `Start Scanning`
  - `Explore Dashboard`
- No login, signup, password, account creation, permission prompt, backend gate, or auth guard appears in onboarding.
- Tapping `Explore Dashboard` completes onboarding and hands off to Home.
- Home appears with the existing dashboard entry content and bottom navigation.

## Comparison to Sprint 01 baseline

- Preserved AppShell-controlled completion and handoff.
- Preserved guest/signed-out access.
- Preserved local onboarding persistence key and controller contract.
- Changed only the onboarding presentation from a single composite scroll screen into a three-stage guided presentation.
- Did not modify router strategy, authentication entry, backend behavior, AppShell tab structure, or Home presentation.

## Status

Runtime evidence reached `runtime_ready` for Sprint 02 implementation. This does not imply visual approval or freeze; explicit review is still required by the visual approval gate process.
