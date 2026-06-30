param(
  [string]$ManifestPath = "",
  [string]$ImageDir = "",
  [string]$Endpoint = "http://127.0.0.1:8000/api/analyze",
  [string]$ReportsDir = "",
  [string]$UserImageFolder = "",
  [string]$KagglePath = "",
  [string]$HuggingFaceExport = "",
  [switch]$PrepareOnly,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$pythonScript = Join-Path $root "backend\scripts\prepare_validation_dataset.py"
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
  $ManifestPath = Join-Path $root "validation\manifests\sample_manifest.json"
}
if ([string]::IsNullOrWhiteSpace($ImageDir)) {
  $ImageDir = Join-Path $root "validation\images"
}
if ([string]::IsNullOrWhiteSpace($ReportsDir)) {
  $ReportsDir = Join-Path $root "validation\reports"
}

New-Item -ItemType Directory -Force $ImageDir | Out-Null
New-Item -ItemType Directory -Force (Split-Path -Parent $ManifestPath) | Out-Null
New-Item -ItemType Directory -Force $ReportsDir | Out-Null

$prepareArgs = @(
  $pythonScript,
  "prepare",
  "--output-manifest",
  $ManifestPath,
  "--copy-images-to",
  $ImageDir
)

if (-not [string]::IsNullOrWhiteSpace($UserImageFolder)) {
  $prepareArgs += @("--image-folder", $UserImageFolder)
}
if (-not [string]::IsNullOrWhiteSpace($KagglePath)) {
  $prepareArgs += @("--kaggle-path", $KagglePath)
}
if (-not [string]::IsNullOrWhiteSpace($HuggingFaceExport)) {
  $prepareArgs += @("--hugging-face-export", $HuggingFaceExport)
}

if (-not [string]::IsNullOrWhiteSpace($UserImageFolder) -or
    -not [string]::IsNullOrWhiteSpace($KagglePath) -or
    -not [string]::IsNullOrWhiteSpace($HuggingFaceExport)) {
  py @prepareArgs
}

if ($PrepareOnly) {
  exit $LASTEXITCODE
}

$runArgs = @(
  $pythonScript,
  "run",
  "--manifest",
  $ManifestPath,
  "--image-dir",
  $ImageDir,
  "--reports-dir",
  $ReportsDir,
  "--endpoint",
  $Endpoint
)
if ($DryRun) {
  $runArgs += "--dry-run"
}

py @runArgs
exit $LASTEXITCODE
