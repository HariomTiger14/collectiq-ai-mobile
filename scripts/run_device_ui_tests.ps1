param(
  [string]$DeviceId = "",
  [string]$ReportDir = "",
  [int]$TimeoutSeconds = 300,
  [string]$Reporter = "expanded"
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
$diagnosticLog = Join-Path $ReportDir "device_ui_timeout_logcat.log"

function Resolve-AdbPath {
  $candidates = @(
    "adb",
    (Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"),
    (Join-Path $env:USERPROFILE "AppData\Local\Android\Sdk\platform-tools\adb.exe")
  )
  if (-not [string]::IsNullOrWhiteSpace($env:ANDROID_HOME)) {
    $candidates += Join-Path $env:ANDROID_HOME "platform-tools\adb.exe"
  }
  if (-not [string]::IsNullOrWhiteSpace($env:ANDROID_SDK_ROOT)) {
    $candidates += Join-Path $env:ANDROID_SDK_ROOT "platform-tools\adb.exe"
  }

  foreach ($candidate in $candidates) {
    if ($candidate -eq "adb") {
      $command = Get-Command adb -ErrorAction SilentlyContinue
      if ($null -ne $command) {
        return $command.Source
      }
    } elseif (Test-Path $candidate) {
      return $candidate
    }
  }

  return ""
}

function Write-DeviceDiagnostics {
  param([string]$Reason)

  $adb = Resolve-AdbPath
  if ([string]::IsNullOrWhiteSpace($adb)) {
    "ADB not found; unable to collect device diagnostics for $Reason." |
      Tee-Object -FilePath $diagnosticLog
    return
  }

  $deviceArgs = @()
  if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
    $deviceArgs = @("-s", $DeviceId)
  }

  "Device diagnostics for $Reason at $(Get-Date -Format o)" |
    Tee-Object -FilePath $diagnosticLog
  "---- pidof com.collectiq.ai ----" | Tee-Object -FilePath $diagnosticLog -Append
  & $adb @deviceArgs shell pidof com.collectiq.ai 2>&1 |
    Tee-Object -FilePath $diagnosticLog -Append
  "---- filtered logcat ----" | Tee-Object -FilePath $diagnosticLog -Append
  & $adb @deviceArgs logcat -d -t 500 2>&1 |
    Select-String -Pattern "COLLECTIQ|collectiq|Flutter|flutter|Dart|VM Service|Observatory|IntegrationTest|integration_test|AndroidRuntime|FATAL EXCEPTION|E/flutter|PlatformException|ANR" |
    Tee-Object -FilePath $diagnosticLog -Append
}

Push-Location $root
try {
  & $flutter devices 2>&1 | Tee-Object -FilePath $deviceReport

  $arguments = @("test", "integration_test")
  if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
    $arguments += @("-d", $DeviceId)
  }
  if (-not [string]::IsNullOrWhiteSpace($Reporter)) {
    $arguments += @("-r", $Reporter)
  }

  "Running device UI tests at $(Get-Date -Format o)" | Tee-Object -FilePath $log
  "Command: flutter $($arguments -join ' ')" | Tee-Object -FilePath $log -Append
  "Timeout guard: foreground mode streams results; use external process timeout if a hard wall-clock kill is required." |
    Tee-Object -FilePath $log -Append

  & $flutter @arguments
  $exitCode = $LASTEXITCODE
  "Exit code: $exitCode" | Tee-Object -FilePath $log -Append

  if ($exitCode -ne 0) {
    Write-DeviceDiagnostics -Reason "device-ui-exit-$exitCode"
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
if (-not [string]::IsNullOrWhiteSpace($Reporter)) {
  $commandLabel = "$commandLabel -r $Reporter"
}

@(
  "# Device UI Test Report",
  "",
  "- Status: $status",
  "- Device: $deviceLabel",
  "- Command: $commandLabel",
  "- Reporter: $Reporter",
  "- Timeout seconds: $TimeoutSeconds (diagnostic setting; foreground execution streams output)",
  "- Log: build/test_reports/device_ui_tests.log",
  "- Device list: build/test_reports/flutter_devices.log",
  "- Diagnostics: build/test_reports/device_ui_timeout_logcat.log",
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
