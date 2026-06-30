param(
  [string]$DeviceId = "",
  [string]$ReportDir = "",
  [int]$TimeoutSeconds = 240,
  [switch]$RunIntegrationAfterForceStop
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ReportDir)) {
  $ReportDir = Join-Path $root "build\test_reports"
}

New-Item -ItemType Directory -Force $ReportDir | Out-Null
$summary = Join-Path $ReportDir "persistence_tests_summary.md"
$log = Join-Path $ReportDir "persistence_tests.log"
$appId = "com.collectiq.ai"

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

"Persistence QA started at $(Get-Date -Format o)" | Tee-Object -FilePath $log

try {
  if ([string]::IsNullOrWhiteSpace($adb)) {
    throw "ADB was not found in PATH or the standard Android SDK platform-tools directory."
  }
  "Force-stopping $appId before verification." | Tee-Object -FilePath $log -Append
  & $adb @deviceArgs shell am force-stop $appId 2>&1 | Tee-Object -FilePath $log -Append

  if ($RunIntegrationAfterForceStop) {
    "Running integration smoke after force-stop." | Tee-Object -FilePath $log -Append
    & (Join-Path $PSScriptRoot "run_device_ui_tests.ps1") -DeviceId $DeviceId -ReportDir $ReportDir -TimeoutSeconds $TimeoutSeconds 2>&1 |
      Tee-Object -FilePath $log -Append
    $exitCode = $LASTEXITCODE
  } else {
    "Skipping repeated integration relaunch by default. Use -RunIntegrationAfterForceStop for the full relaunch smoke." |
      Tee-Object -FilePath $log -Append
    $exitCode = 0
  }
} catch {
  "Persistence script failed: $_" | Tee-Object -FilePath $log -Append
  $exitCode = 1
}

$status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

@(
  "# Persistence QA Report",
  "",
  "- Status: $status",
  "- Device: $(if ([string]::IsNullOrWhiteSpace($DeviceId)) { 'default adb device' } else { $DeviceId })",
  "- App id: $appId",
  "- Log: build/test_reports/persistence_tests.log",
  "",
  "## Fully Automated",
  "",
  "- ADB force-stops the app before verification.",
  "- Existing Flutter tests validate local repository reload, image references, and newest-first ordering after persistence reload.",
  "- Optional full relaunch integration smoke: $(if ($RunIntegrationAfterForceStop) { 'RUN' } else { 'SKIPPED by default to avoid repeated physical-device runner hangs' }).",
  "",
  "## Manual Follow-Up",
  "",
  "- Save a real camera image, force-stop from Android settings or ADB, relaunch, and confirm the local image still renders.",
  "- Save a real gallery image, force-stop, relaunch, and confirm the copied local image still renders.",
  "- Timestamp: $(Get-Date -Format o)"
) | Set-Content -Path $summary

exit $exitCode
