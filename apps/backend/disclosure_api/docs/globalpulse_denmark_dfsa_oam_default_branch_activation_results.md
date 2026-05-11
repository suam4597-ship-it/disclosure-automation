# GlobalPulse Denmark DFSA OAM Default-Branch Activation Results

Date: 2026-05-11 KST

## Conclusion

```text
DENMARK_DFSA_OAM_DEFAULT_BRANCH_WORKFLOW_ACTIVATION_PASS
DENMARK_DFSA_OAM_MAIN_MANUAL_DISPATCH_PASS
DENMARK_DFSA_OAM_SCHEDULE_CRON_PRESENT_ON_MAIN
DENMARK_DFSA_OAM_FIRST_AUTOMATED_SCHEDULED_RUN_PENDING
DENMARK_DFSA_OAM_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
DENMARK_DFSA_OAM_SOURCE_REMAINS_ACTIVE_FALSE
```

## Scope

This document records default-branch activation for the Denmark DFSA OAM staging-only canary workflow path.

It does not enable production scheduled polling, does not set the source active, does not change backend response shape, and does not add frontend UI, poll UI, audit UI, or public Source Health UI.

## Default Branch Activation

The repository default branch is `main`. GitHub scheduled workflows execute from the default branch, so the phase0 schedule configuration required a workflow-only activation PR on `main`.

```text
phase0 config PR: #496 Configure Denmark DFSA OAM scheduled staging canary
main activation PR: #497 Activate Denmark DFSA OAM staging schedule on main
main activation merge commit: 8445ae20f87432f58602482dcea772e994702a6c
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
```

The default-branch workflow now contains:

```text
SEC cron: 7 * * * *
India NSE cron: 37 */2 * * 1-5
first EU canary cron: 17 */4 * * 1-5
Denmark DFSA OAM cron: 47 */4 * * 1-5
```

## Main Manual Dispatch Verification

After #497 merged, the Denmark alias was manually dispatched from `main`.

```text
workflow: GlobalPulse live staging poll
event: workflow_dispatch
run: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25646296370
run_id: 25646296370
run_number: 53
job_id: 75275743268
head_branch: main
head_sha: 8445ae20f87432f58602482dcea772e994702a6c
job conclusion: success
```

Inputs:

```text
backend_url: https://globalpulse-backend-staging.fly.dev
source_key: denmark_dfsa_oam_staging_canary
edition: breaking
```

Resolution:

```text
source: denmark_dfsa_oam_staging_canary
run_mode: denmark_dfsa_oam_canary
denmark_dfsa_oam_canary_sources: dk_dfsa_oam_company_announcements
schedule: empty
```

## Verification Results

Health:

```text
GET /api/health
status: 200
response: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

Poll:

```text
source: dk_dfsa_oam_company_announcements
poll status: 202
fetch.mode: live
fetch.loaded: true
fetch.status_code: 200
fetch.bytes: 7141
records_seen: 25
records_inserted: 25
canonical_items count: 25
raw_documents count: 25
poll contract: pass
```

Digest:

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 12
metadata.fallback_to_fixture: false
digest contract: pass
```

Artifact:

```text
artifact name: globalpulse-live-staging-poll-25646296370
artifact id: 6909040737
artifact digest: sha256:6111a5c36f4f12267b8888965d05eaf595ce495b6d8426fbbb117b7c8778961c
artifact size: 3305 bytes
```

## Guardrails Confirmed

```text
default branch activation is workflow-only
scope remains staging-only
production scheduled polling not enabled
source active flag not changed
registry not changed
parser not changed
page remains 1
pageSize remains 25
category allowlist unchanged
details/document fetch disabled
backend digest JSON response shape unchanged
frontend UI unchanged
public poll UI not added
audit UI not added
public Source Health UI not added
```

## Pending Observation

The first automated scheduled Denmark run is pending the next matching default-branch cron slot:

```text
cron: 47 */4 * * 1-5
event expected: schedule
expected run_mode: denmark_dfsa_oam_canary
expected source list: dk_dfsa_oam_company_announcements
```

After that run completes, record a separate docs-only first scheduled observation with workflow URL, artifact metadata, health, poll, digest, source-health, and any rollback action if validation fails.
