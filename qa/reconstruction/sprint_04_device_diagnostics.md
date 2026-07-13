# Sprint 04 device diagnostics

Date: 2026-07-13

Branch: `rebuild/product-language-v1`

## Summary

Device QA could not proceed to install/run because Flutter device discovery and build probes hung before tool output. ADB itself was available and detected the connected Samsung device, but the device was unauthorized.

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

Two independent blockers were observed:

1. ADB can see the Samsung device, but it is unauthorized. The phone must accept the USB debugging authorization prompt, or USB debugging authorization should be reset on the device and reaccepted.
2. Some Flutter command paths hang before invoking useful tool output, including `devices`, `doctor`, and `build apk`. The build hang occurs before Gradle starts, so the attempted APK build did not prove an Android compile failure.

## Unverified because of blockers

- `flutter devices` returning a usable device list.
- Debug APK build.
- APK install/run.
- Home runtime smoke on Samsung `RZ8R213M8ZL`.
- Home screenshots and hierarchy capture.
- Logcat stress-switch evidence.
