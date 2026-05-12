# GlobalPulse India NSE Interim Scheduled Observation

Date: 2026-05-12 KST

This document records interim India NSE scheduled staging observations while the 7-day observation window is still in progress.

This is documentation-only. It does not enable production scheduled polling, does not set any source `active=true`, does not change backend runtime behavior, does not change frontend runtime behavior, does not change routes or public API response shapes, and does not add public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
INDIA_NSE_INTERIM_SCHEDULED_OBSERVATION_RECORDED
INDIA_NSE_RECENT_SCHEDULED_RUNS_SUCCESSFUL
INDIA_NSE_FETCH_MODE_LIVE
INDIA_NSE_DIGEST_CONTRACT_PASS
INDIA_NSE_TOP_N_DIGEST_VISIBILITY_PRESENT
INDIA_NSE_SOURCE_REMAINS_STAGING_ONLY
INDIA_NSE_7_DAY_OBSERVATION_WINDOW_STILL_IN_PROGRESS
PRODUCTION_INDIA_NSE_POLLING_NOT_ENABLED
```

## Observation Scope

```text
workflow: GlobalPulse live staging poll
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
event: schedule
head branch: main
head sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
expected India NSE cron: 37 */2 * * 1-5
resolved source_key: india_nse_announcements
run mode: single_source
edition: breaking
backend URL: https://globalpulse-backend-staging.fly.dev
```

The first India NSE automated scheduled run is already recorded separately. This document is an interim observation summary, not the final 7-day observation decision.

## Recent Successful India NSE Scheduled Runs

| Run id | Created at UTC | Artifact id | Artifact digest | fetch.mode | fetch.status_code | records_seen | records_inserted | digest_date | digest item_count | digest fallback | India top-N items |
| --- | --- | --- | --- | --- | ---: | ---: | ---: | --- | ---: | --- | ---: |
| 25694981715 | 2026-05-11T20:20:01Z | 6928969989 | sha256:27c68c6b0e4b26abb5b53b6ba876cd8c2665558c1e819cae4382d02b2f8fada7 | live | 200 | 9 | 9 | 2026-05-12 | 9 | false | 9 |
| 25699447717 | 2026-05-11T21:51:22Z | 6930725464 | sha256:91c59c750c5f1fedc7d1ea6cc55cfad5fb356595359511c1243206366d8fd6c7 | live | 200 | 10 | 10 | 2026-05-12 | 10 | false | 10 |
| 25703573653 | 2026-05-11T23:32:16Z | 6932270847 | sha256:aace5fc845aa88abe3f6bd1ef7a5a9cabe759b82d9d888947f91021e8f592939 | live | 200 | 10 | 10 | 2026-05-12 | 10 | false | 10 |

Interpretation:

```text
all three inspected recent India NSE scheduled runs completed successfully
all three poll artifacts resolved source_key=india_nse_announcements
all three runs fetched the official NSE Online Announcements RSS live endpoint
all three runs returned fetch.status_code=200
all three runs stayed below the 25-item cap
all three digest artifacts preserved metadata.fallback_to_fixture=false
all three digest artifacts included India NSE rows in the global top-N digest
```

## Latest Canonical Window

The latest two inspected runs observed the same current NSE RSS canonical window:

```text
breaking-2026-05-12-https-nsearchives-nseindia-com-corporate-archean-12052026025037-large-corporate-disclosure-revised-pdf
breaking-2026-05-12-https-nsearchives-nseindia-com-corporate-xbrl-bm-543657-125202613258-outcome-webxmlfile-20260512-013300286-xml
breaking-2026-05-12-https-nsearchives-nseindia-com-corporate-xbrl-divdend-xml-outcome-webxmlfile-20260512-013251887-xml
```

This confirms repeated scheduled fetches can observe bounded live NSE rows without changing the public digest response shape.

## Source State Follow-up

An informational source-health read after the observed runs returned:

```text
GET /api/admin/source-health/india_nse_announcements
http_status: 200
source_key: india_nse_announcements
active: false
candidate_status: manual_staging_only
source_type: rss
parser_key: rss_v1
base_url: https://nsearchives.nseindia.com/content/RSS/Online_announcements.xml
health_status: unknown
last_success_at: 2026-05-11T23:32:24.620542Z
last_seen_published_at: 2026-05-12T02:51:05.000000Z
last_error: null
last_failure_at: null
```

Interpretation:

```text
the source remains inactive and manual-staging-only
the latest source-health timestamp matches the inspected scheduled India poll window
health_status remains informational and should be tracked, but it does not change the scheduled-run pass evidence
```

## Observation Window Status

Current India NSE observation progress:

```text
first automated scheduled run: recorded separately
recent successful scheduled runs inspected here: 3
minimum duration target: 7 calendar days
fixture fallback count in inspected runs: 0
unresolved parser/runtime failures in inspected runs: 0
source active flag: false
production scheduled polling: not enabled
promotion decision: not approved
```

This means India NSE has good early scheduled evidence, but the 7-day staging observation window is still not complete.

## Guardrails Preserved

```text
production scheduled India NSE polling: not enabled
source active flags: unchanged
candidate_status values: unchanged
backend digest JSON response shape change: none
frontend shell change: none
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
fixture fallback claimed as live success: no
JP live polling: still blocked pending issue #339 source-authority decision
KR live source track: still deferred until the dedicated backend/source authority path exists
```

## Next Allowed Steps

```text
1. Continue India NSE scheduled staging observation until the 7-day window is mature.
2. Record the final 7-day India NSE observation summary only after enough scheduled runs accumulate.
3. Keep India NSE active=false and production scheduled polling disabled.
4. Continue EU canary, Denmark DFSA OAM, HKEX, public web smoke, and source-health observation windows in parallel.
```
