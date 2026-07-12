# Deterministic greeting tests

Production behavior remains `ScanHubPage(now: DateTime.now)` by default. Tests inject a fixed clock through the existing `now` constructor seam; the shared `_pumpHub` fixture defaults to `2026-07-12 09:00` instead of the wall clock.

Covered states:

- Morning: fixed 09:00, guest fallback `Collector`.
- Afternoon: fixed 15:00, authenticated first name `Avery` from `Avery Collector`.
- Evening: fixed 20:00, guest fallback `Collector`.
- Long authenticated first name plus independent wave emoji at 360 logical pixels.
- Large text scale with scrollability and no exception.

Result: focused S01/shared-shell run passed all 16 tests. Full Flutter suite passed all 513 tests.
