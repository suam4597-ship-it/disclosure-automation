# GlobalPulse Macedonian Stock Exchange Free Market Announcements Candidate Notes

## Status

```text
MSE_FREE_MARKET_ANNOUNCEMENTS_MANUAL_SOURCE_REGISTERED
MSE_FREE_MARKET_ANNOUNCEMENTS_LOCAL_FIXTURE_PARSER_SMOKE_PASS
MSE_FREE_MARKET_ANNOUNCEMENTS_LIVE_PARSER_SMOKE_PASS
MSE_FREE_MARKET_ANNOUNCEMENTS_LIVE_ENDPOINT_PROBE_PASS
MSE_FREE_MARKET_ANNOUNCEMENTS_STAGING_LIVE_POLL_PASS
MSE_FREE_MARKET_ANNOUNCEMENTS_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
MSE_FREE_MARKET_ANNOUNCEMENTS_LATEST_PUBLIC_UI_VISIBILITY_PENDING
MSE_FREE_MARKET_ANNOUNCEMENTS_SCHEDULED_POLLING_DISABLED
```

## Candidate

```text
source_key: mk_mse_free_market_announcements
owner: Macedonian Stock Exchange
authority class: official exchange issuer announcement surface
candidate URL: https://www.mse.mk/Issuers.aspx
observed HTTP: 200
observed content-type: text/html; charset=utf-8
observed shape: bounded HTML list under "Announcements from companies on the Free Market"
parser: mse_free_market_announcements_html_v1
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
```

## Why This Fits

```text
The page is operated by the Macedonian Stock Exchange and exposes issuer announcement rows.
Rows include publication date, issuer name, announcement type, and an official MSE announcement URL.
This is listed-company/issuer disclosure material, not a central-bank, macro, parliament, or policy-news feed.
The first integration is intentionally limited to the bounded latest Free Market announcements list on the public Issuers page.
```

## Bounded Implementation

```text
Parser extracts only:
- announcement URL
- publication date
- issuer/title text
- announcement category text

Parser does not fetch attachment/detail pages.
Parser does not expose raw HTML, cookies, headers, tokens, or private material.
The source remains active=false and cannot enter scheduled polling until separate staging smoke evidence and batch-promotion approval exist.
```

## Local And Live Parser Smoke

```text
local fixture parser smoke: PASS
local fixture records: 3
live parser smoke: PASS
live observed HTTP: 200
live observed content-type: text/html; charset=utf-8
live observed bytes: 134,203
live records kept by parser capability limit: 25
first live row title: ZIK Gradiste AD Kumanovo - Financial data and dividends
first live row published_at: 2026-05-08T00:00:00Z
```

## Next Verification

```text
1. Keep source active=false.
2. Keep scheduled polling disabled.
3. Re-check latest public UI visibility when the public digest date/top-N selection includes MSE rows.
4. Consider this source only inside the broader Europe batch-promotion gate.
```

## Staging Smoke

```text
Fly staging live poll: PASS
deploy commit: 009aa66a5cb366a47905f87d71b348f1e1822133
poll endpoint: POST /api/admin/sources/mk_mse_free_market_announcements/poll?use_live_fetch=true&edition=breaking
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 134203
records_seen: 25
records_inserted: 25
source health: healthy
active: false
date-specific digest visibility: PASS for 2026-05-06 and 2026-05-05 under eu_south
latest public UI visibility: pending because latest public digest currently renders 2026-05-09 while the latest MSE row is 2026-05-08
```

## Guardrails

```text
Do not enable scheduled polling.
Do not set active=true.
Do not treat MSE general exchange news as listed-company disclosures.
Do not add public poll UI, audit UI, or public Source Health UI.
Do not change backend digest JSON response shape.
Do not claim staging live success from fixture fallback.
```
