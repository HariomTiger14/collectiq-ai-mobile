param(
  [string]$ReportDir = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ReportDir)) {
  $ReportDir = Join-Path $root "build\test_reports"
}

New-Item -ItemType Directory -Force $ReportDir | Out-Null

& (Join-Path $PSScriptRoot "run_backend_tests.ps1") -ReportDir $ReportDir
$exitCode = $LASTEXITCODE

$summary = Join-Path $ReportDir "backend_quality_summary.md"
$status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

@(
  "# Backend Quality Report",
  "",
  "- Status: $status",
  "- Backend tests: py -m unittest discover tests",
  "- Health endpoint: covered by backend tests",
  "- Mock analyze endpoint: covered by backend tests",
  "- OpenAI/eBay calls: mocked only in automated tests",
  "- Error responses: covered by backend tests",
  "- Timestamp: $(Get-Date -Format o)"
) | Set-Content -Path $summary

exit $exitCode
