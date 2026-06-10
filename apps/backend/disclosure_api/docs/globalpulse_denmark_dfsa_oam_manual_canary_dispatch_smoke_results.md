# GlobalPulse Denmark DFSA OAM Manual Canary Dispatch Smoke Results

Date: 2026-05-11 KST

## Conclusion

```text
DENMARK_DFSA_OAM_MANUAL_CANARY_DISPATCH_PASS
DENMARK_DFSA_OAM_CANARY_ALIAS_RESOLVED
DENMARK_DFSA_OAM_CANARY_POLL_CONTRACT_PASS
DENMARK_DFSA_OAM_DIGEST_CONTRACT_PASS
DENMARK_DFSA_OAM_SOURCE_HEALTH_HEALTHY
DENMARK_DFSA_OAM_REMAINS_ACTIVE_FALSE
DENMARK_DFSA_OAM_PRODUCTION_SCHEDULED_POLLING_STILL_BLOCKED
```

## Scope

This document records the first manual dispatch of the Denmark DFSA OAM staging-only canary workflow path.

It does not enable a schedule cron, does not enable production scheduled polling, does not set the source active, does not change backend response shape, and does not add frontend UI, poll UI, audit UI, or public Source Health UI.

```text
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
manual alias: denmark_dfsa_oam_staging_canary
resolved run_mode: denmark_dfsa_oam_canary
resolved source list: dk_dfsa_oam_company_announcements
backend: https://globalpulse-backend-staging.fly.dev
edition: breaking
```

## Workflow Run

```text
workflow: GlobalPulse live staging poll
event: workflow_dispatch
run: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25646128342
run_id: 25646128342
run_number: 52
job_id: 75275276585
head_branch: phase0-foundation
head_sha: f9b6e7b87c99b9d5e8f4849c06779203e73d8cfe
job conclusion: success
```

Workflow inputs:

```text
backend_url: https://globalpulse-backend-staging.fly.dev
source_key: denmark_dfsa_oam_staging_canary
edition: breaking
```

Artifact:

```text
artifact name: globalpulse-live-staging-poll-25646128342
artifact id: 6908982666
artifact digest: sha256:2124878cbbfafbf539a53eca066c1321d48ae44bf129324cee8ca75333c3063f
artifact size: 3306 bytes
```

## Resolution Check

The workflow resolved the manual alias correctly:

```text
source: denmark_dfsa_oam_staging_canary
run_mode: denmark_dfsa_oam_canary
denmark_dfsa_oam_canary_sources: dk_dfsa_oam_company_announcements
schedule: empty
```

This confirms the manual dispatch path is separate from:

```text
SEC single-source schedule
India NSE staging schedule
existing first EU staging canary schedule
```

## Health Check

```text
GET /api/health
status: 200
response: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

## Poll Result

```text
POST /api/admin/sources/dk_dfsa_oam_company_announcements/poll?use_live_fetch=true&edition=breaking
poll status: 202
source_key: dk_dfsa_oam_company_announcements
edition: breaking
fetch.mode: live
fetch.loaded: true
fetch.status_code: 200
fetch.bytes: 7141
fetch.url: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/search
records_seen: 25
records_inserted: 25
canonical_items count: 25
raw_documents count: 25
poll contract: pass
```

Canonical item keys:

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

## Digest Result

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 12
metadata.fallback_to_fixture: false
digest contract: pass
Denmark latest digest top-N visibility: pending
```

The latest digest is still newer than the Denmark page-1 rows. Absence from latest top-N is not a failure for this smoke because the source-health and poll artifacts prove live ingestion.

## Post-Run Source Health

```text
source_key: dk_dfsa_oam_company_announcements
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
health_status: healthy
last_error: null
last_failure_at: null
last_seen_published_at: 2026-05-08T14:13:40.000000Z
last_success_at: 2026-05-11T01:49:46.719987Z
page: 1
pageSize: 25
ShortSelling category: excluded
Shareholder category: excluded
```

## Guardrails Confirmed

```text
manual dispatch path only
no Denmark schedule cron enabled by this smoke
production scheduled polling not enabled
source remains active=false
candidate_status remains manual_staging_only
fixture fallback not used for live claim
page remains 1
pageSize remains 25
category allowlist unchanged
details/document fetch not enabled
backend digest JSON response shape unchanged
frontend UI unchanged
public poll UI not added
audit UI not added
public Source Health UI not added
```

## Next Step

The Denmark manual canary dispatch path passed. A separate workflow/config PR may now activate a staging-only scheduled Denmark canary if it preserves the decision gate:

```text
staging only
no production scheduled polling
source active=false
page=1
pageSize=25
current category allowlist
separate cron minute from existing EU/India paths where practical
per-run artifact upload
same poll/digest contract checks
```
