# GlobalPulse EU Scheduled Staging Canary Second Follow-up Observation

Date: 2026-05-12 KST

This document records a later automatic EU scheduled staging canary run after the first follow-up observation.

This is documentation-only. It does not enable production scheduled polling, does not set any source `active=true`, does not expand the canary source list, does not change backend runtime behavior, does not change frontend runtime behavior, does not change routes or public API response shapes, and does not add public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
EU_CANARY_SECOND_FOLLOWUP_AUTOMATED_CRON_OBSERVED
EU_CANARY_SECOND_FOLLOWUP_AUTOMATED_CRON_RUN_SUCCESS
EU_CANARY_ALL_EIGHT_SOURCE_POLL_STEPS_PASS
EU_CANARY_DIGEST_CONTRACT_PASS
EU_CANARY_TOP_N_DIGEST_VISIBILITY_NOT_PRESENT_IN_THIS_RUN
EU_CANARY_LATEST_FOLLOWUP_AUTOMATED_CRON_RUN_SUCCESS
EU_CANARY_LATEST_DIGEST_EURONEXT_VISIBILITY_RETURNED
EU_CANARY_ARTIFACT_METADATA_RECORDED
EU_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Workflow Run

```text
workflow: GlobalPulse live staging poll
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
event: schedule
run URL: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25698983703
run id: 25698983703
head sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
status: completed
conclusion: success
created_at: 2026-05-11T21:41:17Z
```

## Schedule Resolution

```text
SCHEDULE_EXPR: 17 */4 * * 1-5
SOURCE_KEY: eu_scheduled_staging_canary
RUN_MODE: eu_canary
edition: breaking
backend URL: https://globalpulse-backend-staging.fly.dev
```

## Artifact

```text
artifact name: globalpulse-live-staging-poll-25698983703
artifact id: 6930553140
artifact digest: sha256:dfb8a247ea7d5babac3b1bc501e744e2dbf0efafd932ef0fadf39058a6f2378a
artifact size: 9968 bytes
expired: false
created_at: 2026-05-11T21:41:55Z
expires_at: 2026-08-09T21:41:17Z
```

The artifact was downloaded and inspected locally from the GitHub Actions artifact reference.

## Later Scheduled Run Update

A later automatic EU scheduled staging canary run also completed successfully:

```text
workflow: GlobalPulse live staging poll
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
event: schedule
run URL: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25712655792
run id: 25712655792
head sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
status: completed
conclusion: success
created_at: 2026-05-12T04:05:12Z
```

Schedule resolution:

```text
SCHEDULE_EXPR: 17 */4 * * 1-5
SOURCE_KEY: eu_scheduled_staging_canary
RUN_MODE: eu_canary
edition: breaking
backend URL: https://globalpulse-backend-staging.fly.dev
```

Artifact:

```text
artifact name: globalpulse-live-staging-poll-25712655792
artifact id: 6935410004
artifact digest: sha256:5200bbf29c7ea3cccf627d89e541645fafbff2d6529f8076e1c36003a561a6ab
artifact size: 9719 bytes
expired: false
created_at: 2026-05-12T04:05:46Z
expires_at: 2026-08-10T04:05:12Z
```

Representative poll contract lines from the latest run:

| Source | poll status | fetch.mode | fetch.status_code | records_seen | records_inserted |
| --- | ---: | --- | ---: | ---: | ---: |
| eu_france_info_financiere_oam | 202 | live | 200 | 25 | 25 |
| eu_spain_cnmv_inside_information | 202 | live | 200 | 3 | 3 |
| eu_spain_cnmv_other_relevant_information | 202 | live | 200 | 7 | 7 |

The full canary loop remains bounded by the workflow's per-source contract check. The job would fail if any configured EU canary source exceeded the item cap, returned non-live fetch metadata, used fixture fallback, or returned a non-200 fetch status. The latest run completed successfully and uploaded ten artifact files, which is consistent with `health.json`, eight `poll-*.json` files, and one EU canary digest file.

Latest digest review:

