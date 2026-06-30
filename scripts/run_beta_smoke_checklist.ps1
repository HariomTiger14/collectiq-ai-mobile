param(
    [string]$OutputPath = "build/test_reports/beta_smoke_checklist.md"
)

$ErrorActionPreference = "Stop"

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory -and -not (Test-Path $outputDirectory)) {
    New-Item -ItemType Directory -Force $outputDirectory | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$content = @"
# CollectIQ AI Beta Smoke Checklist

Generated: $timestamp

Mark each item after testing the current release candidate on a physical Android
device.

## App Launch + Onboarding

- [ ] Fresh install launches without crash.
- [ ] Onboarding appears on first launch.
- [ ] Start Scanning opens Scan.
- [ ] Explore Dashboard opens Home.
- [ ] Reset Onboarding in Settings works.

## Scan

- [ ] Camera opens and returns with preview.
- [ ] Gallery opens and returns with preview.
- [ ] Analyze loading state appears.
- [ ] Result card renders value, category, confidence, condition, and trend.
- [ ] Scan Again clears selected image/result.

## Save + Portfolio

- [ ] Save to Portfolio succeeds.
- [ ] New item appears first.
- [ ] Thumbnail/image renders.
- [ ] Search works.
- [ ] Category filter works.
- [ ] Detail page opens.

## Home Dashboard

- [ ] Recent Activity updates.
- [ ] Dashboard metrics update.
- [ ] Collector intelligence renders.
- [ ] Alerts summary renders.
- [ ] Wishlist/goals render.

## Detail

- [ ] Back navigation works.
- [ ] Alert creation works.
- [ ] Wishlist status change persists.
- [ ] Delete confirmation works if used.

## Settings

- [ ] Local account mode is clear.
- [ ] Sync status is clear.
- [ ] Billing disabled/test state is clear.
- [ ] Notification permission status is clear.
- [ ] Developer diagnostics are readable.

## Offline/local-first

- [ ] Mock scan works offline.
- [ ] Local save works offline.
- [ ] Backend/cloud failures do not block local save.

## Logs

- [ ] No FATAL EXCEPTION.
- [ ] No AndroidRuntime crash.
- [ ] No uncaught E/flutter error.
- [ ] No ANR.

## Notes

- Device:
- Android version:
- Build:
- Tester:
- Issues:
"@

Set-Content -Path $OutputPath -Value $content
Write-Host "Beta smoke checklist written to $OutputPath"
