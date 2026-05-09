# GlobalPulse EU Scheduled Staging Canary Configuration Results

This document records the phase0 workflow configuration for the first EU scheduled staging canary.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, source activation, or production scheduled polling.

## Conclusion

```text
EU_SCHEDULED_STAGING_CANARY_WORKFLOW_CONFIGURED_ON_PHASE0
EU_FIRST_CANARY_SOURCE_LIST_CONFIGURED
EU_MANUAL_PREFLIGHT_CANARY_POLL_PASS
EU_DEFAULT_BRANCH_ACTIVATION_PASS
EU_CANARY_MANUAL_DISPATCH_PATH_RECORDED
EU_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Baseline

```text
design doc: globalpulse_eu_source_batch_promotion_design.md
runbook doc: globalpulse_eu_scheduled_staging_canary_runbook.md
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
backend URL: https://globalpulse-backend-staging.fly.dev
branch target: phase0-foundation
main activation PR: #447 Activate EU staging canary schedule on main
main activation merge commit: 09fdcb747022bf47709e913298495c595819f6fe
manual dispatch doc: globalpulse_eu_scheduled_staging_canary_manual_dispatch.md
source status: active=false
candidate status: manual_staging_only
```

## Workflow Configuration

Existing schedules remain:

```text
SEC cron: 7 * * * *
SEC resolved source_key: sec_press_releases
India NSE cron: 37 */2 * * 1-5
India NSE resolved source_key: india_nse_announcements
```

New EU staging canary schedule:

```text
EU cron: 17 */4 * * 1-5
EU run mode: eu_canary
edition: breaking
backend: https://globalpulse-backend-staging.fly.dev
scope: staging workflow only
production polling: not enabled
```

Configured first-canary source list:

```text
eu_france_info_financiere_oam
eu_spain_cnmv_inside_information
eu_spain_cnmv_other_relevant_information
eu_belgium_fsma_stori
uk_fca_nsm_regulated_information
ch_six_ser_official_notices
eu_euronext_company_press_releases
pt_cmvm_portal_info_privi
```

## Workflow Behavior

```text
workflow_dispatch source_key input still wins when provided
manual workflow_dispatch default source_key remains sec_press_releases
workflow_dispatch source_key=eu_scheduled_staging_canary runs the EU canary source list manually
SEC and India NSE scheduled routing remains intact
EU cron polls the full first-canary source list sequentially
EU cron writes one poll-<source_key>.json artifact per source
EU cron continues after an individual source failure and fails the job at the end if any source failed
latest digest is verified once after the EU canary poll set
health.json, poll*.json, and digest*.json are uploaded as smoke artifacts
```

Per-source EU canary validation:

```text
poll HTTP status is 2xx
poll.fetch.mode is live
poll.fetch.status_code is 200
poll.fetch.fixture_fallback is not true
poll.records_seen <= 25
poll.records_inserted <= poll.records_seen
poll.canonical_items count <= poll.records_seen
poll.raw_documents count <= poll.records_seen
```

Digest validation:

```text
GET /api/feed/digest/latest?edition=breaking returns 2xx
digest.metadata.fallback_to_fixture is false
```

The workflow accepts omitted `poll.fetch.fixture_fallback` as long as it is not `true`, because existing successful live poll responses for several legacy manual candidates omit that optional metadata field.

## Manual Preflight

Before enabling the scheduled workflow path, the first-canary source list was manually polled against Fly staging.

```text
request pattern: POST /api/admin/sources/<source_key>/poll?use_live_fetch=true&edition=breaking
backend: https://globalpulse-backend-staging.fly.dev
```

Observed manual preflight results:

```text
eu_france_info_financiere_oam: live 200, records_seen=25, records_inserted=25, canonical_items=25
eu_spain_cnmv_inside_information: live 200, records_seen=0, records_inserted=0, canonical_items=0
eu_spain_cnmv_other_relevant_information: live 200, records_seen=6, records_inserted=6, canonical_items=6
eu_belgium_fsma_stori: live 200, records_seen=25, records_inserted=25, canonical_items=25
uk_fca_nsm_regulated_information: live 200, records_seen=25, records_inserted=25, canonical_items=25
ch_six_ser_official_notices: live 200, records_seen=9, records_inserted=9, canonical_items=9
eu_euronext_company_press_releases: live 200, records_seen=8, records_inserted=8, canonical_items=8
pt_cmvm_portal_info_privi: live 200, records_seen=3, records_inserted=3, canonical_items=3
```

Interpretation:

```text
All first-canary sources passed live HTTP and parser/canonical preflight.
Spain CNMV inside-information currently returning zero live rows is an acceptable empty-feed live pass, not a parser failure.
No first-canary source exceeded the configured 25-item cap in the manual preflight.
```

## Default Branch Activation

GitHub scheduled workflows execute from the repository default branch. PR #447 applied the workflow-only EU canary schedule change to `main`, which is the repository default branch.

Verified default-branch workflow state:

```text
default branch: main
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
SEC cron present: 7 * * * *
India NSE cron present: 37 */2 * * 1-5
EU canary cron present: 17 */4 * * 1-5
EU canary run mode: eu_canary
default branch activation: complete
```

## Guardrails Preserved

```text
production scheduled EU polling: not enabled
source active flags: unchanged
candidate_status: unchanged
Germany Company Register scheduled polling: not enabled
Prague/PSE scheduled polling: not enabled
public digest JSON response shape change: none
frontend shell change: none
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
JP live polling: still blocked pending issue #339 source-authority decision
```

## Next Result To Record

After the first automatic EU cron completes, record:

```text
workflow run URL
artifact name and id
health.json status
per-source poll JSON status
per-source records_seen and records_inserted
per-source fetch.mode and fetch.status_code
digest JSON item_count and fallback_to_fixture
latest digest source and region distribution
date-specific digest checks for rows not visible in latest top-N
any rollback action if a source fails
```

## Current Conclusion

```text
EU_SCHEDULED_STAGING_CANARY_PHASE0_CONFIG_READY
EU_DEFAULT_BRANCH_ACTIVATION_PASS
EU_CANARY_MANUAL_DISPATCH_READY
EU_FIRST_CANARY_RUN_SMOKE_PENDING
EU_PRODUCTION_SCHEDULED_POLLING_BLOCKED
```
