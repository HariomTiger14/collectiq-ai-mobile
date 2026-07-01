param(
  [string]$SourceImageFolder = "",
  [string]$Metadata = "",
  [string]$Endpoint = "http://127.0.0.1:8000/api/analyze",
  [switch]$RunFullValidation,
  [switch]$RunProductionDashboard
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$localImageDir = Join-Path $root "validation\images\local_sample"
$manifestPath = Join-Path $root "validation\manifests\local_sample_manifest.json"
$reportsDir = Join-Path $root "validation\reports"
$firstRunReport = Join-Path $root "docs\FIRST_VALIDATION_RUN_REPORT.md"
$supportedExtensions = @(".jpg", ".jpeg", ".png", ".webp")

New-Item -ItemType Directory -Force $localImageDir | Out-Null
New-Item -ItemType Directory -Force (Split-Path -Parent $manifestPath) | Out-Null
New-Item -ItemType Directory -Force $reportsDir | Out-Null
New-Item -ItemType Directory -Force (Split-Path -Parent $firstRunReport) | Out-Null

function Get-LocalImages {
  if (-not (Test-Path $localImageDir)) {
    return @()
  }
  return @(
    Get-ChildItem -Path $localImageDir -File -Recurse |
      Where-Object { $supportedExtensions -contains $_.Extension.ToLowerInvariant() }
  )
}

function Read-ManifestRows {
  if (-not (Test-Path $manifestPath)) {
    return @()
  }
  $raw = Get-Content $manifestPath -Raw
  if ([string]::IsNullOrWhiteSpace($raw)) {
    return @()
  }
  $parsed = $raw | ConvertFrom-Json
  if ($null -eq $parsed) {
    return @()
  }
  return @($parsed)
}

function Test-ManifestCompleteness {
  param([array]$Rows)

  $missing = New-Object System.Collections.Generic.List[string]
  foreach ($row in $Rows) {
    $filename = [string]$row.filename
    if ([string]::IsNullOrWhiteSpace($filename)) {
      $missing.Add("A manifest row is missing filename.") | Out-Null
      continue
    }
    foreach ($field in @("expected_name", "expected_category")) {
      $value = [string]$row.$field
      if ([string]::IsNullOrWhiteSpace($value)) {
        $missing.Add("$filename is missing $field.") | Out-Null
      }
    }
  }
  return $missing
}

function Convert-ValidationCsvToMetrics {
  $csv = Join-Path $reportsDir "latest_validation_results.csv"
  $metrics = [ordered]@{
    TotalImages = 0
    TotalAnalyzed = 0
    CategoryAccuracy = "n/a"
    NameMatchAccuracy = "n/a"
    ConfidenceDistribution = "n/a"
    PricingFallbackUsage = "n/a"
    AverageLatency = "n/a"
    Failures = 0
  }
  if (-not (Test-Path $csv)) {
    return $metrics
  }

  $rows = @(Import-Csv $csv)
  $passed = @($rows | Where-Object { $_.status -eq "passed" })
  $metrics.TotalImages = $rows.Count
  $metrics.TotalAnalyzed = $passed.Count
  $metrics.Failures = @($rows | Where-Object { $_.status -in @("failed", "missing_image") }).Count

  if ($passed.Count -gt 0) {
    $categoryMatches = @($passed | Where-Object { $_.category_match -eq "True" }).Count
    $nameMatches = @($passed | Where-Object { $_.name_keyword_match -eq "True" }).Count
    $metrics.CategoryAccuracy = "{0:P1}" -f ($categoryMatches / [double]$passed.Count)
    $metrics.NameMatchAccuracy = "{0:P1}" -f ($nameMatches / [double]$passed.Count)

    $confidenceValues = @(
      $passed |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_.confidence) } |
        ForEach-Object { [double]$_.confidence }
    )
    if ($confidenceValues.Count -gt 0) {
      $high = @($confidenceValues | Where-Object { $_ -ge 90 }).Count
      $medium = @($confidenceValues | Where-Object { $_ -ge 70 -and $_ -lt 90 }).Count
      $low = @($confidenceValues | Where-Object { $_ -lt 70 }).Count
      $metrics.ConfidenceDistribution = "High: $high, Medium: $medium, Low: $low"
    }

    $latencyValues = @(
      $passed |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_.latency_ms) } |
        ForEach-Object { [double]$_.latency_ms }
    )
    if ($latencyValues.Count -gt 0) {
      $metrics.AverageLatency = "{0:N0} ms" -f (($latencyValues | Measure-Object -Average).Average)
    }

    $fallbacks = @($passed | Where-Object { -not [string]::IsNullOrWhiteSpace($_.fallback_reason) }).Count
    $metrics.PricingFallbackUsage = "$fallbacks of $($passed.Count) analyzed result(s)"
  }

  return $metrics
}

