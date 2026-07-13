# Sprint 04 device diagnostics

Date: 2026-07-13

Branch: `rebuild/product-language-v1`

## Summary

Device QA proceeded after the Samsung device was reauthorized. Flutter CLI discovery, local debug build, install, launch, Home runtime validation, screenshots, hierarchy capture, and logcat capture completed.

No `flutter clean` was run during this diagnostic pass.

## Environment observations

- `where flutter`: no PATH entry found.
- `where dart`: no PATH entry found.
- `where adb`: `C:\Users\hario\Downloads\platform-tools-latest-windows\platform-tools\adb.exe`.
- `java -version`: Java 1.8.0_431.
- Direct Dart SDK check: `Dart SDK version: 3.12.2 (stable) ... on "windows_x64"`.

## ADB checks

Command:

`C:\Users\hario\Downloads\platform-tools-latest-windows\platform-tools\adb.exe version`

Result:

- Android Debug Bridge 1.0.41
- Version 37.0.0-14910828
- Installed at `C:\Users\hario\Downloads\platform-tools-latest-windows\platform-tools\adb.exe`

Command:

`adb devices -l`

Result:

- ADB daemon started successfully.
- `RZ8R213M8ZL unauthorized transport_id:1`

After `adb kill-server`, `adb start-server`, and another `adb devices -l`, the state remained:

- `RZ8R213M8ZL unauthorized transport_id:1`

This means Android device-side authorization must be resolved on the handset before install/run QA can proceed.

Follow-up runtime pass:

- `adb devices -l` reported `RZ8R213M8ZL device product:f62ins model:SM_E625F device:f62 transport_id:1`.
- `flutter devices --device-timeout 30` detected `SM E625F (mobile)`.

## Flutter hang probes

The following commands hung before useful Flutter output:

- `C:\Users\hario\Desktop\flutter\bin\flutter.bat --version`
- `C:\Users\hario\Desktop\flutter\bin\flutter.bat devices --device-timeout 30`
- `C:\Users\hario\Desktop\flutter\bin\flutter.bat doctor -v`
- `C:\Users\hario\Desktop\flutter\bin\flutter.bat build apk --debug --flavor local -v`

For each hung probe, process inspection showed only the launched PowerShell wrapper and child `cmd.exe` for `flutter.bat`. No Gradle process appeared during the build probe. Each hung probe was stopped by terminating only the launched process tree.

By contrast, these Flutter test/analyze commands completed normally:

- `C:\Users\hario\Desktop\flutter\bin\flutter.bat analyze`
- focused Flutter test commands
- full Flutter test command

## Diagnosis

Earlier blocked-pass diagnosis:

1. ADB can see the Samsung device, but it is unauthorized. The phone must accept the USB debugging authorization prompt, or USB debugging authorization should be reset on the device and reaccepted.
2. Some Flutter command paths hang before invoking useful tool output, including `devices`, `doctor`, and `build apk`. The build hang occurs before Gradle starts, so the attempted APK build did not prove an Android compile failure.

Follow-up diagnosis:

- The previous Flutter CLI hang was caused by sandboxed Flutter tooling being unable to open `C:\Users\hario\Desktop\flutter\bin\cache\lockfile`.
- Running Flutter commands outside the sandbox allowed SDK cache access and resolved discovery/build hangs.
- No Gradle daemon stop or `flutter clean` was required.

## Build install and launch

- Build command: `flutter build apk --debug --flavor local -v`.
- Build result: passed; Gradle `assembleLocalDebug` completed successfully.
- APK path: `build\app\outputs\flutter-apk\app-local-debug.apk`.
- Install command: `flutter install -d RZ8R213M8ZL --debug --flavor local`.
- Install result: passed.
- Launch command: `adb shell monkey -p com.collectiq.ai.local -c android.intent.category.LAUNCHER 1`.
- Launch result: passed; foreground activity was `com.collectiq.ai.local/com.collectiq.ai.MainActivity`.

## Runtime evidence

Evidence directory: `qa/screenshots/reconstruction/sprint_04_home/`

- `empty_home_first_viewport.png` and `.xml`
- `empty_home_lower_content.png`
- `scan_action_handoff.png` and `.xml`
- `portfolio_action_handoff.png` and `.xml`
- `home_after_tab_scroll_stress.png` and `.xml`
- `tab_scroll_stress_logcat.txt`

The known Home/shell stress sequence completed without observed ANR, input lock, foreground loss, or blank final frame. Raw logcat includes unrelated device/service noise and normal app Scanner lost-picker recovery logs when visiting Scan.
