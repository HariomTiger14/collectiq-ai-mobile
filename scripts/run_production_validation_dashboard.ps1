param(
  [string]$ReportDir = "",
  [string]$ValidationEndpoint = "http://127.0.0.1:8000/api/analyze",
  [string]$ValidationManifest = "",
  [switch]$SkipBuilds,
  [switch]$SkipValidationLabNetwork
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ReportDir)) {
  $ReportDir = Join-Path $root "build\test_reports\production_validation"
}
if ([string]::IsNullOrWhiteSpace($ValidationManifest)) {
  $ValidationManifest = Join-Path $root "validation\manifests\sample_manifest.json"
}

$dashboardPath = Join-Path $ReportDir "production_validation_dashboard.md"
$docsReportPath = Join-Path $root "docs\PRODUCTION_VALIDATION_REPORT.md"
$validationReportsDir = Join-Path $root "validation\reports"
$validationCsv = Join-Path $validationReportsDir "latest_validation_results.csv"
$validationMd = Join-Path $validationReportsDir "latest_validation_report.md"
$results = New-Object System.Collections.Generic.List[object]
$startedAt = Get-Date

New-Item -ItemType Directory -Force $ReportDir | Out-Null
New-Item -ItemType Directory -Force $validationReportsDir | Out-Null

function Invoke-ValidationStep {
  param(
    [string]$Name,
    [scriptblock]$Action,
    [bool]$Required = $true
  )

  $log = Join-Path $ReportDir "$Name.log"
  $stepStartedAt = Get-Date
  $status = "PASS"
  $notes = ""
  try {
    "Running $Name at $($stepStartedAt.ToString('o'))" | Tee-Object -FilePath $log
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
      & $Action 2>&1 | Tee-Object -FilePath $log -Append
    } finally {
      $ErrorActionPreference = $previousErrorActionPreference
    }
    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) {
      $exitCode = 0
    }
    if ($exitCode -ne 0) {
      $status = "FAIL"
      $notes = "Exit code $exitCode. See $log"
      if ($Required) {
        throw $notes
      }
    }
  } catch {
    $status = "FAIL"
    $notes = "$_"
    "Step failed: $notes" | Tee-Object -FilePath $log -Append
    if ($Required) {
      $results.Add([pscustomobject]@{
        Name = $Name
        Status = $status
        Notes = $notes
        StartedAt = $stepStartedAt
        FinishedAt = Get-Date
      }) | Out-Null
      throw
    }
  }

  $results.Add([pscustomobject]@{
    Name = $Name
    Status = $status
    Notes = $notes
    StartedAt = $stepStartedAt
    FinishedAt = Get-Date
  }) | Out-Null
}

function Get-StepStatus {
  param([string]$Name)
  $match = $results | Where-Object { $_.Name -eq $Name } | Select-Object -Last 1
  if ($null -eq $match) {
    return "NOT RUN"
  }
  return $match.Status
}

function Get-ValidationMetrics {
  $metrics = @{
    AiAccuracy = "Not measured"
    PricingAgreement = "Not measured"
    AverageConfidence = "Not measured"
    AverageLatency = "Not measured"
    FailedImages = "Not measured"
  }

  if (-not (Test-Path $validationCsv)) {
    return $metrics
  }

  $rows = Import-Csv $validationCsv
  $passed = @($rows | Where-Object { $_.status -eq "passed" })
  if ($passed.Count -eq 0) {
    $missing = @($rows | Where-Object { $_.status -eq "missing_image" })
    $dryRun = @($rows | Where-Object { $_.status -eq "dry_run" })
    if ($dryRun.Count -gt 0) {
      $metrics.AiAccuracy = "Dry run only"
      $metrics.PricingAgreement = "Dry run only"
      $metrics.AverageConfidence = "Dry run only"
      $metrics.AverageLatency = "Dry run only"
    } elseif ($missing.Count -gt 0) {
      $metrics.AiAccuracy = "No images available"
      $metrics.PricingAgreement = "No images available"
      $metrics.AverageConfidence = "No images available"
      $metrics.AverageLatency = "No images available"
    }
    $metrics.FailedImages = "$($missing.Count)"
    return $metrics
  }

  $categoryMatches = @($passed | Where-Object { $_.category_match -eq "True" })
  $confidenceValues = @(
    $passed |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_.confidence) } |
      ForEach-Object { [double]$_.confidence }
  )
  $latencyValues = @(
    $passed |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_.latency_ms) } |
      ForEach-Object { [double]$_.latency_ms }
  )
  $fallbacks = @(
    $passed |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_.fallback_reason) }
  )

  $metrics.AiAccuracy = "{0:P1}" -f ($categoryMatches.Count / [double]$passed.Count)
  if ($confidenceValues.Count -gt 0) {
    $metrics.AverageConfidence = "{0:N1}%" -f (($confidenceValues | Measure-Object -Average).Average)
  }
  if ($latencyValues.Count -gt 0) {
    $metrics.AverageLatency = "{0:N0} ms" -f (($latencyValues | Measure-Object -Average).Average)
  }
  $metrics.PricingAgreement = if ($fallbacks.Count -gt 0) {
    "Fallback used for $($fallbacks.Count) result(s)"
  } else {
    "No fallback reported"
  }
  $metrics.FailedImages = "$(@($rows | Where-Object { $_.status -in @('failed', 'missing_image') }).Count)"
  return $metrics
}

