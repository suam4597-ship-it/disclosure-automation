# Denmark DFSA OAM Company Announcements Staging Live Poll Smoke Results

Date: 2026-05-11 KST

## Conclusion

```text
DENMARK_DFSA_OAM_COMPANY_ANNOUNCEMENTS_STAGING_LIVE_POLL_PASS
DENMARK_DFSA_OAM_COMPANY_ANNOUNCEMENTS_SOURCE_HEALTH_PASS
DENMARK_DFSA_OAM_COMPANY_ANNOUNCEMENTS_CANONICAL_INSERT_PASS
DENMARK_DFSA_OAM_COMPANY_ANNOUNCEMENTS_DATE_SPECIFIC_PUBLIC_DIGEST_TOP_N_PENDING
DENMARK_DFSA_OAM_COMPANY_ANNOUNCEMENTS_LATEST_PUBLIC_UI_VISIBILITY_PENDING
```

## Scope

This smoke verifies the inactive/manual-staging Denmark DFSA OAM company-announcements candidate against Fly staging.

```text
source_key: dk_dfsa_oam_company_announcements
source type: api
parser: dfsa_oam_company_announcements_json_v1
backend: https://globalpulse-backend-staging.fly.dev
source status: active=false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
scheduled polling: disabled
```

## Deploy Context

```text
candidate PR: #487 Add Denmark DFSA OAM company announcements candidate
candidate merge commit: 0098adf3fb30295ccfc67c2cd6c19c2f1706ae27
Fly app: globalpulse-backend-staging
Fly deploy: success
release_command: success
```

## Smoke Commands

```text
GET /api/health
GET /api/admin/source-health/dk_dfsa_oam_company_announcements
POST /api/admin/sources/dk_dfsa_oam_company_announcements/poll?use_live_fetch=true&edition=breaking
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
source_key: dk_dfsa_oam_company_announcements
display_name: Denmark DFSA OAM Company Announcements
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
base_url: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/search
healthcheck_url: https://www.dfsa.dk/financial-themes/capital-market/company-announcements
parser_key: dfsa_oam_company_announcements_json_v1
```

Live poll:

```text
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 7141
fetch.url: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/search
records_seen: 25
records_inserted: 25
edition: breaking
```

Canonical item keys inserted:

```text
breaking-2026-05-08-dfsa-oam-300008701
breaking-2026-05-08-dfsa-oam-300008685
breaking-2026-05-08-dfsa-oam-300008678
breaking-2026-05-08-dfsa-oam-300008670
breaking-2026-05-08-dfsa-oam-300008652
breaking-2026-05-08-dfsa-oam-300008640
breaking-2026-05-08-dfsa-oam-300008641
breaking-2026-05-08-dfsa-oam-300008639
breaking-2026-05-07-dfsa-oam-300008633
breaking-2026-05-07-dfsa-oam-300008630
breaking-2026-05-07-dfsa-oam-300008625
breaking-2026-05-07-dfsa-oam-300008622
breaking-2026-05-07-dfsa-oam-300008621
breaking-2026-05-07-dfsa-oam-300008618
breaking-2026-05-07-dfsa-oam-300008609
breaking-2026-05-07-dfsa-oam-300008602
breaking-2026-05-07-dfsa-oam-300008579
breaking-2026-05-07-dfsa-oam-300008575
breaking-2026-05-07-dfsa-oam-300008563
breaking-2026-05-07-dfsa-oam-300008562
breaking-2026-05-07-dfsa-oam-300008561
breaking-2026-05-07-dfsa-oam-300008560
breaking-2026-05-06-dfsa-oam-300008550
breaking-2026-05-06-dfsa-oam-300008549
breaking-2026-05-06-dfsa-oam-300008548
```

Post-poll source health:

```text
health_status: healthy
last_error: null
last_failure_at: null
last_seen_published_at: 2026-05-08T14:13:40.000000Z
last_success_at: 2026-05-10T16:00:46.901927Z
```

Date-specific digest:

```text
GET /api/feed/digest/2026-05-08/breaking
status: 200
metadata.fallback_to_fixture: false
top_n: 12
Denmark DFSA OAM item visibility: pending
reason: date-specific digest top-N already contains higher-ranked/newer 2026-05-08 live items from India, UK, Belgium, Nasdaq Nordic, Greece, Euronext, Norway, Hungary, and Italy.
```

Latest digest/public UI:

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
latest digest date: 2026-05-09
Denmark DFSA OAM latest visibility: pending
reason: Denmark DFSA OAM latest rows are 2026-05-08 while current public latest digest is 2026-05-09.
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
details/document fetch remains out of scope
ShortSelling category remains excluded from the bounded live request
```

## Follow-Up

Before any scheduled promotion, record repeated staging smoke and a cadence/rate/pagination design for the DFSA OAM API. The current manual staging source uses a bounded page-1 search window, pageSize 25, and issuer/company announcement category allowlist only.
