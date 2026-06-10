# Moldova MSI Regulated Information Staging Live Poll Smoke Results

Date: 2026-05-11 KST

## Conclusion

```text
MOLDOVA_MSI_REGULATED_INFORMATION_STAGING_LIVE_POLL_PASS
MOLDOVA_MSI_REGULATED_INFORMATION_SOURCE_HEALTH_PASS
MOLDOVA_MSI_REGULATED_INFORMATION_CANONICAL_INSERT_PASS
MOLDOVA_MSI_REGULATED_INFORMATION_DATE_SPECIFIC_PUBLIC_DIGEST_TOP_N_PENDING
MOLDOVA_MSI_REGULATED_INFORMATION_LATEST_PUBLIC_UI_VISIBILITY_PENDING
```

## Scope

This smoke verifies the inactive/manual-staging Moldova MSI regulated information candidate against Fly staging.

```text
source_key: md_msi_regulated_information
source type: html
parser: md_msi_regulated_information_html_v1
backend: https://globalpulse-backend-staging.fly.dev
source status: active=false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
scheduled polling: disabled
```

## Deploy Context

```text
candidate PR: #485 Add Moldova MSI regulated information candidate
candidate merge commit: f29027e39840d874ac4074abb6d0ec312e02810e
Fly app: globalpulse-backend-staging
Fly deploy: success
release_command: success
```

## Smoke Commands

```text
GET /api/health
GET /api/admin/source-health/md_msi_regulated_information
POST /api/admin/sources/md_msi_regulated_information/poll?use_live_fetch=true&edition=breaking
GET /api/feed/digest/2026-05-08/breaking
GET /api/feed/digest/latest?edition=breaking
```

## Results

Health check:

```text
status: 200
service: disclosure_automation
phase: phase1
repo: up
```

Pre-poll source registration:

```text
source_key: md_msi_regulated_information
display_name: Moldova MSI Regulated Information
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
base_url: https://emitent-msi.market.md/includes/parts/pubdocs-list.php
healthcheck_url: https://emitent-msi.market.md/en/
parser_key: md_msi_regulated_information_html_v1
```

Live poll:

```text
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 2848
fetch.url: https://emitent-msi.market.md/includes/parts/pubdocs-list.php
records_seen: 10
records_inserted: 10
edition: breaking
```

Canonical item keys inserted:

```text
breaking-2026-05-08-en-displayfile-4933
breaking-2026-05-08-en-displayfile-4932
breaking-2026-05-08-en-displayfile-4931
breaking-2026-05-07-en-displayfile-4929
breaking-2026-05-06-en-displayfile-4928
breaking-2026-05-06-en-displayfile-4927
breaking-2026-05-06-en-displayfile-4926
breaking-2026-05-06-en-displayfile-4925
breaking-2026-05-05-en-displayfile-4924
breaking-2026-05-05-en-displayfile-4923
```

Post-poll source health:

```text
health_status: healthy
last_error: null
last_failure_at: null
last_seen_published_at: 2026-05-08T00:00:00.000000Z
last_success_at: 2026-05-10T15:39:24.758978Z
```

Date-specific digest:

```text
GET /api/feed/digest/2026-05-08/breaking
status: 200
metadata.fallback_to_fixture: false
top_n: 12
Moldova MSI item visibility: pending
reason: date-specific digest top-N already contains higher-ranked/newer 2026-05-08 live items from India, UK, Belgium, Nordic, Greece, Euronext, Norway, Hungary, and Italy.
```

Latest digest/public UI:

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
latest digest date: 2026-05-09
Moldova MSI latest visibility: pending
reason: Moldova MSI latest rows are 2026-05-08 while current public latest digest is 2026-05-09.
```

## Guardrails Confirmed

```text
source remains inactive
scheduled polling not enabled
fixture fallback disabled for live smoke
backend digest JSON response shape unchanged
frontend UI unchanged
public poll UI not added
public Source Health UI not added
document download/detail fetch remains out of scope
```

## Follow-Up

Before any scheduled promotion, record a cadence/date-window design for MSI. The current manual staging source uses a bounded static search window and page 1 only.
