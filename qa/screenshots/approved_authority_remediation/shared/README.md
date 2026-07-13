# Shared Phase 0 Remediation Evidence

Phase 0 captures shared visual-foundation runtime evidence only. It validates the app-level dark background, dark system bars, shared bottom navigation clearance, cross-tab runtime stability, and post-change logcat from the approved Android device.

Device: RZ8R213M8ZL, SM E625F, Android 13 API 33.
Build: local debug APK from `flutter build apk --debug --flavor local`.
Package: `com.collectiq.ai.local`.

This folder intentionally does not claim screen-specific authority alignment for Home, Portfolio, Detail, or Scanner. Portfolio and Detail still have screen-owned visual deviations captured in prior authority evidence and are deferred to their screen phases.