```text
GET /api/feed/digest/latest?edition=breaking
digest_date: 2026-05-12
edition: breaking
generated_at: 2026-05-12T04:05:46Z
item_count: 12
metadata.fallback_to_fixture: false
digest contract: pass
```

Observed top-N digest visibility returned for EU Euronext rows:

```text
eu_euronext_company_press_releases / eu / LINK Mobility - Q1 2026 - On track to organic growth
eu_euronext_company_press_releases / eu / Atos and Backbase to accelerate secure, AI-native banking across regulated markets
eu_euronext_company_press_releases / eu / Rapid Nutrition Extends AI-Powered Agentic Platform to Consumer Ecosystem Following Investor Rollout
```

The same digest also included India NSE rows. This confirms digest diversity for this latest EU canary window without changing source activation or production schedule status.

## Source Poll Review

The scheduled canary loop ran the bounded first-canary source list. All eight sources passed the live poll contract:

| Source | fetch.mode | fetch.status_code | records_seen | records_inserted | canonical_items | raw_documents |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| ch_six_ser_official_notices | live | 200 | 25 | 25 | 25 | 25 |
| eu_belgium_fsma_stori | live | 200 | 25 | 25 | 25 | 25 |
| eu_euronext_company_press_releases | live | 200 | 6 | 6 | 6 | 6 |
| eu_france_info_financiere_oam | live | 200 | 25 | 25 | 25 | 25 |
| eu_spain_cnmv_inside_information | live | 200 | 4 | 4 | 4 | 4 |
| eu_spain_cnmv_other_relevant_information | live | 200 | 25 | 25 | 25 | 25 |
| pt_cmvm_portal_info_privi | live | 200 | 3 | 3 | 3 | 3 |
| uk_fca_nsm_regulated_information | live | 200 | 25 | 25 | 25 | 25 |

Interpretation:

```text
all eight configured EU canary sources returned live payloads
all fetch.status_code values were 200
all poll steps returned accepted bounded payloads
no source exceeded the 25-item canary cap
no fixture fallback was claimed as live success
```

## Digest Review

```text
GET /api/feed/digest/latest?edition=breaking
digest_date: 2026-05-12
edition: breaking
generated_at: 2026-05-11T21:41:54Z
item_count: 9
metadata.fallback_to_fixture: false
digest contract: pass
```

Observed digest source mix:

```text
india_nse_announcements
```

The digest contract passed because the public digest remained live-backed with `metadata.fallback_to_fixture=false`. However, this run's global top-N digest was dominated by India NSE rows and did not include EU canary rows.

Interpretation:

```text
EU canary polling passed
digest fallback remained false
this run does not provide EU public top-N visibility evidence
EU public visibility and digest diversity need continued observation in separate smoke windows
```

## Observation Window Status

This run adds another successful automatic canary observation for the first EU canary set. It does not approve production polling.

The later run `25712655792` adds one more successful automatic EU canary observation and restored EU Euronext visibility in the global top-N digest for that window. It still does not approve production polling.

The production-promotion gate remains:

```text
minimum duration: 7 calendar days
minimum successful scheduled runs per included source: 5
fixture fallback count: 0
unresolved parser/content-type failures: 0
public digest visibility: continue observing because this run's top-N digest was India-only
explicit source-by-source approval: required
```

## Guardrails Preserved

```text
production scheduled EU polling: not enabled
source active flags: unchanged
candidate_status values: unchanged
EU canary source list: unchanged
Denmark DFSA OAM canary: unchanged
Germany Company Register scheduled polling: not enabled
Prague/PSE scheduled polling: not enabled
backend digest JSON response shape change: none
frontend shell change: none
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
JP live polling: still blocked pending issue #339 source-authority decision
KR live source track: still deferred until the dedicated backend/source authority path exists
```

## Next Allowed Steps

```text
1. Continue EU scheduled staging canary observation across additional time windows.
2. Record public digest diversity separately when EU rows appear in the global top-N digest again.
3. Continue Denmark DFSA OAM, India NSE, HKEX, public web smoke, and source-health observation windows in parallel.
4. Keep production scheduled polling disabled until explicit source-by-source approval exists.
```
