# GlobalPulse HKEX Scheduled Staging Seven-run Observation

Date: 2026-05-12 KST

This document records the next HKEX Latest Listed Company Information scheduled staging observation set after the five-run follow-up record.

This is documentation-only. It does not change workflows, source activation, backend runtime behavior, frontend runtime behavior, routes, public API response shapes, production polling, public poll UI, audit UI, public Source Health UI, parser behavior, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or database schema.

## Conclusion

```text
HKEX_SCHEDULED_STAGING_SEVEN_RUN_OBSERVED
HKEX_SCHEDULED_STAGING_SUCCESSFUL_RUNS_CONFIRMED_7
HKEX_POLL_FETCH_MODE_LIVE
HKEX_POLL_FETCH_STATUS_200
HKEX_POLL_FIXTURE_FALLBACK_NOT_USED
HKEX_DIGEST_FALLBACK_FALSE
HKEX_DIGEST_TOP_N_VISIBILITY_NOT_REQUIRED_FOR_EVERY_RUN
HKEX_SOURCE_REMAINS_ACTIVE_FALSE
HKEX_CANDIDATE_STATUS_REMAINS_MANUAL_STAGING_ONLY
HKEX_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
HKEX_OBSERVATION_WINDOW_STILL_IN_PROGRESS
```

## Observation Scope

```text
workflow: GlobalPulse live staging poll
workflow file: .github/workflows/globalpulse-live-staging-poll.yml
workflow id: 272984043
event: schedule
head branch: main
head sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
expected HKEX cron: 22 */2 * * 1-5
resolved source_key: hkex_latest_listed_company_information
run mode: single_source
edition: breaking
backend URL: https://globalpulse-backend-staging.fly.dev
```

Earlier HKEX scheduled staging evidence is recorded in:

```text
globalpulse_hkex_first_automated_scheduled_run_results.md
globalpulse_hkex_scheduled_staging_followup_observation_20260512.md
```

This record adds two later scheduled HKEX runs and moves the observed scheduled-run count from five to seven. It is still not a production-promotion approval.

## Additional Successful HKEX Scheduled Runs

| Run id | Created at UTC | Artifact id | Artifact digest | fetch.mode | fetch.status_code | records_seen | records_inserted | digest_date | digest item_count | digest fallback | HKEX top-N items |
| --- | --- | --- | --- | --- | ---: | ---: | ---: | --- | ---: | --- | ---: |
| 25719626744 | 2026-05-12T07:18:36Z | 6937994537 | sha256:46c2e64f486818c61d7e5dbabe509da82b8aaa46fbec682591c9657f59251781 | live | 200 | 5 | 5 | 2026-05-12 | 12 | false | 0 |
| 25729361512 | 2026-05-12T10:43:04Z | 6941990312 | sha256:5266c6bd1d2cd9895377239e2e26825dca0c19e749c3fa26cbe3e7a9b2e2ed7f | live | 200 | 5 | 5 | 2026-05-12 | 12 | false | 0 |

Interpretation:

```text
both additional HKEX scheduled runs completed successfully
both runs resolved source_key=hkex_latest_listed_company_information
both runs fetched the official HKEX homecat0_e.json live endpoint
both runs returned fetch.status_code=200
both runs stayed bounded at five parsed latest-submission records
both digest artifacts preserved metadata.fallback_to_fixture=false
```

HKEX rows were not in the global top-N digest for these two later runs. This is not a poll failure. The public digest is a recency-ranked global feed, so India, EU, SEC, and other live rows can push HKEX rows out of the visible top-N window while the HKEX poll still succeeds.

## Successful Scheduled Run Count

The observed successful HKEX scheduled staging run set is now:

```text
25684138207
25694265118
25699065657
25702861937
25712752961
25719626744
25729361512
```

This brings HKEX to:

```text
successful scheduled HKEX runs observed: 7
minimum target before promotion discussion: 10 successful scheduled runs
minimum duration target: 7 calendar days
```

## Latest Canonical Windows

Run `25719626744` observed this HKEX latest-five canonical item set:

```text
breaking-2026-05-12-hkex-llci-2026051200403
breaking-2026-05-12-hkex-llci-2026051200350
breaking-2026-05-12-hkex-llci-2026051200335
breaking-2026-05-12-hkex-llci-2026051200329
breaking-2026-05-12-hkex-llci-2026051200325
```

Run `25729361512` observed a later HKEX latest-five canonical item set:

```text
breaking-2026-05-12-hkex-llci-2026051201035
breaking-2026-05-12-hkex-llci-2026051201029
breaking-2026-05-12-hkex-llci-2026051201027
breaking-2026-05-12-hkex-llci-2026051201025
breaking-2026-05-12-hkex-llci-2026051201023
```

This confirms the scheduled workflow continues to observe a moving HKEX LLCI source window without fetching PDF, HTM, detail, or attachment bodies.

## Source State Follow-up

An informational source-health read after run `25729361512` returned:

```text
GET /api/admin/source-health/hkex_latest_listed_company_information
http_status: 200
source_key: hkex_latest_listed_company_information
active: false
candidate_status: manual_staging_only
source_type: api
parser_key: hkex_latest_listed_company_info_json_v1
base_url: https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
health_status: unknown
last_success_at: 2026-05-12T10:43:11.137535Z
last_seen_published_at: 2026-05-12T10:41:00.000000Z
last_error: null
last_failure_at: null
```

Interpretation:

```text
HKEX remains inactive and manual-staging-only
the latest source-health timestamps match the latest inspected scheduled HKEX poll window
health_status remains informational and should be tracked, but it does not change the scheduled-run pass evidence
```

## Observation Window Status

Current HKEX observation progress:

```text
successful scheduled HKEX runs observed: 7
minimum target before promotion discussion: 10 successful scheduled runs
minimum duration target: 7 calendar days
fixture fallback count: 0
unresolved parser/runtime failures: 0
source active flag: false
production scheduled polling: not enabled
promotion decision: not approved
```

HKEX has moved further through the staging observation window, but it remains below the 7-day / 10-run promotion gate.

## Guardrails Preserved

```text
production scheduled HKEX polling: not enabled
source active flags: unchanged
candidate_status values: unchanged
backend digest JSON response shape change: none
frontend shell change: none
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
HKEX PDF/HTM/detail/attachment body fetch: still out of scope
fixture fallback claimed as live success: no
JP live polling: still blocked pending issue #339 source-authority decision
KR live source track: still deferred until the dedicated backend/source authority path exists
```

## Next Allowed Steps

```text
1. Continue HKEX scheduled staging observation toward the 7-day / 10 successful run gate.
2. Record another HKEX observation summary after additional successful scheduled runs accumulate.
3. Keep HKEX active=false and production scheduled polling disabled.
4. Continue India NSE, EU canary, Denmark DFSA OAM, public web smoke, and source-health observation windows in parallel.
```
