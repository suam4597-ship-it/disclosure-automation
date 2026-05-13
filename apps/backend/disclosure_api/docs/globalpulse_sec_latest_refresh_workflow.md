# GlobalPulse SEC Latest Refresh Workflow

Date: 2026-05-14

## Purpose

This runbook gives operators a bounded way to refresh the latest U.S. SEC investment-idea feed in staging.

It is designed for the current GlobalPulse public dashboard workflow:

```text
SEC source poll
-> canonical digest rows
-> /api/feed/digest/latest?edition=breaking
-> public GlobalPulse UI
```

## Guardrails

- Use Fly staging first.
- Do not enable production scheduled SEC polling from this workflow.
- Do not add public poll UI.
- Do not add public Source Health UI.
- Do not change backend digest JSON response shape.
- Prefer async polling for heavy SEC sources.
- Treat scores and summaries as idea-discovery aids, not investment recommendations.

## Current Staging Endpoints

```text
backend/API base:
https://globalpulse-backend-staging.fly.dev

public Pages UI:
https://suam4597-ship-it.github.io/disclosure-automation/
```

## Recommended Refresh Order

Run lighter or highest-signal sources first, then heavier sources through the slow lane.

```text
1. sec_edgar_current_8k_filings
2. sec_edgar_form4_clustered_insider_buys
3. sec_edgar_13f_institutional_accumulation
4. sec_edgar_current_schedule_to_tender_offers
5. sec_edgar_current_13d_activist_ownership
6. sec_edgar_current_13g_increased_ownership
7. sec_edgar_current_s4_merger_registration_statements
8. sec_edgar_current_f4_merger_registration_statements
9. sec_edgar_current_s1_registration_statements
10. sec_edgar_current_f1_registration_statements
11. sec_edgar_current_10q_reports
12. sec_edgar_current_10k_reports
```

## PowerShell Command Template

From any local environment with network access:

```powershell
$api = "https://globalpulse-backend-staging.fly.dev"
$edition = "breaking"

$sources = @(
  "sec_edgar_current_8k_filings",
  "sec_edgar_form4_clustered_insider_buys",
  "sec_edgar_13f_institutional_accumulation",
  "sec_edgar_current_schedule_to_tender_offers",
  "sec_edgar_current_13d_activist_ownership",
  "sec_edgar_current_13g_increased_ownership",
  "sec_edgar_current_s4_merger_registration_statements",
  "sec_edgar_current_f4_merger_registration_statements",
  "sec_edgar_current_s1_registration_statements",
  "sec_edgar_current_f1_registration_statements",
  "sec_edgar_current_10q_reports",
  "sec_edgar_current_10k_reports"
)

Invoke-RestMethod -Uri "$api/api/health" -Method Get

foreach ($source in $sources) {
  $uri = "$api/api/admin/sources/$source/poll?use_live_fetch=true&edition=$edition&async=true"
  Write-Host "Polling $source"
  Invoke-RestMethod -Uri $uri -Method Post
  Start-Sleep -Seconds 2
}

Start-Sleep -Seconds 20
Invoke-RestMethod -Uri "$api/api/feed/digest/latest?edition=$edition&region=us&limit=100&recent_date_limit=10" -Method Get
```

## Success Criteria

For each source poll response:

```text
HTTP status: 202 accepted or bounded 200 result
operation: source_poll
fetch.mode: live when available
fallback_to_fixture: false for live success claims
no Fly proxy timeout
no OOM restart
```

For the digest:

```text
GET /api/feed/digest/latest?edition=breaking&region=us -> 200
items include U.S. SEC sources
positive_signal_score metadata appears when scoring config applies
public UI shows SEC tabs and signal badges after Pages deploy
raw filings, cookies, tokens, headers, or private auth material are not exposed
```

## UI Verification Checklist

Open:

```text
https://suam4597-ship-it.github.io/disclosure-automation/
```

Verify:

```text
Backend ok
미국 region visible
투자 시그널 tab visible
전략/계약 tab visible
M&A/공개매수 tab visible
지분/기관 tab visible
내부자 tab visible
실적 tab visible
IPO tab visible
signal badges visible for scored SEC items
복합 시그널 badge visible when the same issuer has multiple SEC signal types in the current digest
detail page keeps Korean label/value summary rows
browser console has no fatal fetch/CORS errors
```

## When To Stop

Stop and record an observation instead of retrying aggressively if:

```text
SEC returns repeated 429/403 responses
Fly app shows memory pressure or restarts
poll response returns bounded 409/429/5xx repeatedly
digest endpoint returns repeated 500 responses after retry
source starts falling back to fixture while claiming live refresh
```

## Follow-Up Work Queue

Recommended next SEC improvements:

```text
1. Add a bounded operator command/script around this runbook if manual refresh becomes frequent.
2. Tune positive_signal_score values after observing false positives and missed ideas.
3. Add source-specific smoke records for the first successful refresh of each newly added SEC source.
4. Consider backend-side composite signal materialization after the UI grouping proves useful.
5. Add optional stale-digest alerting for U.S. SEC region if public digest freshness becomes important.
```

