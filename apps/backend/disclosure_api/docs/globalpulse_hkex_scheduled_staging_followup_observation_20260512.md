# GlobalPulse HKEX Scheduled Staging Follow-up Observation

Date: 2026-05-12 KST

This document records the first follow-up observation set for the inactive HKEX Latest Listed Company Information scheduled staging workflow.

This is documentation-only. It does not change workflows, source activation, backend runtime behavior, frontend runtime behavior, routes, public API response shapes, production polling, public poll UI, audit UI, public Source Health UI, parser behavior, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or database schema.

## Conclusion

```text
HKEX_SCHEDULED_STAGING_FOLLOWUP_OBSERVED
HKEX_SCHEDULED_STAGING_SUCCESSFUL_RUNS_CONFIRMED_4
HKEX_POLL_FETCH_MODE_LIVE
HKEX_POLL_FIXTURE_FALLBACK_NOT_USED
HKEX_DIGEST_FALLBACK_FALSE
HKEX_DIGEST_TOP_N_VISIBILITY_NOT_GUARANTEED_EVERY_RUN
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

The first HKEX automated scheduled staging run is recorded separately in:

```text
globalpulse_hkex_first_automated_scheduled_run_results.md
```

This follow-up record adds the next observed scheduled HKEX runs. It is still not a production-promotion approval.

## Successful HKEX Scheduled Runs

| Run id | Created at UTC | Artifact id | Artifact digest | fetch.mode | fetch.status_code | records_seen | records_inserted | digest_date | digest item_count | digest fallback | HKEX top-N items |
| --- | --- | --- | --- | --- | ---: | ---: | ---: | --- | ---: | --- | ---: |
| 25684138207 | 2026-05-11T16:48:50Z | 6924498853 | sha256:da2757d136e94258707e66ee203a9e2e279a521d215420751296bd4ffffb639e | live | 200 | 5 | 5 | 2026-05-11 | 12 | false | 2 |
| 25694265118 | 2026-05-11T20:05:31Z | 6928674895 | sha256:d8b611aacb0b1ea9e30712003584e53732801339eb9fe83be4733024da20946b | live | 200 | 5 | 5 | 2026-05-11 | 12 | false | 0 |
| 25699065657 | 2026-05-11T21:43:00Z | 6930576266 | sha256:20d03d53fbcd7dd38858ff0a74f4acb7b904e667fbf038fe919667ddfc532e6a | live | 200 | 5 | 5 | 2026-05-12 | 9 | false | 0 |
| 25702861937 | 2026-05-11T23:13:25Z | 6932004754 | sha256:acf10d7ac93b16c450676aa10e85cfd735c041782c0ef63c3bd34f89325f2fc6 | live | 200 | 5 | 5 | 2026-05-12 | 10 | false | 0 |

Interpretation:

```text
all four observed HKEX scheduled runs completed successfully
all four poll artifacts resolved source_key=hkex_latest_listed_company_information
all four runs fetched the official HKEX homecat0_e.json live endpoint
all four runs returned fetch.status_code=200
all four runs stayed bounded at five parsed latest-submission records
all four digest artifacts preserved metadata.fallback_to_fixture=false
```

The later digest artifacts did not include HKEX in the global top-N list. This is not a poll failure. The digest is a recency-ranked global feed, so SEC, India, EU, and other live rows can push HKEX rows out of the top-N window. HKEX public visibility was already observed on the first scheduled run and manual smoke records, but visibility should continue to be monitored before any promotion.

## Latest Canonical Window

The first three scheduled HKEX runs observed the same latest-five canonical item set:

```text
breaking-2026-05-11-hkex-llci-2026051101908
breaking-2026-05-11-hkex-llci-2026051101830
breaking-2026-05-11-hkex-llci-2026051101821
breaking-2026-05-11-hkex-llci-2026051101741
breaking-2026-05-11-hkex-llci-2026051101739
```

The latest observed run advanced to a newer HKEX latest-five window:

```text
breaking-2026-05-11-hkex-llci-2026051200177
breaking-2026-05-11-hkex-llci-2026051200152
breaking-2026-05-11-hkex-llci-2026051200147
breaking-2026-05-11-hkex-llci-2026051200145
breaking-2026-05-11-hkex-llci-2026051200139
```

This confirms the scheduled workflow can observe a moving HKEX LLCI source window without fetching PDF, HTM, detail, or attachment bodies.

## Source State Follow-up

An informational source-health read after the observed runs returned:

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
last_success_at: 2026-05-11T23:13:39.851284Z
last_seen_published_at: 2026-05-11T23:06:00.000000Z
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
successful scheduled HKEX runs observed: 4
minimum target before promotion discussion: 10 successful scheduled runs
minimum duration target: 7 calendar days
fixture fallback count: 0
unresolved parser/runtime failures: 0
source active flag: false
production scheduled polling: not enabled
promotion decision: not approved
```

This means HKEX has moved from first scheduled-run proof to an active observation window, but it is still below the 7-day / 10-run promotion gate.

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