function Get-ReadinessScore {
  param([hashtable]$Metrics)

  $score = 100
  foreach ($name in @("flutter_quality", "backend_quality", "validation_lab", "android_builds")) {
    $status = Get-StepStatus -Name $name
    if ($status -eq "FAIL") {
      $score -= 25
    } elseif ($status -eq "NOT RUN") {
      $score -= 10
    }
  }

  if ($Metrics.AiAccuracy -in @("Not measured", "No images available", "Dry run only")) {
    $score -= 10
  }
  if ($Metrics.PricingAgreement -in @("Not measured", "No images available", "Dry run only")) {
    $score -= 10
  }
  if ($Metrics.AverageLatency -in @("Not measured", "No images available", "Dry run only")) {
    $score -= 5
  }

  if ($score -lt 0) {
    return 0
  }
  return $score
}

function Format-ResultRows {
  $lines = New-Object System.Collections.Generic.List[string]
  foreach ($result in $results) {
    $note = if ([string]::IsNullOrWhiteSpace($result.Notes)) { "" } else { $result.Notes }
    $lines.Add("| $($result.Name) | $($result.Status) | $note |") | Out-Null
  }
  return $lines
}

function Write-Dashboard {
  $finishedAt = Get-Date
  $duration = New-TimeSpan -Start $startedAt -End $finishedAt
  $metrics = Get-ValidationMetrics
  $score = Get-ReadinessScore -Metrics $metrics
  $criticalBlockers = New-Object System.Collections.Generic.List[string]
  $highPriorityFixes = New-Object System.Collections.Generic.List[string]

  foreach ($result in $results) {
    if ($result.Status -eq "FAIL") {
      $criticalBlockers.Add("$($result.Name) failed: $($result.Notes)") | Out-Null
    }
  }
  if ($metrics.AiAccuracy -in @("Not measured", "No images available", "Dry run only")) {
    $highPriorityFixes.Add("Run Validation Lab with licensed/user-owned collectible images to measure AI accuracy.") | Out-Null
  }
  if ($metrics.PricingAgreement -in @("Not measured", "No images available", "Dry run only")) {
    $highPriorityFixes.Add("Run backend in real-provider mode locally to measure pricing provider agreement.") | Out-Null
  }
  if ($criticalBlockers.Count -eq 0) {
    $criticalBlockers.Add("None from automated local validation.") | Out-Null
  }
  if ($highPriorityFixes.Count -eq 0) {
    $highPriorityFixes.Add("None from automated local validation.") | Out-Null
  }

  $betaRecommendation = if ($score -ge 85 -and $criticalBlockers[0] -eq "None from automated local validation.") {
    "Recommended for closed beta after manual real-device camera/gallery and real-provider spot checks."
  } elseif ($score -ge 70) {
    "Conditionally ready for closed beta after resolving high-priority validation gaps."
  } else {
    "Not ready for beta until critical validation failures are resolved."
  }

  $resultRows = Format-ResultRows
  $content = @(
    "# CollectIQ AI Production Validation Report",
    "",
    "- Generated: $($finishedAt.ToString('o'))",
    "- Duration: $($duration.ToString())",
    '- Report source: `scripts/run_production_validation_dashboard.ps1`',
    "- Validation manifest: ``$ValidationManifest``",
    "- Validation endpoint: ``$ValidationEndpoint``",
    "",
    "## Executive Summary",
    "",
    "- Overall readiness score: **$score / 100**",
    "- Recommendation for beta: **$betaRecommendation**",
    "",
    "## Validation Dashboard",
    "",
    "| Metric | Current Status |",
    "| --- | --- |",
    "| AI accuracy | $($metrics.AiAccuracy) |",
    "| Pricing provider agreement | $($metrics.PricingAgreement) |",
    "| Average confidence | $($metrics.AverageConfidence) |",
    "| Average latency | $($metrics.AverageLatency) |",
    "| Sync success rate | Covered by Flutter sync tests; live Supabase rate requires configured project run. |",
    "| Billing status | Google Play Billing foundation tested; production products require Play Console setup. |",
    "| Crash-free sessions | Telemetry placeholder available; live crash-free sessions require a selected observability provider and beta traffic. |",
    "| Backend health | $(Get-StepStatus -Name 'backend_quality') |",
    "| Test status | Flutter: $(Get-StepStatus -Name 'flutter_quality'); Backend: $(Get-StepStatus -Name 'backend_quality') |",
    "| Release readiness | Android builds: $(Get-StepStatus -Name 'android_builds') |",
    "",
    "## QA Lanes",
    "",
    "| Lane | Status | Notes |",
    "| --- | --- | --- |",
    $resultRows,
    "",
    "## Critical Blockers",
    "",
    ($criticalBlockers | ForEach-Object { "- $_" }),
    "",
    "## High-Priority Fixes",
    "",
    ($highPriorityFixes | ForEach-Object { "- $_" }),
    "",
    "## Evidence",
    "",
    '- Flutter QA summary: `build/test_reports/production_validation/flutter_quality_summary.md`',
    '- Backend QA summary: `build/test_reports/production_validation/backend_quality_summary.md`',
    '- Validation Lab report: `validation/reports/latest_validation_report.md`',
    '- Android build summary: `build/test_reports/production_validation/android_builds_summary.md`',
    "",
    "## Notes",
    "",
    "- Automated validation runs in mock/default mode and does not call paid OpenAI/eBay/TCGPlayer/PriceCharting APIs.",
    "- Real AI accuracy and pricing agreement require manual/local validation with configured backend providers and licensed or user-owned images.",
    "- Crash-free sessions are not a local metric; they become meaningful after an observability provider is configured and beta testers generate sessions.",
    ""
  )

  $content | Set-Content -Path $dashboardPath
  $content | Set-Content -Path $docsReportPath
}

