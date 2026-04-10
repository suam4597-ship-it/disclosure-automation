param(
  [Parameter(Mandatory = $true)]
  [string]$ExtractedRoot
)

$ErrorActionPreference = "Stop"

function Find-WorkspaceRoot {
  param([string]$Root)

  $candidate = Join-Path $Root "disclosure-automation\apps\backend\disclosure_api\mix.exs"
  if (Test-Path $candidate) {
    return (Split-Path $candidate -Parent)
  }

  $found = Get-ChildItem -Path $Root -Recurse -Filter mix.exs -File |
    Where-Object { $_.FullName -like "*disclosure-automation*apps*backend*disclosure_api*" } |
    Select-Object -First 1

  if ($found) {
    return $found.DirectoryName
  }

  throw "Could not find extracted disclosure_api workspace under: $Root"
}

$repoRoot = Split-Path $PSScriptRoot -Parent
$target = Join-Path $repoRoot "apps\backend\disclosure_api"
$source = Find-WorkspaceRoot -Root $ExtractedRoot

Write-Host "Source: $source"
Write-Host "Target: $target"

if (-not (Test-Path $target)) {
  throw "Target repo path not found: $target"
}

Copy-Item -Path (Join-Path $source "*") -Destination $target -Recurse -Force

Write-Host "Overlay copy complete."
Write-Host "Next commands:"
Write-Host "  cd apps/backend/disclosure_api"
Write-Host "  mix format"
Write-Host "  mix deps.get"
Write-Host "  mix ecto.create"
Write-Host "  mix ecto.migrate"
Write-Host "  mix compile"
