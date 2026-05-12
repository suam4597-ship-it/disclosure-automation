# GlobalPulse India NSE Scheduled Observation Refresh

Date: 2026-05-12 KST

This document records two additional India NSE scheduled staging observations after the interim India NSE observation record.

This is documentation-only. It does not enable production scheduled polling, does not set any source `active=true`, does not change backend runtime behavior, does not change frontend runtime behavior, does not change routes or public API response shapes, and does not add public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
INDIA_NSE_SCHEDULED_OBSERVATION_REFRESH_RECORDED
INDIA_NSE_RECENT_SCHEDULED_RUNS_CONFIRMED_6
INDIA_NSE_FETCH_MODE_LIVE
INDIA_NSE_FETCH_STATUS_200
INDIA_NSE_DIGEST_CONTRACT_PASS
INDIA_NSE_DIGEST_FALLBACK_FALSE
INDIA_NSE_TOP_N_VISIBILITY_NOT_REQUIRED_FOR_EVERY_RUN
INDIA_NSE_LATEST_SOURCE_HEALTH_UPDATED
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

Earlier India NSE scheduled staging evidence is recorded in:

```text
globalpulse_india_nse_interim_scheduled_observation_20260512.md
```

This refresh adds two later scheduled India NSE runs. It is still not a final 7-day observation decision and does not approve production polling.

## Additional Successful India NSE Scheduled Runs

| Run id | Created at UTC | Artifact id | Artifact digest | fetch.mode | fetch.status_code | records_seen | records_inserted | digest_date | digest item_count | digest fallback | India top-N items |
| --- | --- | --- | --- | --- | ---: | ---: | ---: | --- | ---: | --- | ---: |
| 25719883720 | 2026-05-12T07:24:31Z | 6938093293 | sha256:8000ba6da399ccb57d0420825be1b90eb39402efba465ad3ce36d077cee66126 | live | 200 | 25 | 25 | 2026-05-12 | 12 | false | 0 |
| 25730184956 | 2026-05-12T11:00:31Z | 6942331331 | sha256:ee26e62aca0aa992b0ed472ee6ca5b0dee7d32ec9212111370493f9b489afb49 | live | 200 | 25 | 25 | 2026-05-12 | 12 | false | 0 |

Interpretation:

```text
both additional India NSE scheduled runs completed successfully
both poll artifacts resolved source_key=india_nse_announcements
both runs fetched the official NSE Online Announcements RSS live endpoint
both runs returned fetch.status_code=200
both runs stayed within the 25-item cap
both digest artifacts preserved metadata.fallback_to_fixture=false
```

India NSE rows were not present in the global top-N digest for these two later runs. This is not a poll failure. The public digest is a recency-ranked global feed, so other live rows can push India NSE rows out of the visible top-N window while the India NSE poll still succeeds.

## Successful Scheduled Run Count

The recent inspected India NSE scheduled staging run set is now:

```text
25694981715
25699447717
25703573653
25713273293
25719883720
25730184956
```

This brings the recent inspected India NSE observation set to:

```text
recent successful scheduled India NSE runs inspected: 6
first automated scheduled run: recorded separately
minimum duration target: 7 calendar days
```

## Latest Canonical Windows

Run `25719883720` observed this leading canonical item sample:

```text
breaking-2026-05-12-https-nsearchives-nseindia-com-corporate-excellentwires-12052026125243-outcomeofbm12052026ewpl-pdf
breaking-2026-05-12-https-nsearchives-nseindia-com-corporate-vasconeq-12052026125006-presentation-sd-pdf
breaking-2026-05-12-https-nsearchives-nseindia-com-corporate-gallantt-12052026125051-gallantt-transcript-pdf
breaking-2026-05-12-https-nsearchives-nseindia-com-corporate-gipcl7868-12052026125050-se-pbnewspaperpublication-12052026-pdf
breaking-2026-05-12-https-nsearchives-nseindia-com-corporate-mayuruniq-12052026124014-2-disclosure-after-strikesd-pdf
```

Run `25730184956` observed a later leading canonical item sample:

```text
breaking-2026-05-12-https-nsearchives-nseindia-com-corporate-voltamp-12052026162925-newspaper-saksham-niveshak-signed-pdf
breaking-2026-05-12-https-nsearchives-nseindia-com-corporate-ugarsugar-12052026162814-outome-of-bm-12052026-1-pdf
breaking-2026-05-12-https-nsearchives-nseindia-com-corporate-rssoft-12052026162907-rssoft-finresults-outcomebm-07may2026-pdf
breaking-2026-05-12-https-nsearchives-nseindia-comarfind-12052026162904-newspaper-covering-board-meeting-march-26-pdf
breaking-2026-05-12-https-nsearchives-nseindia-com-corporate-lkwalimbe-bajajauto-co-in-12052026162900-se-transcript-q4-fy26-pdf
```

This confirms repeated scheduled fetches can observe a moving bounded NSE RSS window without changing the public digest response shape.

## Source State Follow-up

An informational source-health read after run `25730184956` returned:

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
last_success_at: 2026-05-12T11:00:42.925754Z
last_seen_published_at: 2026-05-12T16:30:04.000000Z
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
recent successful scheduled runs inspected: 6
minimum duration target: 7 calendar days
fixture fallback count in inspected runs: 0
unresolved parser/runtime failures in inspected runs: 0
source active flag: false
production scheduled polling: not enabled
promotion decision: not approved
```

This means India NSE has continued successful scheduled evidence, but the 7-day staging observation window is still not complete.

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
