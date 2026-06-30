param(
  [string]$DeviceId = "",
  [string]$ReportDir = "",
  [int]$TimeoutSeconds = 300
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$flutter = Join-Path $env:USERPROFILE "Desktop\flutter\bin\flutter.bat"
if ([string]::IsNullOrWhiteSpace($ReportDir)) {
  $ReportDir = Join-Path $root "build\test_reports"
}

New-Item -ItemType Directory -Force $ReportDir | Out-Null
$log = Join-Path $ReportDir "device_ui_tests.log"
$summary = Join-Path $ReportDir "device_ui_tests_summary.md"
$deviceReport = Join-Path $ReportDir "flutter_devices.log"

Push-Location $root
try {
  & $flutter devices 2>&1 | Tee-Object -FilePath $deviceReport

  $arguments = @("test", "integration_test")
  if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
    $arguments += @("-d", $DeviceId)
  }

  "Running device UI tests at $(Get-Date -Format o)" | Tee-Object -FilePath $log
  "Command: flutter $($arguments -join ' ')" | Tee-Object -FilePath $log -Append

  $job = Start-Job -ScriptBlock {
    param($WorkingDirectory, $FlutterCommand, $FlutterArguments)

    Push-Location $WorkingDirectory
    try {
      & $FlutterCommand @FlutterArguments 2>&1
      "__COLLECTIQ_EXIT_CODE__$LASTEXITCODE"
    } finally {
      Pop-Location
    }
  } -ArgumentList $root, $flutter, $arguments

  if (-not (Wait-Job $job -Timeout $TimeoutSeconds)) {
    Stop-Job $job | Out-Null
    Receive-Job $job | Tee-Object -FilePath $log -Append | Out-Null
    "Device UI tests timed out after $TimeoutSeconds seconds." | Tee-Object -FilePath $log -Append
    $exitCode = 124
  } else {
    $output = Receive-Job $job
    $output | Tee-Object -FilePath $log -Append | Out-Null
    $exitLine = $output | Where-Object { $_ -is [string] -and $_.StartsWith("__COLLECTIQ_EXIT_CODE__") } | Select-Object -Last 1
    if ($null -eq $exitLine) {
      $exitCode = 1
    } else {
      $exitCode = [int]($exitLine -replace "__COLLECTIQ_EXIT_CODE__", "")
    }
  }
} finally {
  Pop-Location
}

$status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$deviceLabel = if ([string]::IsNullOrWhiteSpace($DeviceId)) { "default Flutter device selection" } else { $DeviceId }
$commandLabel = "flutter test integration_test"
if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
  $commandLabel = "$commandLabel -d $DeviceId"
}

@(
  "# Device UI Test Report",
  "",
  "- Status: $status",
  "- Device: $deviceLabel",
  "- Command: $commandLabel",
  "- Timeout seconds: $TimeoutSeconds",
  "- Log: build/test_reports/device_ui_tests.log",
  "- Device list: build/test_reports/flutter_devices.log",
  "",
  "## Native Picker Manual Coverage",
  "",
  "Native camera/gallery picker surfaces are outside Flutter widget automation.",
  "Use scripts/android_scan_flow_logs.ps1 -DeviceId <device> while manually testing:",
  "",
  "1. Open Scan.",
  "2. Tap Camera, capture, confirm preview returns.",
  "3. Tap Gallery, choose an image, confirm preview returns.",
  "4. Check logs for COLLECTIQ_SCAN_FLOW, AndroidRuntime, FATAL EXCEPTION, PlatformException, and image_picker.",
  "",
  "- Timestamp: $(Get-Date -Format o)"
) | Set-Content -Path $summary

exit $exitCode
