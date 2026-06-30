param(
  [string]$ReportDir = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$flutter = Join-Path $env:USERPROFILE "Desktop\flutter\bin\flutter.bat"
$dart = Join-Path $env:USERPROFILE "Desktop\flutter\bin\dart.bat"
if ([string]::IsNullOrWhiteSpace($ReportDir)) {
  $ReportDir = Join-Path $root "build\test_reports"
}

New-Item -ItemType Directory -Force $ReportDir | Out-Null
$summary = Join-Path $ReportDir "flutter_quality_summary.md"
$results = New-Object System.Collections.Generic.List[string]

function ConvertTo-CommandLine {
  param(
    [string]$Command,
    [string[]]$Arguments
  )

  $quotedCommand = '"' + $Command + '"'
  $quotedArguments = $Arguments | ForEach-Object {
    if ($_ -match '\s') { '"' + $_ + '"' } else { $_ }
  }
  return "$quotedCommand $($quotedArguments -join ' ')"
}

function Invoke-LoggedCommand {
  param(
    [string]$Name,
    [string]$Command,
    [string[]]$Arguments
  )

  $log = Join-Path $ReportDir "$Name.log"
  $commandLine = ConvertTo-CommandLine -Command $Command -Arguments $Arguments
  Push-Location $root
  try {
    "Running $Name at $(Get-Date -Format o)" | Tee-Object -FilePath $log
    cmd.exe /c "$commandLine 2>&1" | Tee-Object -FilePath $log -Append
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

@(
  "# Flutter Quality Report",
  "",
  $results,
  "",
  "- Coverage: formatting, static analysis, Flutter unit/widget tests",
  "- Mode: mock/default, no paid providers",
  "- Timestamp: $(Get-Date -Format o)"
) | Set-Content -Path $summary
