# GlobalPulse SEC Hourly Scheduled Run After Liveness Gap

Date: 2026-05-12 KST

This document records the first observed `GlobalPulse live staging poll` scheduled run after the earlier scheduled staging poll no-new-run gap observation.

This is documentation-only. It does not change workflow schedules, source activation, backend runtime behavior, frontend runtime behavior, routes, public API response shapes, production polling, public poll UI, audit UI, public Source Health UI, dashboards, alerts, secrets, or hosting configuration.

## Conclusion

```text
GLOBALPULSE_SEC_HOURLY_SCHEDULED_RUN_AFTER_GAP_OBSERVED
GLOBALPULSE_LIVE_STAGING_POLL_LIVENESS_RESUMED
SEC_HOURLY_SCHEDULE_RUN_25712461043_PASS
SEC_FETCH_MODE_LIVE
SEC_FETCH_STATUS_200
SEC_POLL_STATUS_202
SEC_RECORDS_SEEN_25
SEC_RECORDS_INSERTED_25
DIGEST_FALLBACK_FALSE
NO_NEW_HKEX_EU_DENMARK_INDIA_MATCHING_RUN_CLAIMED
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Run Evidence

```text
workflow: GlobalPulse live staging poll
run id: 25712461043
event: schedule
status: completed
conclusion: success
created_at: 2026-05-12T03:59:01Z
head_sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
job: poll
job id: 75495393066
```

The workflow resolved to the SEC hourly route:

```text
SCHEDULE_EXPR: 7 * * * *
SOURCE_KEY: sec_press_releases
RUN_MODE: single_source
backend_url: https://globalpulse-backend-staging.fly.dev
edition: breaking
```

## Health And Poll Evidence

Health check:

```text
GET /api/health
status: 200
payload.status: ok
payload.service: disclosure_automation
payload.phase: phase1
payload.repo: up
```

Poll:

```text
POST /api/admin/sources/sec_press_releases/poll?use_live_fetch=true&edition=breaking
poll status: 202
fetch.mode: live
fetch.status_code: 200
fetch.url: https://www.sec.gov/news/pressreleases.rss
records_seen: 25
records_inserted: 25
canonical_items: 25
raw_documents: 25
```

## Digest Evidence

Workflow digest verification:

```text
GET /api/feed/digest/latest?edition=breaking
digest status: 200
digest.generated_at: 2026-05-12T03:59:10Z
digest.item_count: 10
digest.metadata.fallback_to_fixture: false
digest contract: pass
```

Local retry after the run:

```text
digest.generated_at: 2026-05-12T04:01:22Z
digest.item_count: 10
digest.metadata.fallback_to_fixture: false
source distribution: india_nse_announcements=10
region distribution: india=10
```

The latest top-N digest remained India-only. This is not a SEC poll failure; it is a global recency-ranked digest visibility observation.

## Interpretation

This run resolves the earlier workflow-liveness no-new-run gap for `GlobalPulse live staging poll`:

```text
the workflow executed again from schedule
the workflow remained active
the SEC hourly source resolved correctly
the SEC live poll passed
the digest verification passed with fallback=false
```

This run is not new evidence for HKEX, EU canary, Denmark DFSA OAM, or India NSE scheduled observations:

```text
SCHEDULE_EXPR was 7 * * * *
SOURCE_KEY was sec_press_releases
RUN_MODE was single_source
```

Continue waiting for matching scheduled runs before writing source-specific HKEX, EU, Denmark, or India observation updates.

## Follow-up

Next safe actions:

```text
continue checking recent GlobalPulse live staging poll runs
record HKEX/EU/Denmark/India only from matching SCHEDULE_EXPR and SOURCE_KEY logs
record public web daily scheduled smoke only after event=schedule appears
continue digest diversity checks
keep production approval blockers open until operator values are provided
```

## Guardrails

```text
Do not set new sources active=true.
Do not enable production scheduled polling.
Do not change workflow schedules in this observation PR.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not claim fixture fallback as live success.
Do not count this SEC run as HKEX, EU, Denmark, or India evidence.
Do not count workflow_dispatch as a scheduled pass.
JP live polling remains blocked by issue #339.
KR remains deferred until the dedicated backend/source path exists.
```
