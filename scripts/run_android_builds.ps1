param(
  [string]$ReportDir = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$flutter = Join-Path $env:USERPROFILE "Desktop\flutter\bin\flutter.bat"
if ([string]::IsNullOrWhiteSpace($ReportDir)) {
  $ReportDir = Join-Path $root "build\test_reports"
}

New-Item -ItemType Directory -Force $ReportDir | Out-Null
$summary = Join-Path $ReportDir "android_builds_summary.md"
$results = New-Object System.Collections.Generic.List[string]

function Invoke-LoggedFlutterBuild {
  param(
    [string]$Name,
    [string[]]$Arguments
  )

  $log = Join-Path $ReportDir "$Name.log"
  Push-Location $root
  try {
    "Running $Name at $(Get-Date -Format o)" | Tee-Object -FilePath $log
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
      & $flutter @Arguments 2>&1 | Tee-Object -FilePath $log -Append
    } finally {
      $ErrorActionPreference = $previousErrorActionPreference
    }
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

Invoke-LoggedFlutterBuild -Name "flutter_build_apk_debug" -Arguments @("build", "apk", "--debug")
Invoke-LoggedFlutterBuild -Name "flutter_build_apk_release" -Arguments @("build", "apk", "--release")
Invoke-LoggedFlutterBuild -Name "flutter_build_appbundle_release" -Arguments @("build", "appbundle", "--release")

@(
  "# Android Build Report",
  "",
  $results,
  "",
  "- Debug APK: build/app/outputs/flutter-apk/app-debug.apk",
  "- Release APK: build/app/outputs/flutter-apk/app-release.apk",
  "- Release AAB: build/app/outputs/bundle/release/app-release.aab",
  "- Timestamp: $(Get-Date -Format o)"
) | Set-Content -Path $summary
