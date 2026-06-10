# GlobalPulse EU Scheduled Staging Canary Later-run Observation

Date: 2026-05-12 KST

This document records two later automatic EU scheduled staging canary runs after the second follow-up observation.

This is documentation-only. It does not enable production scheduled polling, does not set any source `active=true`, does not expand the canary source list, does not change backend runtime behavior, does not change frontend runtime behavior, does not change routes or public API response shapes, and does not add public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
EU_CANARY_LATER_RUN_OBSERVATION_RECORDED
EU_CANARY_LATER_RUNS_SUCCESSFUL
EU_CANARY_ALL_EIGHT_SOURCE_POLL_STEPS_PASS
EU_CANARY_FETCH_MODE_LIVE
EU_CANARY_FETCH_STATUS_200
EU_CANARY_DIGEST_CONTRACT_PASS
EU_CANARY_DIGEST_FALLBACK_FALSE
EU_CANARY_TOP_N_DIGEST_DIVERSITY_PRESENT
EU_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Observation Scope

```text
workflow: GlobalPulse live staging poll
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
event: schedule
head branch: main
head sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
expected EU canary cron: 17 */4 * * 1-5
resolved source_key: eu_scheduled_staging_canary
run mode: eu_canary
edition: breaking
backend URL: https://globalpulse-backend-staging.fly.dev
```

Earlier EU canary scheduled staging evidence is recorded in:

```text
globalpulse_eu_scheduled_staging_canary_second_followup_observation_20260512.md
```

This refresh records two later scheduled canary runs. It is still not a production-promotion approval.

## Additional Successful EU Canary Runs

| Run id | Created at UTC | Artifact id | Artifact digest | digest_date | digest item_count | digest fallback |
| --- | --- | --- | --- | --- | ---: | --- |
| 25718344882 | 2026-05-12T06:48:26Z | 6937485282 | sha256:ef4481ff5d400d0b98f8f98e72a0c12cd9bf0a3694090741d7cef55dbf27bfa8 | 2026-05-12 | 12 | false |
| 25729286004 | 2026-05-12T10:41:28Z | 6941983662 | sha256:3f4024d570fd886c0475ac975b93a1926541aeea3e63300005917acc4e6faa5d | 2026-05-12 | 12 | false |

Interpretation:

```text
both EU canary scheduled runs completed successfully
both runs resolved source_key=eu_scheduled_staging_canary
both runs used run_mode=eu_canary
both digest artifacts preserved metadata.fallback_to_fixture=false
```

## Source Poll Review

Run `25718344882`:

| Source | fetch.mode | fetch.status_code | records_seen | records_inserted | canonical_items | raw_documents |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| ch_six_ser_official_notices | live | 200 | 25 | 25 | 25 | 25 |
| eu_belgium_fsma_stori | live | 200 | 25 | 25 | 25 | 25 |
| eu_euronext_company_press_releases | live | 200 | 7 | 7 | 7 | 7 |
| eu_france_info_financiere_oam | live | 200 | 25 | 25 | 25 | 25 |
| eu_spain_cnmv_inside_information | live | 200 | 3 | 3 | 3 | 3 |
| eu_spain_cnmv_other_relevant_information | live | 200 | 8 | 8 | 8 | 8 |
| pt_cmvm_portal_info_privi | live | 200 | 3 | 3 | 3 | 3 |
| uk_fca_nsm_regulated_information | live | 200 | 25 | 25 | 25 | 25 |

Run `25729286004`:

| Source | fetch.mode | fetch.status_code | records_seen | records_inserted | canonical_items | raw_documents |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| ch_six_ser_official_notices | live | 200 | 25 | 25 | 25 | 25 |
| eu_belgium_fsma_stori | live | 200 | 25 | 25 | 25 | 25 |
| eu_euronext_company_press_releases | live | 200 | 8 | 8 | 8 | 8 |
| eu_france_info_financiere_oam | live | 200 | 25 | 25 | 25 | 25 |
| eu_spain_cnmv_inside_information | live | 200 | 3 | 3 | 3 | 3 |
| eu_spain_cnmv_other_relevant_information | live | 200 | 18 | 18 | 18 | 18 |
| pt_cmvm_portal_info_privi | live | 200 | 3 | 3 | 3 | 3 |
| uk_fca_nsm_regulated_information | live | 200 | 25 | 25 | 25 | 25 |

Interpretation:

```text
all eight configured EU canary sources returned live payloads in both later runs
all fetch.status_code values were 200
all poll steps returned accepted bounded payloads
no source exceeded the 25-item canary cap
no fixture fallback was claimed as live success
```

## Digest Review

Run `25718344882` digest source mix:

```text
india_nse_announcements: 2
ch_six_ser_official_notices: 2
eu_belgium_fsma_stori: 2
eu_euronext_company_press_releases: 2
pt_cmvm_portal_info_privi: 1
eu_spain_cnmv_other_relevant_information: 1
uk_fca_nsm_regulated_information: 1
hkex_latest_listed_company_information: 1
```

Run `25729286004` digest source mix:

```text
india_nse_announcements: 2
ch_six_ser_official_notices: 2
eu_spain_cnmv_other_relevant_information: 1
uk_fca_nsm_regulated_information: 1
eu_euronext_company_press_releases: 2
dk_dfsa_oam_company_announcements: 1
eu_belgium_fsma_stori: 1
eu_france_info_financiere_oam: 1
pt_cmvm_portal_info_privi: 1
```

Interpretation:

```text
both digest artifacts were live-backed with metadata.fallback_to_fixture=false
both top-N windows included a mix of EU canary rows and non-EU rows
run 25729286004 also included a Denmark DFSA OAM row in the global top-N digest
```

## Observation Window Status

These runs add two more successful automatic canary observations for the first EU canary set. They do not approve production polling.

The production-promotion gate remains:

```text
minimum duration: 7 calendar days
minimum successful scheduled runs per included source: 5
fixture fallback count: 0
unresolved parser/content-type failures: 0
public digest visibility: continue observing across source-specific windows
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
2. Keep the first EU canary source list unchanged unless a dedicated canary-expansion PR states otherwise.
3. Keep production scheduled polling disabled until source-specific approvals exist.
4. Continue Denmark DFSA OAM, India NSE, HKEX, public web smoke, and source-health observation windows in parallel.
```
