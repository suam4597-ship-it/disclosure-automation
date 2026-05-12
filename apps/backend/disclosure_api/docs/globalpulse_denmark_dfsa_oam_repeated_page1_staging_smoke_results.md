# Denmark DFSA OAM Repeated Page-1 Staging Smoke Results

Date: 2026-05-11 KST

## Conclusion

```text
DENMARK_DFSA_OAM_REPEATED_PAGE_ONE_STAGING_SMOKE_PASS
DENMARK_DFSA_OAM_COMPANY_ANNOUNCEMENTS_SECOND_LIVE_POLL_PASS
DENMARK_DFSA_OAM_COMPANY_ANNOUNCEMENTS_SOURCE_HEALTH_HEALTHY
DENMARK_DFSA_OAM_COMPANY_ANNOUNCEMENTS_REPEATED_CANONICAL_INSERT_PASS
DENMARK_DFSA_OAM_REMAINS_MANUAL_STAGING_ONLY
DENMARK_DFSA_OAM_SCHEDULED_POLLING_STILL_BLOCKED
```

## Scope

This document records a second manual Fly staging live-poll smoke for the Denmark DFSA OAM company-announcements candidate in a later observation window.

It does not enable scheduled polling, does not set the source active, does not change backend digest JSON shape, does not add frontend UI, and does not add public poll UI, audit UI, or public Source Health UI.

```text
source_key: dk_dfsa_oam_company_announcements
display_name: Denmark DFSA OAM Company Announcements
source type: api
parser: dfsa_oam_company_announcements_json_v1
backend: https://globalpulse-backend-staging.fly.dev
source status: active=false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
scheduled polling: disabled
```

## Related Evidence

```text
candidate notes: globalpulse_denmark_dfsa_oam_company_announcements_candidate_notes.md
first staging smoke: globalpulse_denmark_dfsa_oam_company_announcements_staging_live_poll_smoke_results.md
cadence/rate/pagination design: globalpulse_denmark_dfsa_oam_cadence_rate_pagination_design.md
```

The cadence design requires repeated page-1 staging evidence before any staging canary discussion. This smoke provides the next observation window.

## Workflow Run

```text
workflow: GlobalPulse live staging poll
run: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25644574112
run_number: 51
run branch: main
run sha: 2ff6e437b934ebc6c17934785473009e13a142d2
artifact: globalpulse-live-staging-poll-25644574112
artifact id: 6908422977
artifact digest: sha256:a89cb3bd5614ec257e9a1741a3360b283249dae0765e9b20e508f92b9ef7eb75
```

Workflow inputs:

```text
backend_url: https://globalpulse-backend-staging.fly.dev
source_key: dk_dfsa_oam_company_announcements
edition: breaking
run_mode: single_source
```

## Results

Health check:

```text
GET /api/health
status: 200
response: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

Live poll:

```text
POST /api/admin/sources/dk_dfsa_oam_company_announcements/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.loaded: true
fetch.status_code: 200
fetch.bytes: 7141
fetch.url: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/search
records_seen: 25
records_inserted: 25
edition: breaking
```

The repeated smoke stayed within the bounded page-1 canary cap:

```text
page: 1
pageSize: 25
records_seen: 25
canonical_items count: 25
raw_documents count: 25
```

Canonical item keys observed:

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
source_key: dk_dfsa_oam_company_announcements
active: false
candidate_status: manual_staging_only
health_status: healthy
last_error: null
last_failure_at: null
last_seen_published_at: 2026-05-08T14:13:40.000000Z
last_success_at: 2026-05-11T00:49:19.436310Z
```

Latest digest contract:

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 12
metadata.fallback_to_fixture: false
Denmark latest digest top-N visibility: pending
```

Denmark latest top-N visibility remains pending because the current latest digest date is 2026-05-09 and Denmark DFSA OAM page-1 rows remain dated 2026-05-08 or earlier.

## Repeated Evidence Comparison

```text
first smoke last_success_at: 2026-05-10T16:00:46.901927Z
second smoke last_success_at: 2026-05-11T00:49:19.436310Z
first smoke records_seen: 25
second smoke records_seen: 25
first smoke records_inserted: 25
second smoke records_inserted: 25
first smoke fetch.bytes: 7141
second smoke fetch.bytes: 7141
first smoke latest published_at: 2026-05-08T14:13:40.000000Z
second smoke latest published_at: 2026-05-08T14:13:40.000000Z
```

This confirms the ordered JSON request body, category allowlist, page-1 window, and parser remained stable across two observation windows.

## Guardrails Confirmed

```text
source remains active=false
scheduled polling not enabled
production scheduled polling not enabled
fixture fallback not used for live claim
backend digest JSON response shape unchanged
frontend UI unchanged
public poll UI not added
public Source Health UI not added
audit UI not added
details/document fetch remains out of scope
ShortSelling category remains excluded
Shareholder category remains excluded
page remains 1
pageSize remains 25
```

## Next Step

Denmark DFSA OAM now has repeated page-1 manual staging evidence. Do not promote it to production scheduled polling.

Before any staging canary inclusion, record a separate decision PR that names:

```text
source list
cadence
rollback path
request budget
expected duplicate behavior
latest digest/top-N impact
pause triggers
```

Any page-2 or broader category exploration must remain a separate manual-staging smoke track.
