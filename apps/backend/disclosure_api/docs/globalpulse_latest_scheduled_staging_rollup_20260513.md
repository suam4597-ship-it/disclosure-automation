# GlobalPulse Latest Scheduled Staging Rollup

Date: 2026-05-13 KST

This document records the latest observed GlobalPulse scheduled staging poll set after the HKEX, India NSE, EU canary, and Denmark DFSA OAM observation refreshes.

This is documentation-only. It does not enable production scheduled polling, does not set any candidate source `active=true`, does not change backend runtime behavior, does not change frontend runtime behavior, does not change routes or public API response shapes, and does not add public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
LATEST_SCHEDULED_STAGING_ROLLUP_RECORDED
SEC_BASELINE_SCHEDULED_RUN_PASS
EU_CANARY_LATEST_SCHEDULED_RUN_PASS
HKEX_SCHEDULED_STAGING_RUN_COUNT_ADVANCED_TO_8
INDIA_NSE_RECENT_INSPECTED_RUN_COUNT_ADVANCED_TO_7
DENMARK_DFSA_OAM_LATEST_SCHEDULED_RUN_PASS
ALL_RECORDED_DIGESTS_FALLBACK_FALSE
PUBLIC_DIGEST_SOURCE_DIVERSITY_PRESENT
CANDIDATE_SOURCES_REMAIN_ACTIVE_FALSE
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Observation Scope

```text
workflow: GlobalPulse live staging poll
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
event: schedule
head branch: main
head sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
backend URL: https://globalpulse-backend-staging.fly.dev
edition: breaking
```

## Latest Scheduled Runs

| Run id | Created at UTC | Resolved source | Run mode | Schedule | Artifact id | Artifact digest | Poll summary | Digest fallback |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 25741580440 | 2026-05-12T14:37:27Z | sec_press_releases | single_source | 7 * * * * | 6947103641 | sha256:758707863b6c3df892c7d045a2d4a4a05ef87d7736076cb8bbd6e8f9321a169b | live/200/25 seen/25 inserted | false |
| 25742257297 | 2026-05-12T14:48:59Z | eu_scheduled_staging_canary | eu_canary | 17 */4 * * 1-5 | 6947415137 | sha256:7e077932e66c770558f8723b5e7e4a1fb5f638ea09c756aa32b3b7315a71c669 | eight EU canary poll steps live/200 | false |
| 25743490299 | 2026-05-12T15:10:11Z | hkex_latest_listed_company_information | single_source | 22 */2 * * 1-5 | 6947958168 | sha256:8e06f9306f928b5767ba929c36d58e1c7ec2699090c9f1ae02420516d096498c | live/200/5 seen/5 inserted | false |
| 25744353562 | 2026-05-12T15:24:59Z | india_nse_announcements | single_source | 37 */2 * * 1-5 | 6948340957 | sha256:2c53df27052d3340ef2e910bf2677248a97206f5a5c88de4da9e69ea9f9a2524 | live/200/25 seen/25 inserted | false |
| 25744795173 | 2026-05-12T15:32:40Z | denmark_dfsa_oam_staging_canary | denmark_dfsa_oam_canary | 47 */4 * * 1-5 | 6948536792 | sha256:d2ccbf3e53190e9f112d30f3780d8d8bdc0ede1917b4177526f0a5020708b916 | live/200/25 seen/25 inserted | false |

Interpretation:

```text
all five latest scheduled runs completed successfully
all inspected poll artifacts used live fetch mode
all inspected fetch.status_code values were 200
all inspected digest artifacts preserved metadata.fallback_to_fixture=false
```

## EU Canary Source Review

Run `25742257297` executed the unchanged eight-source EU canary list:

| Source | fetch.mode | fetch.status_code | records_seen | records_inserted |
| --- | --- | ---: | ---: | ---: |
| ch_six_ser_official_notices | live | 200 | 25 | 25 |
| eu_belgium_fsma_stori | live | 200 | 25 | 25 |
| eu_euronext_company_press_releases | live | 200 | 6 | 6 |
| eu_france_info_financiere_oam | live | 200 | 25 | 25 |
| eu_spain_cnmv_inside_information | live | 200 | 5 | 5 |
| eu_spain_cnmv_other_relevant_information | live | 200 | 22 | 22 |
| pt_cmvm_portal_info_privi | live | 200 | 3 | 3 |
| uk_fca_nsm_regulated_information | live | 200 | 25 | 25 |

The EU canary source list was not expanded by this observation.

## Digest Diversity

The latest Denmark scheduled run `25744795173` produced a live-backed digest with this source mix:

```text
india_nse_announcements: 3
dk_dfsa_oam_company_announcements: 1
ch_six_ser_official_notices: 2
eu_belgium_fsma_stori: 1
hkex_latest_listed_company_information: 1
eu_euronext_company_press_releases: 1
uk_fca_nsm_regulated_information: 1
eu_spain_cnmv_other_relevant_information: 1
pt_cmvm_portal_info_privi: 1
```

This confirms that the latest inspected top-N digest remained live-backed, regionally diverse, and not dominated by any single staging candidate.

## Source-health Snapshot

An informational source-health read after the latest scheduled runs returned:

| Source | active | candidate_status | last_success_at | last_seen_published_at | last_error |
| --- | --- | --- | --- | --- | --- |
| sec_press_releases | true | n/a | 2026-05-12T14:37:40.592118Z | 2026-05-06T19:24:19.000000Z | null |
| hkex_latest_listed_company_information | false | manual_staging_only | 2026-05-12T15:10:22.297493Z | 2026-05-12T14:50:00.000000Z | null |
| india_nse_announcements | false | manual_staging_only | 2026-05-12T15:25:11.458775Z | 2026-05-12T20:52:17.000000Z | null |
| dk_dfsa_oam_company_announcements | false | manual_staging_only | 2026-05-12T15:32:56.900712Z | 2026-05-12T16:48:59.000000Z | null |

Interpretation:

```text
SEC remains the active baseline source
HKEX, India NSE, and Denmark DFSA OAM remain inactive/manual-staging-only candidates
no candidate source was promoted by these observations
```

## Candidate Progress Update

```text
HKEX successful scheduled staging runs observed: 8
HKEX minimum target before promotion discussion: 10 successful scheduled runs and 7 calendar days
India NSE recent inspected successful scheduled runs: 7
India NSE minimum duration target: 7 calendar days
Denmark DFSA OAM latest observed scheduled run: 25744795173
EU canary latest observed scheduled run: 25742257297
```

None of these progress markers approves production scheduled polling.

## Guardrails Preserved

```text
production scheduled polling: not enabled
candidate source active flags: unchanged
candidate_status values: unchanged
EU canary source list: unchanged
Denmark canary cadence: unchanged
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
1. Continue HKEX scheduled staging observation toward the 7-day / 10 successful run gate.
2. Continue India NSE scheduled staging observation until the 7-day window is mature.
3. Continue EU canary and Denmark DFSA OAM scheduled observation summaries as later windows accumulate.
4. Keep production scheduled polling disabled unless issue #561 and issue #565 receive explicit approvals.
```
