# GlobalPulse Macedonian Stock Exchange Free Market Announcements Candidate Notes

## Status

```text
MSE_FREE_MARKET_ANNOUNCEMENTS_MANUAL_SOURCE_REGISTERED
MSE_FREE_MARKET_ANNOUNCEMENTS_LOCAL_FIXTURE_PARSER_SMOKE_PASS
MSE_FREE_MARKET_ANNOUNCEMENTS_LIVE_PARSER_SMOKE_PASS
MSE_FREE_MARKET_ANNOUNCEMENTS_LIVE_ENDPOINT_PROBE_PASS
MSE_FREE_MARKET_ANNOUNCEMENTS_STAGING_LIVE_POLL_PENDING
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
1. Deploy to Fly staging after merge.
2. Poll manually with use_live_fetch=true and edition=breaking.
3. Verify source health remains bounded and active=false.
4. Check date-specific digest visibility under eu_south.
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
