param(
  [string]$DeviceId = "",
  [switch]$SkipDeviceUi,
  [switch]$SkipBuilds,
  [switch]$SkipStress,
  [switch]$SkipCameraGallery,
  [switch]$SkipPersistence,
  [int]$StressIterations = 1
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$reportDir = Join-Path $root "build\test_reports"
$summary = Join-Path $reportDir "master_qa_summary.md"
$results = New-Object System.Collections.Generic.List[string]
$startedAt = Get-Date
$overallStatus = "PASS"
$failureReason = ""

New-Item -ItemType Directory -Force $reportDir | Out-Null

function Write-MasterSummary {
  param(
    [string]$Status,
    [string]$FailureReason = ""
  )

  $finishedAt = Get-Date
  $duration = New-TimeSpan -Start $startedAt -End $finishedAt
  $failureLines = @()
  if (-not [string]::IsNullOrWhiteSpace($FailureReason)) {
    $failureLines = @("", "## Failure", "", "- $FailureReason")
  }

  @(
    "# CollectIQ AI Master QA Summary",
    "",
    "- Status: $Status",
    "- Started: $($startedAt.ToString('o'))",
    "- Finished: $($finishedAt.ToString('o'))",
    "- Duration: $($duration.ToString())",
    "- Device: $(if ([string]::IsNullOrWhiteSpace($DeviceId)) { 'default Flutter/ADB device' } else { $DeviceId })",
    $failureLines,
    "",
    "## Results",
    "",
    $results,
    "",
    "## Coverage Classification",
    "",
    "- Fully automated: Flutter format/analyze/tests, backend tests, integration smoke when the attached-device runner is available, seeded dashboard/portfolio/detail/settings flows, usage-limit error, Android builds.",
    "- Semi-automated: camera/gallery native picker with ADB log capture, force-stop persistence smoke, optional full relaunch persistence smoke.",
    "- Stress: repeated Flutter quality by default; pass run_stress_tests.ps1 without -SkipDeviceUi for repeated physical-device integration runs.",
    "- Manual-only: OEM picker permission decisions, real captured/gallery image visual confirmation, offline airplane-mode validation, real cloud/provider validation.",
    "",
    "## Reports",
    "",
    "- build/test_reports/flutter_quality_summary.md",
    "- build/test_reports/backend_tests_summary.md",
    "- build/test_reports/device_ui_tests_summary.md",
    "- build/test_reports/camera_gallery_tests_summary.md",
    "- build/test_reports/persistence_tests_summary.md",
    "- build/test_reports/stress_tests_summary.md",
    "- build/test_reports/android_builds_summary.md"
  ) | Set-Content -Path $summary
}

function Invoke-QaScript {
  param(
    [string]$Name,
    [string]$ScriptPath,
    [string[]]$Arguments = @(),
    [bool]$Required = $true,
    [bool]$Unpiped = $false
  )

  $log = Join-Path $reportDir "master_$Name.log"
  try {
    "Running $Name at $(Get-Date -Format o)" | Tee-Object -FilePath $log
    if ($Unpiped) {
      "Running without Tee-Object pipeline to preserve attached-device Flutter test result delivery." |
        Tee-Object -FilePath $log -Append
      & powershell -ExecutionPolicy Bypass -File $ScriptPath @Arguments
      "Exit code: $LASTEXITCODE" | Tee-Object -FilePath $log -Append
    } else {
      & powershell -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1 |
        Tee-Object -FilePath $log -Append
    }
    $exitCode = $LASTEXITCODE
  } catch {
    "Script exception: $_" | Tee-Object -FilePath $log -Append
    $exitCode = 1
  }

  $status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
  $results.Add("- ${Name}: $status") | Out-Null
  if ($Required -and $exitCode -ne 0) {
    throw "$Name failed. See $log"
  }
}

try {
  Invoke-QaScript -Name "flutter_quality" -ScriptPath (Join-Path $PSScriptRoot "run_flutter_quality.ps1") -Arguments @("-ReportDir", $reportDir)
  Invoke-QaScript -Name "backend_quality" -ScriptPath (Join-Path $PSScriptRoot "run_backend_quality.ps1") -Arguments @("-ReportDir", $reportDir)

  if (-not $SkipDeviceUi) {
    Invoke-QaScript -Name "device_ui_tests" -ScriptPath (Join-Path $PSScriptRoot "run_device_ui_tests.ps1") -Arguments @("-DeviceId", $DeviceId, "-ReportDir", $reportDir, "-TimeoutSeconds", "240") -Unpiped $true
  } else {
    $results.Add("- device_ui_tests: SKIPPED") | Out-Null
  }

  if (-not $SkipCameraGallery) {
    Invoke-QaScript -Name "camera_gallery_tests" -ScriptPath (Join-Path $PSScriptRoot "run_camera_gallery_tests.ps1") -Arguments @("-DeviceId", $DeviceId, "-ReportDir", $reportDir, "-LogSeconds", "10") -Required $false
  } else {
    $results.Add("- camera_gallery_tests: SKIPPED") | Out-Null
  }

  if (-not $SkipPersistence -and -not $SkipDeviceUi) {
    Invoke-QaScript -Name "persistence_tests" -ScriptPath (Join-Path $PSScriptRoot "run_persistence_tests.ps1") -Arguments @("-DeviceId", $DeviceId, "-ReportDir", $reportDir, "-TimeoutSeconds", "240")
  } else {
    $results.Add("- persistence_tests: SKIPPED") | Out-Null
  }

  if (-not $SkipStress) {
    $stressArgs = @("-DeviceId", $DeviceId, "-ReportDir", $reportDir, "-Iterations", "$StressIterations")
    $stressArgs += "-SkipDeviceUi"
    Invoke-QaScript -Name "stress_tests" -ScriptPath (Join-Path $PSScriptRoot "run_stress_tests.ps1") -Arguments $stressArgs
  } else {
    $results.Add("- stress_tests: SKIPPED") | Out-Null
  }

  if (-not $SkipBuilds) {
    Invoke-QaScript -Name "android_builds" -ScriptPath (Join-Path $PSScriptRoot "run_android_builds.ps1") -Arguments @("-ReportDir", $reportDir)
  } else {
    $results.Add("- android_builds: SKIPPED") | Out-Null
  }
} catch {
  $overallStatus = "FAIL"
  $failureReason = "$_"
  Write-MasterSummary -Status $overallStatus -FailureReason $failureReason
  throw
}

Write-MasterSummary -Status $overallStatus -FailureReason $failureReason
