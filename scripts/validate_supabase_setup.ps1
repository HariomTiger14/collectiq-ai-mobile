param(
  [switch]$Live
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$scriptPath = Join-Path $repoRoot "scripts\validate_supabase_setup.py"

$arguments = @($scriptPath)
if ($Live) {
  $arguments += "--live"
}

py @arguments
