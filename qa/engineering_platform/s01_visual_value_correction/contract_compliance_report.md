# Contract compliance report

| Blocker | Evidence | Result |
|---|---|---|
| B-GREETING-CRAMPED | Active widget test verifies 8px spacer; Samsung shows separated line boxes | PASS |
| B-ICON-MIX | Entry icons are consistent outlined Material glyphs; gallery now uses image frame | PASS, exact family provisional |
| B-HERO-RATIO | Active widget test verifies rendered ratio 2.25–2.55 and 132–168 normal height | PASS |
| B-TILE-ANATOMY | Active tests verify 72px minimum, 40px icon container, 16px icon/text gap, 4px text gap, 12px peers | PASS |
| B-SAFE-LEAK | Fresh screenshot shows continuous scanner surfaces through system areas | PASS |
| B-NAV-ACTIVE | Scan selected hierarchy plus four-tab device exercise | PASS |

Responsive contexts passed at 360, 390, 412, and 430 logical pixels, plus long name, Collector fallback, large text, morning, afternoon, and evening.

Build/device evidence:

- APK timestamp: `2026-07-12T12:42:37.5180021+10:00`
- Size: `167572793` bytes
- SHA-256: `DB6F9FAD74E0A895BE1B47643B2D7D1232079F2E52C00B9A21A1CADCE905FAC0`
- Clean install: `2026-07-12 12:43:35`
- Package: `com.collectiq.ai.sit`, version `1.0.0 (1)`
- Foreground: `com.collectiq.ai.sit/com.collectiq.ai.MainActivity`

## Freeze decision

**S01 FROZEN** against Visual Intelligence package `PLX-V03-S01` v1. The blocker contracts pass, fresh Samsung evidence exists, the new value set is visibly active, and entry/navigation behavior remains functional. Provisional icon-family and exact gradient decisions remain documented variances and do not constitute major layout mismatch.