function Write-FirstRunReport {
  param(
    [int]$ImageCount,
    [array]$ManifestRows,
    [System.Collections.Generic.List[string]]$MissingLabels,
    [string]$DryRunStatus,
    [string]$FullRunStatus
  )

  $metrics = Convert-ValidationCsvToMetrics
  $nextSteps = if ($ImageCount -eq 0) {
    @(
      "1. Create or choose a local folder with 20-50 user-owned or open/licensed collectible images.",
      "2. Prefer a balanced mix: Pokemon/TCG cards, sports cards, coins, comics, and memorabilia.",
      "3. Run:",
      '   ```powershell',
      "   scripts\run_first_validation_dataset.ps1 -SourceImageFolder C:\path\to\your\images",
      '   ```',
      '4. Open `validation\manifests\local_sample_manifest.json` and fill `expected_name`, `expected_category`, `expected_brand`, `expected_set`, and `expected_year` where known.',
      "5. Start the backend in mock mode:",
      '   ```powershell',
      "   cd backend",
      "   `$env:AI_PROVIDER='mock'",
      "   `$env:PRICING_PROVIDER='mock'",
      "   py -m uvicorn app.main:app --host 0.0.0.0 --port 8000",
      '   ```',
      "6. In a second terminal, run:",
      '   ```powershell',
      "   scripts\run_first_validation_dataset.ps1 -RunFullValidation -RunProductionDashboard",
      '   ```'
    )
  } elseif ($MissingLabels.Count -gt 0) {
    @(
      "1. Fill the missing required labels listed below before treating metrics as meaningful.",
      '2. Required fields for scoring are `expected_name` and `expected_category`.',
      '3. Rerun with `-RunFullValidation` after the backend is running.'
    )
  } else {
    @(
      '1. Review misclassified images in `validation\reports\latest_validation_results.csv`.',
      "2. Add 20-50 more images before prompt/pricing tuning.",
      "3. Run real-provider validation locally only after backend API keys are configured server-side."
    )
  }

  $manifestCompletenessLines = if ($MissingLabels.Count -eq 0) {
    @("- Required labels are complete for current manifest rows.")
  } else {
    @($MissingLabels | ForEach-Object { "- $_" })
  }

  @(
    "# First Validation Dataset Run Report",
    "",
    "- Generated: $(Get-Date -Format o)",
    '- Image folder: `validation/images/local_sample/`',
    '- Manifest: `validation/manifests/local_sample_manifest.json`',
    "- Endpoint: $Endpoint",
    "",
    "## Status",
    "",
    "- Images found: $ImageCount",
    "- Manifest rows: $($ManifestRows.Count)",
    "- Dry-run validation: $DryRunStatus",
    "- Full validation: $FullRunStatus",
    "",
    "## Metrics",
    "",
    "| Metric | Value |",
    "| --- | --- |",
    "| Total images found | $ImageCount |",
    "| Total analyzed | $($metrics.TotalAnalyzed) |",
    "| Category accuracy | $($metrics.CategoryAccuracy) |",
    "| Name match accuracy | $($metrics.NameMatchAccuracy) |",
    "| Confidence distribution | $($metrics.ConfidenceDistribution) |",
    "| Pricing fallback usage | $($metrics.PricingFallbackUsage) |",
    "| Average latency | $($metrics.AverageLatency) |",
    "| Failures | $($metrics.Failures) |",
    "",
    "## Manifest Completeness",
    "",
    $manifestCompletenessLines,
    "",
    "## Next Tuning Recommendations",
    "",
    $nextSteps,
    "",
    "## Safety Notes",
    "",
    "- Do not commit image files.",
    "- Do not scrape Google, eBay, marketplaces, or seller listings.",
    "- Use user-owned, public-domain, or explicitly open/licensed images only.",
    "- Automated validation must remain mock/default unless you intentionally run a local backend with real providers.",
    ""
  ) | Set-Content -Path $firstRunReport
}

