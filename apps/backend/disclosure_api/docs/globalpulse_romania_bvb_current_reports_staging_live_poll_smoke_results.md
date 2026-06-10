# GlobalPulse Romania BVB Current Reports staging live poll smoke results

## Summary

```text
ROMANIA_BVB_CURRENT_REPORTS_SOURCE_REGISTERED
ROMANIA_BVB_CURRENT_REPORTS_STAGING_LIVE_POLL_PASS
ROMANIA_BVB_CURRENT_REPORTS_CANONICAL_ITEMS_CREATED
ROMANIA_BVB_CURRENT_REPORTS_DIGEST_TOP_N_VISIBILITY_PENDING_EXPECTED
ROMANIA_BVB_CURRENT_REPORTS_SCHEDULED_POLLING_DISABLED
```

## Scope

```text
source_key: ro_bvb_current_reports
display_name: Romania BVB Current Reports
source_type: html
parser_key: bvb_current_reports_html_v1
source URL: https://bvb.ro/FinancialInstruments/SelectedData/CurrentReports
authority: official Bucharest Stock Exchange current-report surface
mode: manual staging live poll only
scheduled polling: disabled
```

## Deployment

```text
phase0-foundation merge commit: cd6be86239fc3a9c19f5d87ad9e7b70fefd7af2d
Fly app: globalpulse-backend-staging
Fly URL: https://globalpulse-backend-staging.fly.dev/
Fly deploy: success
release_command: success
Fly image: registry.fly.io/globalpulse-backend-staging:deployment-01KR58TT91T3Z3K21B2EH53XBK
CI:
- Phase 0 validate: success
- Phase 0 report: success
- Phase 1 backend verify: success
- Phase 1 runtime smoke: success
- Phase 1 backend report: success
- Phase 1 backend diagnose: success
- Phase 1 backend trace: success
```

## Automated checks

```text
local compile: PASS
local format check: PASS
local fixture parser smoke: PASS, 2 records, first external_id=7F19B
local live parser smoke: PASS, 25 records, first external_id=7F19B
```

Note:

```text
compile emitted existing Phoenix dependency typing warnings in output but exited 0.
The first parser smoke attempt used mix run without --no-start and hit local Postgres auth; rerun with mix run --no-start passed.
```

## Staging API smoke

```text
GET /api/health
status: 200
body.status: ok
body.service: disclosure_automation
```

```text
POST /api/admin/sources/ro_bvb_current_reports/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 736173
records_seen: 25
records_inserted: 24
canonical_items: 24
metadata.fallback_to_fixture: false
```

## Digest smoke

Latest digest:

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 3
metadata.fallback_to_fixture: false
result: latest digest currently contains India 2026-05-09 items, so Romania 2026-05-08 items are not expected in latest UI yet.
```

Date-specific digest:

```text
GET /api/feed/digest/2026-05-08/breaking
status: 200
digest_date: 2026-05-08
item_count: 12
metadata.fallback_to_fixture: false
romania_count: 0
```

Reason:

```text
The BVB live poll created canonical items, but the public digest endpoint currently returns the top 12 diverse items for the date.
Existing higher-ranked/diverse 2026-05-08 items filled that top-n window, so Romania BVB public digest visibility remains pending rather than failed.
```

First live parser item:

```text
source: Romania BVB Current Reports
region: eu_central
headline: Premier Energy PLC - Convocare AGA din data de 10.06.2026
canonical_url: https://bvb.ro/FinancialInstruments/SelectedData/NewsItem/PE-Convocare-AGA-din-data-de-10-06-2026/7F19B
summary: Bucharest Stock Exchange current report | Issuer: Premier Energy PLC | Symbol: PE | ISIN: CY0200900914 | Document type: Adunarea Generala a Actionarilor
published_at: 2026-05-08T15:56:00Z
```

## Public UI status

```text
DIGEST_TOP_N_VISIBILITY_PENDING_EXPECTED
PUBLIC_LATEST_UI_VISIBILITY_PENDING_EXPECTED
```

Reason:

```text
The public Pages shell renders the latest digest date and the API's current top-n digest window.
After the BVB poll, latest digest remained 2026-05-09 with India items.
The Romania live records are dated 2026-05-08 and were created as canonical items, but they are not currently selected into the 2026-05-08 top 12 digest response.
```

## Guardrails

```text
No scheduled polling promotion.
No public poll UI.
No audit UI.
No public Source Health UI.
No backend JSON response shape change.
No frontend framework change.
No central-bank, macro, or policy source added.
No fixture fallback claimed as live success.
```
