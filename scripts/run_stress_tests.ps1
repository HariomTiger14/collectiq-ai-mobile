param(
  [string]$DeviceId = "",
  [string]$ReportDir = "",
  [int]$Iterations = 2,
  [switch]$SkipDeviceUi
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ReportDir)) {
  $ReportDir = Join-Path $root "build\test_reports"
}

New-Item -ItemType Directory -Force $ReportDir | Out-Null
$summary = Join-Path $ReportDir "stress_tests_summary.md"
$log = Join-Path $ReportDir "stress_tests.log"
$results = New-Object System.Collections.Generic.List[string]

"Stress QA started at $(Get-Date -Format o)" | Tee-Object -FilePath $log

for ($i = 1; $i -le $Iterations; $i++) {
  try {
    "Iteration ${i}: Flutter quality" | Tee-Object -FilePath $log -Append
    & (Join-Path $PSScriptRoot "run_flutter_quality.ps1") -ReportDir $ReportDir 2>&1 |
      Tee-Object -FilePath $log -Append
    $results.Add("- Iteration ${i} flutter_quality: PASS") | Out-Null

    if (-not $SkipDeviceUi) {
      "Iteration ${i}: Device UI" | Tee-Object -FilePath $log -Append
      & (Join-Path $PSScriptRoot "run_device_ui_tests.ps1") -DeviceId $DeviceId -ReportDir $ReportDir -TimeoutSeconds 240 2>&1 |
        Tee-Object -FilePath $log -Append
      $results.Add("- Iteration ${i} device_ui: PASS") | Out-Null
    } else {
      $results.Add("- Iteration ${i} device_ui: SKIPPED") | Out-Null
    }
  } catch {
    $results.Add("- Iteration ${i}: FAIL") | Out-Null
    "Iteration ${i} failed: $_" | Tee-Object -FilePath $log -Append
    @(
      "# Stress QA Report",
      "",
      $results,
      "",
      "- Status: FAIL",
      "- Iterations requested: $Iterations",
      "- Log: build/test_reports/stress_tests.log",
      "- Timestamp: $(Get-Date -Format o)"
    ) | Set-Content -Path $summary
    exit 1
  }
}

@(
  "# Stress QA Report",
  "",
  $results,
  "",
  "- Status: PASS",
  "- Iterations requested: $Iterations",
  "- Log: build/test_reports/stress_tests.log",
  "- Timestamp: $(Get-Date -Format o)"
) | Set-Content -Path $summary