if (-not (Test-Path $manifestPath)) {
  "[]" | Set-Content -Path $manifestPath
}

if (-not [string]::IsNullOrWhiteSpace($SourceImageFolder)) {
  if (-not (Test-Path $SourceImageFolder)) {
    throw "SourceImageFolder not found: $SourceImageFolder"
  }
  $importArgs = @(
    "-ImageFolder", $SourceImageFolder,
    "-OutputManifest", $manifestPath,
    "-SourceName", "Local first validation sample",
    "-License", "user-owned-or-open",
    "-CopyImagesTo", $localImageDir
  )
  if (-not [string]::IsNullOrWhiteSpace($Metadata)) {
    $importArgs += @("-Metadata", $Metadata)
  }
  & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "import_validation_dataset.ps1") @importArgs
  if ($LASTEXITCODE -ne 0) {
    throw "Dataset import failed."
  }
}

$images = Get-LocalImages
$manifestRows = Read-ManifestRows
$missingLabels = Test-ManifestCompleteness -Rows $manifestRows

$dryRunStatus = "PASS"
try {
  & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "run_validation_lab.ps1") `
    -ManifestPath $manifestPath `
    -ImageDir $localImageDir `
    -ReportsDir $reportsDir `
    -Endpoint $Endpoint `
    -DryRun
  if ($LASTEXITCODE -ne 0) {
    $dryRunStatus = "FAIL"
  }
} catch {
  $dryRunStatus = "FAIL: $_"
}

$fullRunStatus = "SKIPPED"
if ($RunFullValidation) {
  if ($images.Count -eq 0) {
    $fullRunStatus = "SKIPPED: no images found"
  } elseif ($missingLabels.Count -gt 0) {
    $fullRunStatus = "SKIPPED: manifest labels incomplete"
  } else {
    try {
      & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "run_validation_lab.ps1") `
        -ManifestPath $manifestPath `
        -ImageDir $localImageDir `
        -ReportsDir $reportsDir `
        -Endpoint $Endpoint
      $fullRunStatus = if ($LASTEXITCODE -eq 0) { "PASS" } else { "FAIL" }
    } catch {
      $fullRunStatus = "FAIL: $_"
    }
  }
}

if ($RunProductionDashboard) {
  $dashboardArgs = @(
    "-ValidationManifest", $manifestPath,
    "-ValidationEndpoint", $Endpoint
  )
  if ($images.Count -eq 0 -or -not $RunFullValidation) {
    $dashboardArgs += "-SkipValidationLabNetwork"
  }
  & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "run_production_validation_dashboard.ps1") @dashboardArgs
}

Write-FirstRunReport `
  -ImageCount $images.Count `
  -ManifestRows $manifestRows `
  -MissingLabels $missingLabels `
  -DryRunStatus $dryRunStatus `
  -FullRunStatus $fullRunStatus

Write-Host "Images found: $($images.Count)"
Write-Host "Manifest rows: $($manifestRows.Count)"
Write-Host "Dry-run validation: $dryRunStatus"
Write-Host "Full validation: $fullRunStatus"
Write-Host "First validation report written to $firstRunReport"
