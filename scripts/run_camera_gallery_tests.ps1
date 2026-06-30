param(
  [string]$DeviceId = "",
  [string]$ReportDir = "",
  [int]$LogSeconds = 45
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ReportDir)) {
  $ReportDir = Join-Path $root "build\test_reports"
}

New-Item -ItemType Directory -Force $ReportDir | Out-Null
$summary = Join-Path $ReportDir "camera_gallery_tests_summary.md"
$log = Join-Path $ReportDir "camera_gallery_adb.log"

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

$adb = Resolve-AdbPath

$deviceArgs = @()
if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
  $deviceArgs = @("-s", $DeviceId)
}

"Camera/Gallery native QA log started at $(Get-Date -Format o)" | Set-Content -Path $log
try {
  if ([string]::IsNullOrWhiteSpace($adb)) {
    throw "ADB was not found in PATH or the standard Android SDK platform-tools directory."
  }
  & $adb @deviceArgs logcat -c | Out-Null
  $logcat = Start-Job -ScriptBlock {
    param($AdbCommand, $AdbArguments)
    & $AdbCommand @AdbArguments logcat 2>&1
  } -ArgumentList $adb, $deviceArgs

  Start-Sleep -Seconds $LogSeconds
  Stop-Job $logcat | Out-Null
  Receive-Job $logcat |
    Select-String -Pattern "COLLECTIQ_SCAN_FLOW|AndroidRuntime|FATAL EXCEPTION|E/flutter|PlatformException|image_picker|camera|ActivityTaskManager|WindowManager|ANR" |
    ForEach-Object { $_.Line } |
    Add-Content -Path $log
  $status = "SEMI_AUTOMATED"
} catch {
  "Log capture failed: $_" | Add-Content -Path $log
  $status = "NEEDS_ATTENTION"
}

@(
  "# Camera and Gallery Native QA Report",
  "",
  "- Status: $status",
  "- Device: $(if ([string]::IsNullOrWhiteSpace($DeviceId)) { 'default adb device' } else { $DeviceId })",
  "- Log window seconds: $LogSeconds",
  "- Log: build/test_reports/camera_gallery_adb.log",
  "",
  "## Fully Automated",
  "",
  "- Verifies ADB log capture can run with the CollectIQ picker/crash filters.",
  "- Captures COLLECTIQ_SCAN_FLOW, AndroidRuntime, FATAL EXCEPTION, E/flutter, PlatformException, ANR, image_picker, and camera lifecycle lines.",
  "",
  "## Semi-Automated Manual Steps",
  "",
  "1. Run this script while the app is installed on the device.",
  "2. Open Scan.",
  "3. Tap Camera, accept permission, capture a photo, confirm, and verify preview plus Analyze button.",
  "4. Tap Gallery, select an image, and verify preview plus Analyze button.",
  "5. Analyze and save both paths.",
  "6. Review the log for crash signatures and picker lifecycle gaps.",
  "",
  "## Manual-Only",
  "",
  "- Native permission dialogs and OEM gallery/camera picker selection remain manual unless a device-specific UIAutomator script is added.",
  "- Timestamp: $(Get-Date -Format o)"
) | Set-Content -Path $summary
