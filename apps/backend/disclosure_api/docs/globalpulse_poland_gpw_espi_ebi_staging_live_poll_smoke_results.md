# GlobalPulse Poland GPW ESPI/EBI staging live poll smoke results

## Summary

```text
POLAND_GPW_ESPI_EBI_COMPANY_REPORTS_SOURCE_REGISTERED
POLAND_GPW_ESPI_EBI_COMPANY_REPORTS_STAGING_LIVE_POLL_PASS
POLAND_GPW_ESPI_EBI_COMPANY_REPORTS_DATE_SPECIFIC_DIGEST_PASS
POLAND_GPW_ESPI_EBI_COMPANY_REPORTS_PUBLIC_LATEST_UI_VISIBILITY_PENDING_EXPECTED
POLAND_GPW_ESPI_EBI_COMPANY_REPORTS_SCHEDULED_POLLING_DISABLED
```

## Scope

```text
source_key: pl_gpw_espi_ebi_reports
display_name: Poland GPW ESPI/EBI Company Reports
source_type: html
parser_key: gpw_espi_ebi_html_v1
source URL: https://www.gpw.pl/espi-ebi-reports
authority: official Warsaw Stock Exchange / GPW ESPI/EBI company-report surface
mode: manual staging live poll only
scheduled polling: disabled
```

## Deployment

```text
phase0-foundation merge commit: d5bad4242c094748e9b3ea8f82cc344ae8714fe8
Fly app: globalpulse-backend-staging
Fly URL: https://globalpulse-backend-staging.fly.dev/
Fly deploy: success
release_command: success
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
local fixture parser smoke: PASS, 2 records, first external_id=488361
local live parser smoke: PASS, 20 records, first external_id=488361
```

Note:

```text
compile emitted existing Phoenix dependency typing warnings in output but exited 0.
```

## Staging API smoke

```text
GET /api/health
status: 200
body.status: ok
body.service: disclosure_automation
```

```text
POST /api/admin/sources/pl_gpw_espi_ebi_reports/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 107916
records_seen: 20
records_inserted: 20
canonical_items: 20
metadata.fallback_to_fixture: false
```

## Digest smoke

Latest digest:

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
metadata.fallback_to_fixture: false
result: latest digest currently contains India 2026-05-09 items, so GPW 2026-05-08 items are not expected in latest UI yet.
```

Date-specific digest:

```text
GET /api/feed/digest/2026-05-08/breaking
status: 200
digest_date: 2026-05-08
item_count: 12
metadata.fallback_to_fixture: false
poland_count: 1
```

First Poland item:

```text
source: Poland GPW ESPI/EBI Company Reports
region: eu_central
headline: PROTEKTOR SPOLKA AKCYJNA / official GPW ESPI current report
canonical_url: https://www.gpw.pl/espi-ebi-report?geru_id=488361
summary: GPW ESPI/EBI company report | Status: Current | System: ESPI | Report: 37/2026
published_at: 2026-05-08T18:19:49Z
```

## Public UI status

```text
PUBLIC_LATEST_UI_VISIBILITY_PENDING_EXPECTED
```

Reason:

```text
The public Pages shell renders the latest digest date.
After the GPW poll, latest digest remained 2026-05-09 with India items.
The GPW live records are dated 2026-05-08, so they are verified through the date-specific digest endpoint rather than the public latest UI.
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
