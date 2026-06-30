param(
  [string]$ReportDir = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ReportDir)) {
  $ReportDir = Join-Path $root "build\test_reports"
}

New-Item -ItemType Directory -Force $ReportDir | Out-Null
$log = Join-Path $ReportDir "backend_tests.log"
$summary = Join-Path $ReportDir "backend_tests_summary.md"

Push-Location (Join-Path $root "backend")
try {
  "Running backend tests at $(Get-Date -Format o)" | Tee-Object -FilePath $log
  cmd.exe /c "py -m unittest discover tests 2>&1" | Tee-Object -FilePath $log -Append
  $exitCode = $LASTEXITCODE
} finally {
  Pop-Location
}

$status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
@(
  "# Backend Test Report",
  "",
  "- Status: $status",
  "- Command: py -m unittest discover tests",
  "- Log: build/test_reports/backend_tests.log",
  "- Timestamp: $(Get-Date -Format o)"
) | Set-Content -Path $summary

exit $exitCode
