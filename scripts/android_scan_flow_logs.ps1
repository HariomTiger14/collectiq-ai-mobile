param(
  [string]$DeviceId = "",
  [switch]$RunApp
)

$ErrorActionPreference = "Stop"

$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
$flutter = Join-Path $env:USERPROFILE "Desktop\flutter\bin\flutter.bat"
$filter = "COLLECTIQ_SCAN_FLOW AndroidRuntime FATAL EXCEPTION E/flutter image_picker camera ActivityTaskManager WindowManager SurfaceView OpenGLRenderer PlatformException"

if (-not (Test-Path $adb)) {
  throw "adb.exe not found at $adb"
}

Write-Host "Clearing Android logcat..."
& $adb logcat -c

if ($RunApp) {
  if ([string]::IsNullOrWhiteSpace($DeviceId)) {
    throw "Pass -DeviceId when using -RunApp."
  }

  if (-not (Test-Path $flutter)) {
    throw "flutter.bat not found at $flutter"
  }

  Write-Host "Starting Flutter app on $DeviceId..."
  Start-Process -FilePath $flutter -ArgumentList @("run", "-d", $DeviceId)
  Start-Sleep -Seconds 8
}

Write-Host ""
Write-Host "Manual test steps:"
Write-Host "1. Open Scan screen."
Write-Host "2. Tap Camera, take photo, tap OK."
Write-Host "3. Observe picker return."
Write-Host "4. Tap Gallery and select an image."
Write-Host "5. Observe picker return."
Write-Host ""
Write-Host "Capturing filtered logcat. Press Ctrl+C to stop."
Write-Host "Filter: $filter"
Write-Host ""

& $adb logcat |
  Select-String -Pattern $filter
