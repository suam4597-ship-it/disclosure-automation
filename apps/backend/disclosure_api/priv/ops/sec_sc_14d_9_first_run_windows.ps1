param(
  [string]$RepoAppPath = (Get-Location).Path,
  [string]$PostgresUser = "postgres",
  [string]$PostgresPassword = "postgres",
  [string]$PostgresHost = "localhost",
  [string]$PostgresDb = "disclosure_automation_dev",
  [string]$PostgresTestDb = "disclosure_automation_test"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step([string]$Message) {
  Write-Host ""
  Write-Host "=== $Message ===" -ForegroundColor Cyan
}

function Invoke-Bat([string]$CommandLine) {
  Write-Host "> $CommandLine"
  & cmd.exe /c $CommandLine

  if ($LASTEXITCODE -ne 0) {
    throw "command failed with exit code $LASTEXITCODE: $CommandLine"
  }
}

function Wait-ForHealth([string]$Url, [int]$TimeoutSeconds = 90) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

  while ((Get-Date) -lt $deadline) {
    try {
      $response = Invoke-RestMethod -Uri $Url -Method GET -TimeoutSec 5

      if ($response.status -eq "ok") {
        return $response
      }
    } catch {
      Start-Sleep -Seconds 2
    }
  }

  throw "server did not become healthy within $TimeoutSeconds seconds: $Url"
}

function Resolve-PsqlPath() {
  $command = Get-Command psql.exe -ErrorAction SilentlyContinue

  if ($command) {
    return $command.Source
  }

  $candidates = @(
    "C:\Program Files\PostgreSQL\16\bin\psql.exe",
    "C:\Program Files\PostgreSQL\17\bin\psql.exe",
    "C:\Program Files\PostgreSQL\15\bin\psql.exe",
    "C:\Program Files\PostgreSQL\14\bin\psql.exe"
  )

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  throw "psql.exe not found. Install PostgreSQL client tools or add psql.exe to PATH."
}

function Invoke-PsqlCsv([string]$Sql) {
  $psqlPath = Resolve-PsqlPath
  $env:PGPASSWORD = $PostgresPassword

  $output = & $psqlPath -h $PostgresHost -U $PostgresUser -d $PostgresDb -t -A -F "," -c $Sql

  if ($LASTEXITCODE -ne 0) {
    throw "psql validation failed with exit code $LASTEXITCODE"
  }

  return ($output | Out-String).Trim()
}

if (-not (Test-Path (Join-Path $RepoAppPath "mix.bat"))) {
  throw "mix.bat not found under RepoAppPath: $RepoAppPath"
}

$env:POSTGRES_USER = $PostgresUser
$env:POSTGRES_PASSWORD = $PostgresPassword
$env:POSTGRES_HOST = $PostgresHost
$env:POSTGRES_DB = $PostgresDb
$env:POSTGRES_TEST_DB = $PostgresTestDb

$serverProcess = $null

Push-Location $RepoAppPath

