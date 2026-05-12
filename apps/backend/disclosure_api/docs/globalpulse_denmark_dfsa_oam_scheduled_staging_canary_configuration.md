# GlobalPulse Denmark DFSA OAM Scheduled Staging Canary Configuration

Date: 2026-05-11 KST

## Conclusion

```text
DENMARK_DFSA_OAM_SCHEDULED_STAGING_CANARY_CONFIGURED_ON_PHASE0
DENMARK_DFSA_OAM_SEPARATE_STAGING_CRON_CONFIGURED
DENMARK_DFSA_OAM_MANUAL_CANARY_DISPATCH_BASELINE_PASS
DENMARK_DFSA_OAM_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
DENMARK_DFSA_OAM_SOURCE_REMAINS_ACTIVE_FALSE
DENMARK_DFSA_OAM_DEFAULT_BRANCH_ACTIVATION_REQUIRED
```

## Scope

This document records the phase0 workflow configuration for the Denmark DFSA OAM staging-only scheduled canary.

The configuration is staging-only. It does not enable production scheduled polling, does not set the source active, does not change registry/parser/backend response shape, and does not add frontend UI, poll UI, audit UI, or public Source Health UI.

Changed workflow:

```text
.github/workflows/globalpulse-live-staging-poll.yml
```

## Baseline

```text
source_key: dk_dfsa_oam_company_announcements
manual alias: denmark_dfsa_oam_staging_canary
run_mode: denmark_dfsa_oam_canary
source status: active=false
candidate_status: manual_staging_only
page: 1
pageSize: 25
fixture fallback: disabled
details/document fetch: disabled
ShortSelling category: excluded
Shareholder category: excluded
```

Evidence gates already recorded:

```text
candidate notes: globalpulse_denmark_dfsa_oam_company_announcements_candidate_notes.md
first page-1 smoke: globalpulse_denmark_dfsa_oam_company_announcements_staging_live_poll_smoke_results.md
cadence/rate/pagination design: globalpulse_denmark_dfsa_oam_cadence_rate_pagination_design.md
second page-1 smoke: globalpulse_denmark_dfsa_oam_repeated_page1_staging_smoke_results.md
decision gate: globalpulse_denmark_dfsa_oam_staging_canary_decision.md
manual canary path: PR #494
manual canary smoke: globalpulse_denmark_dfsa_oam_manual_canary_dispatch_smoke_results.md
```

Manual canary dispatch baseline:

```text
workflow run: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25646128342
run_mode: denmark_dfsa_oam_canary
health status: 200
poll status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 7141
records_seen: 25
records_inserted: 25
digest status: 200
metadata.fallback_to_fixture: false
post-run source health: healthy
source active: false
```

## Workflow Configuration

Existing schedules remain:

```text
SEC cron: 7 * * * *
India NSE cron: 37 */2 * * 1-5
first EU canary cron: 17 */4 * * 1-5
```

New Denmark staging canary schedule:

```text
Denmark DFSA OAM cron: 47 */4 * * 1-5
resolved source: denmark_dfsa_oam_staging_canary
resolved run_mode: denmark_dfsa_oam_canary
resolved source list: dk_dfsa_oam_company_announcements
edition: breaking
backend: https://globalpulse-backend-staging.fly.dev
scope: staging workflow only
production polling: not enabled
```

Why minute 47:

```text
keeps Denmark separate from SEC minute 7
keeps Denmark separate from the first EU canary minute 17
keeps Denmark separate from India NSE minute 37
avoids silently adding a high-volume OAM source to the existing EU canary minute
```

## Validation Contract

The scheduled Denmark canary reuses the same poll validation contract as the manual canary:

```text
GET /api/health returns 2xx
POST /api/admin/sources/dk_dfsa_oam_company_announcements/poll?use_live_fetch=true&edition=breaking returns 2xx
poll.fetch.mode == live
poll.fetch.status_code == 200
poll.fetch.fixture_fallback is not true
poll.records_seen <= 25
poll.records_inserted <= poll.records_seen
poll.canonical_items count <= poll.records_seen
poll.raw_documents count <= poll.records_seen
GET /api/feed/digest/latest?edition=breaking returns 2xx
digest.metadata.fallback_to_fixture == false
```

Expected healthy no-new-data behavior:

```text
records_seen: 25
records_inserted: may be 0..25
canonical identity: dfsa-oam:{id}
latest digest top-N Denmark visibility: may remain pending when newer sources dominate
```

## Default Branch Activation

GitHub scheduled workflows execute from the repository default branch. This phase0 configuration does not complete scheduled activation by itself if the default branch remains `main`.

Required activation path:

```text
1. Merge this configuration to phase0-foundation.
2. Confirm CI passes.
3. Apply the workflow-only Denmark cron change to the repository default branch.
4. Wait for the first matching cron or manually dispatch the Denmark alias from the default branch.
5. Record the first scheduled Denmark canary observation in a docs-only PR.
```

## Guardrails

```text
production scheduled polling not enabled
source remains active=false
candidate_status remains manual_staging_only
page remains 1
pageSize remains 25
category allowlist unchanged
ShortSelling excluded
Shareholder excluded
details/document fetch disabled
backend digest JSON response shape unchanged
frontend UI unchanged
public poll UI not added
audit UI not added
public Source Health UI not added
fixture fallback cannot be claimed as live
Ireland remains blocked until Dublin-only machine-readable filtering is proven
```

## Next Result To Record

After the default-branch activation PR lands and the first Denmark scheduled canary run completes, record:

```text
workflow run URL
event: schedule
cron expression
artifact name and id
health status
poll status
fetch.mode
fetch.status_code
fetch.bytes
records_seen
records_inserted
canonical_items count
raw_documents count
source health before/after
latest digest status
latest digest fallback_to_fixture
latest digest Denmark top-N visibility note
rollback action if validation fails
```
