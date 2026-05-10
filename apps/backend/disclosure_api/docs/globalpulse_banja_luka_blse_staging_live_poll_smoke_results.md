# GlobalPulse Banja Luka BLSE Staging Live Poll Smoke Results

This document records the first Fly staging live-poll smoke for the Banja Luka Stock Exchange issuer-news multi-code candidate.

The smoke keeps the source manual-only. It does not enable scheduled polling, does not set the source active, does not change backend digest JSON shape, and does not add frontend UI, poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_BANJA_LUKA_BLSE_STAGING_DEPLOY_PASS
BANJA_LUKA_BLSE_SOURCE_HEALTH_MANUAL_ONLY_PASS
BANJA_LUKA_BLSE_LIVE_POLL_PASS
BANJA_LUKA_BLSE_LIVE_FIXTURE_FALLBACK_DISABLED_PASS
BANJA_LUKA_BLSE_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
BANJA_LUKA_BLSE_LATEST_PUBLIC_UI_VISIBILITY_PENDING
BANJA_LUKA_BLSE_SCHEDULED_POLLING_DISABLED
```

## Context

```text
source_key: ba_blse_issuer_news_multi_code
display_name: Banja Luka Stock Exchange Issuer News Multi-Code
parser_key: blse_multi_issuer_news_rss_v1
ticker URL: https://services.blberza.com/blse/ticker.ashx?LangId=3&TickerTypeId=1&filter=all&ct=xml
issuer RSS template: https://www.blberza.com/pages/IssuerNewsRss.aspx?Code={code}&LangId=3
authority: Banja Luka Stock Exchange
PR: #471 Add Banja Luka BLSE issuer news candidate
phase0-foundation deploy commit: 3032c738e01315bb61ee1c075a31fbb05ca2f739
Fly app: globalpulse-backend-staging
smoke date: 2026-05-10
```

## Fly Deploy

```text
command: fly deploy --remote-only --app globalpulse-backend-staging
deploy: PASS
release_command: PASS
app URL: https://globalpulse-backend-staging.fly.dev/
```

## Health Check

```text
GET /api/health
status: 200
response: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

## Source Health

```text
GET /api/admin/source-health/ba_blse_issuer_news_multi_code
status: 200
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
health_status: healthy
last_seen_published_at: 2026-05-08T08:55:17.000000Z
last_success_at: 2026-05-10T13:38:22.631900Z
last_error: null
```

## Live Poll

```text
POST /api/admin/sources/ba_blse_issuer_news_multi_code/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.ticker_status_code: 200
fetch.bytes: 67200
fetch.strategy: blse_multi_issuer_news_rss_v1
universe_count: 14
selected_issuer_count: 5
selected_issuer_window_strategy: static_offset
selected_issuer_window_offset: 0
selected_issuer_window_size: 5
issuer_request_count: 5
fetch.records_seen: 75
records_seen: 25
records_inserted: 25
fixture fallback: disabled by source config and not used
```

Selected canonical item examples:

```text
breaking-2026-05-08-blse-ekbl-r-a-114897
breaking-2026-05-04-blse-tlkm-r-a-114854
breaking-2026-04-30-blse-ekbl-r-a-114851
breaking-2026-04-28-blse-tlkm-r-a-114767
breaking-2026-04-23-blse-snel-r-a-114735
```

## Digest Visibility

Latest digest remains 2026-05-09 and does not currently include BLSE because the BLSE rows in the bounded issuer window are dated 2026-05-08 or earlier. Date-specific digest visibility passed for BLSE rows:

```text
GET /api/feed/digest/2026-05-04/breaking
status: 200
metadata.fallback_to_fixture: false
visible BLSE row: Telekom Srpske a.d. Banja Luka - Financial Statement for the Q1 2026
regions: eu_south
fetch_mode: live
```

```text
GET /api/feed/digest/2026-04-30/breaking
status: 200
metadata.fallback_to_fixture: false
visible BLSE row: Elektrokrajina a.d. Banja Luka - Financial Statement for the Q1 2026
regions: eu_south
fetch_mode: live
```

```text
GET /api/feed/digest/2026-04-28/breaking
status: 200
metadata.fallback_to_fixture: false
visible BLSE row: Telekom Srpske a.d. Banja Luka - The Auditor's report for the FY 2025
regions: eu_south
fetch_mode: live
```

```text
GET /api/feed/digest/2026-04-22/breaking
status: 200
metadata.fallback_to_fixture: false
visible BLSE rows:
- Elektrokrajina a.d. Banja Luka - Announcement about results of the 2nd share issue
- Elektrokrajina a.d. Banja Luka - Decision on the ending public offering of shares
regions: eu_south
fetch_mode: live
```

## Guardrails

```text
scheduled polling enabled: no
source active=true: no
EU scheduled canary inclusion: no
backend digest JSON shape changed: no
frontend framework added: no
public poll UI added: no
audit UI added: no
public Source Health UI added: no
detail fetch / attachment fetch controls added: no
```
