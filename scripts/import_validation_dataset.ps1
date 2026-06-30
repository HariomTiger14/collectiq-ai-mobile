param(
  [string]$ImageFolder = "",
  [string]$Metadata = "",
  [string]$OutputManifest = "",
  [string]$SourceName = "",
  [string]$License = "",
  [string]$CopyImagesTo = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$importer = Join-Path $root "backend\scripts\import_validation_dataset.py"
if ([string]::IsNullOrWhiteSpace($OutputManifest)) {
  $OutputManifest = Join-Path $root "validation\manifests\generated_manifest.json"
}

$arguments = @(
  $importer,
  "--output-manifest",
  $OutputManifest
)

if (-not [string]::IsNullOrWhiteSpace($ImageFolder)) {
  $arguments += @("--image-folder", $ImageFolder)
}
if (-not [string]::IsNullOrWhiteSpace($Metadata)) {
  $arguments += @("--metadata", $Metadata)
}
if (-not [string]::IsNullOrWhiteSpace($SourceName)) {
  $arguments += @("--source-name", $SourceName)
}
if (-not [string]::IsNullOrWhiteSpace($License)) {
  $arguments += @("--license", $License)
}
if (-not [string]::IsNullOrWhiteSpace($CopyImagesTo)) {
  $arguments += @("--copy-images-to", $CopyImagesTo)
}

py @arguments
exit $LASTEXITCODE