try {
  Write-Step "Running mix.bat setup"
  Remove-Item Env:MIX_ENV -ErrorAction SilentlyContinue
  Invoke-Bat "mix.bat setup"

  Write-Step "Running isolated SC 14D-9 test gate"
  $env:MIX_ENV = "test"
  Invoke-Bat "mix.bat test test/sec_sc_14d_9_runtime_idempotency_test.exs"
  Invoke-Bat "mix.bat test test/sec_sc_14d_9_http_smoke_test.exs"

  Write-Step "Resetting dev database"
  $env:MIX_ENV = "dev"
  Invoke-Bat "mix.bat ecto.reset"

  Write-Step "Starting isolated SC 14D-9 dev server"
  $serverCommand = @(
    "set POSTGRES_USER=$PostgresUser",
    "set POSTGRES_PASSWORD=$PostgresPassword",
    "set POSTGRES_HOST=$PostgresHost",
    "set POSTGRES_DB=$PostgresDb",
    "set MIX_ENV=dev",
    "mix.bat run --no-start priv/ops/run_sec_sc_14d_9_server.exs"
  ) -join " && "

  $serverProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $serverCommand" -WorkingDirectory $RepoAppPath -WindowStyle Hidden -PassThru

  $health = Wait-ForHealth -Url "http://127.0.0.1:4000/api/health"
  Write-Host ("health status: " + $health.status)

  Write-Step "Running HTTP smoke sequence"
  $pollUrl = "http://127.0.0.1:4000/api/admin/sources/sec_current_forms/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
  $digestUrl = "http://127.0.0.1:4000/api/feed/digest/latest?edition=breaking"

  $poll1 = Invoke-RestMethod -Uri $pollUrl -Method POST
  $digest1 = Invoke-RestMethod -Uri $digestUrl -Method GET
  $poll2 = Invoke-RestMethod -Uri $pollUrl -Method POST
  $digest2 = Invoke-RestMethod -Uri $digestUrl -Method GET

  if ($poll1.records_seen -ne 1) {
    throw "first poll records_seen was $($poll1.records_seen), expected 1"
  }

  if ($poll2.records_seen -ne 1) {
    throw "second poll records_seen was $($poll2.records_seen), expected 1"
  }

  if ($digest1.item_count -ne 1) {
    throw "first digest item_count was $($digest1.item_count), expected 1"
  }

  if ($digest2.item_count -ne 1) {
    throw "second digest item_count was $($digest2.item_count), expected 1"
  }

  $item1 = $digest1.items[0]
  $item2 = $digest2.items[0]

  if ($item1.event_id -ne $item2.event_id) {
    throw "event_id changed across repeated poll: '$($item1.event_id)' vs '$($item2.event_id)'"
  }

  if ([string]::IsNullOrWhiteSpace($item1.event_family)) {
    throw "event_family was empty on first digest item"
  }

  if ([string]::IsNullOrWhiteSpace($item1.canonical_event_type)) {
    throw "canonical_event_type was empty on first digest item"
  }

  if ($item1.event_family -ne $item2.event_family) {
    throw "event_family changed across repeated poll: '$($item1.event_family)' vs '$($item2.event_family)'"
  }

  if ($item1.canonical_event_type -ne $item2.canonical_event_type) {
    throw "canonical_event_type changed across repeated poll: '$($item1.canonical_event_type)' vs '$($item2.canonical_event_type)'"
  }

  Write-Host ("event_id: " + $item1.event_id)
  Write-Host ("event_family: " + $item1.event_family)
  Write-Host ("canonical_event_type: " + $item1.canonical_event_type)
  Write-Host ("published_at_local: " + $item1.published_at_local)
  Write-Host ("published_at_utc: " + $item1.published_at_utc)
  Write-Host ("filing_date_local: " + $item1.filing_date_local)

  Write-Step "Running storage-level dedupe validation"
  $validationSql = @"
WITH
q1 AS (
  SELECT 1
  FROM raw_documents
  GROUP BY source_registry_id, external_id
  HAVING COUNT(*) > 1
),
q2 AS (
  SELECT 1
  FROM raw_documents
  GROUP BY source_registry_id, document_identity, document_type
  HAVING COUNT(*) > 1
),
q3 AS (
  SELECT 1
  FROM raw_events
  GROUP BY source_registry_id, event_key
  HAVING COUNT(*) > 1
),
q4 AS (
  SELECT 1
  FROM canonical_feed_items
  GROUP BY event_id
  HAVING COUNT(*) > 1
),
q5 AS (
  SELECT 1
  FROM canonical_item_sources
  GROUP BY canonical_feed_item_id, raw_event_id, source_role
  HAVING COUNT(*) > 1
),
q6 AS (
  SELECT 1
  FROM canonical_item_sources
  GROUP BY canonical_feed_item_id
  HAVING COUNT(*) FILTER (WHERE is_representative = true) > 1
),
q7 AS (
  SELECT external_id, COUNT(*) AS row_count
  FROM raw_documents
  WHERE external_id IN ('0001409999-26-000321:submission-text', '0001409999-26-000321:detail-index')
  GROUP BY external_id
)
SELECT
  (SELECT COUNT(*) FROM q1) AS q1_fail_rows,
  (SELECT COUNT(*) FROM q2) AS q2_fail_rows,
  (SELECT COUNT(*) FROM q3) AS q3_fail_rows,
  (SELECT COUNT(*) FROM q4) AS q4_fail_rows,
  (SELECT COUNT(*) FROM q5) AS q5_fail_rows,
  (SELECT COUNT(*) FROM q6) AS q6_fail_rows,
  (SELECT COUNT(*) FROM q7) AS q7_rows,
  (SELECT COUNT(*) FROM q7 WHERE row_count = 1) AS q7_good_rows;
"@

  $validationRow = Invoke-PsqlCsv -Sql $validationSql
  $parts = $validationRow.Split(",")

  if ($parts.Count -ne 8) {
    throw "unexpected validation output: $validationRow"
  }

  $q1Fail = [int]$parts[0]
  $q2Fail = [int]$parts[1]
  $q3Fail = [int]$parts[2]
  $q4Fail = [int]$parts[3]
  $q5Fail = [int]$parts[4]
  $q6Fail = [int]$parts[5]
  $q7Rows = [int]$parts[6]
  $q7GoodRows = [int]$parts[7]

  if ($q1Fail -ne 0 -or $q2Fail -ne 0 -or $q3Fail -ne 0 -or $q4Fail -ne 0 -or $q5Fail -ne 0 -or $q6Fail -ne 0) {
    throw "dedupe duplicate checks failed: $validationRow"
  }

  if ($q7Rows -ne 2 -or $q7GoodRows -ne 2) {
    throw "dedupe spot-check failed: $validationRow"
  }

  Write-Host ("dedupe summary: " + $validationRow)
  Write-Step "SC 14D-9 first run PASSED"
} finally {
  if ($serverProcess -and -not $serverProcess.HasExited) {
    Stop-Process -Id $serverProcess.Id -Force
  }

  Pop-Location
}