try {
  Invoke-ValidationStep -Name "flutter_quality" -Action {
    & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "run_flutter_quality.ps1") -ReportDir $ReportDir
  }

  Invoke-ValidationStep -Name "backend_quality" -Action {
    & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "run_backend_quality.ps1") -ReportDir $ReportDir
  }

  Invoke-ValidationStep -Name "validation_lab" -Action {
    $args = @(
      "-ManifestPath", $ValidationManifest,
      "-ReportsDir", $validationReportsDir,
      "-Endpoint", $ValidationEndpoint
    )
    if ($SkipValidationLabNetwork) {
      $args += "-DryRun"
    }
    & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "run_validation_lab.ps1") @args
  } -Required $false

  if (-not $SkipBuilds) {
    Invoke-ValidationStep -Name "android_builds" -Action {
      & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "run_android_builds.ps1") -ReportDir $ReportDir
    }
  } else {
    $results.Add([pscustomobject]@{
      Name = "android_builds"
      Status = "NOT RUN"
      Notes = "Skipped by caller."
      StartedAt = Get-Date
      FinishedAt = Get-Date
    }) | Out-Null
  }
} finally {
  Write-Dashboard
}

Write-Host "Production validation dashboard written to $dashboardPath"
Write-Host "Production validation report written to $docsReportPath"
