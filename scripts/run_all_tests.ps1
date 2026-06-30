param(
  [string]$DeviceId = "",
  [switch]$SkipDeviceUi,
  [switch]$SkipBuilds
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$flutter = Join-Path $env:USERPROFILE "Desktop\flutter\bin\flutter.bat"
$dart = Join-Path $env:USERPROFILE "Desktop\flutter\bin\dart.bat"
$reportDir = Join-Path $root "build\test_reports"
$summary = Join-Path $reportDir "all_tests_summary.md"
$results = New-Object System.Collections.Generic.List[string]

New-Item -ItemType Directory -Force $reportDir | Out-Null

function Invoke-LoggedCommand {
  param(
    [string]$Name,
    [string]$Command,
    [string[]]$Arguments,
    [string]$WorkingDirectory = $root
  )

  $log = Join-Path $reportDir "$Name.log"
  Push-Location $WorkingDirectory
  try {
    "Running $Name at $(Get-Date -Format o)" | Tee-Object -FilePath $log
    & $Command @Arguments 2>&1 | Tee-Object -FilePath $log -Append
    $exitCode = $LASTEXITCODE
  } finally {
    Pop-Location
  }

  $status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
  $results.Add("- ${Name}: $status") | Out-Null
  if ($exitCode -ne 0) {
    throw "$Name failed. See $log"
  }
}

Invoke-LoggedCommand -Name "dart_format" -Command $dart -Arguments @("format", "lib", "test", "integration_test")
Invoke-LoggedCommand -Name "flutter_analyze" -Command $flutter -Arguments @("analyze")
Invoke-LoggedCommand -Name "flutter_test" -Command $flutter -Arguments @("test")

& (Join-Path $PSScriptRoot "run_backend_tests.ps1") -ReportDir $reportDir
$results.Add("- backend_tests: PASS") | Out-Null

if (-not $SkipDeviceUi) {
  & (Join-Path $PSScriptRoot "run_device_ui_tests.ps1") -DeviceId $DeviceId -ReportDir $reportDir
  $results.Add("- device_ui_tests: PASS") | Out-Null
} else {
  $results.Add("- device_ui_tests: SKIPPED") | Out-Null
}

if (-not $SkipBuilds) {
  & (Join-Path $PSScriptRoot "run_android_builds.ps1") -ReportDir $reportDir
  $results.Add("- android_builds: PASS") | Out-Null
} else {
  $results.Add("- android_builds: SKIPPED") | Out-Null
}

@(
  "# CollectIQ AI Test Automation Summary",
  "",
  $results,
  "",
  "- Report directory: build/test_reports/",
  "- Native picker validation: semi-automated via scripts/android_scan_flow_logs.ps1",
  "- Timestamp: $(Get-Date -Format o)"
) | Set-Content -Path $summary
