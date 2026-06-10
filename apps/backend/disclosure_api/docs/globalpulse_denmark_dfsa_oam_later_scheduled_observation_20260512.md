# GlobalPulse Denmark DFSA OAM Later Scheduled Observation

Date: 2026-05-12 KST

This document records two later automatic Denmark DFSA OAM scheduled staging canary runs after the second follow-up observation.

This is documentation-only. It does not enable production scheduled polling, does not set any source `active=true`, does not change the Denmark canary cadence, does not expand the EU canary source list, does not change backend runtime behavior, does not change frontend runtime behavior, does not change routes or public API response shapes, and does not add public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
DENMARK_DFSA_OAM_LATER_SCHEDULED_OBSERVATION_RECORDED
DENMARK_DFSA_OAM_LATER_RUNS_SUCCESSFUL
DENMARK_DFSA_OAM_FETCH_MODE_LIVE
DENMARK_DFSA_OAM_FETCH_STATUS_200
DENMARK_DFSA_OAM_DIGEST_CONTRACT_PASS
DENMARK_DFSA_OAM_DIGEST_FALLBACK_FALSE
DENMARK_DFSA_OAM_TOP_N_VISIBILITY_PRESENT
DENMARK_DFSA_OAM_SOURCE_REMAINS_ACTIVE_FALSE
DENMARK_DFSA_OAM_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Observation Scope

```text
workflow: GlobalPulse live staging poll
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
event: schedule
head branch: main
head sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
expected Denmark DFSA OAM cron: 47 */4 * * 1-5
resolved source_key: denmark_dfsa_oam_staging_canary
run mode: denmark_dfsa_oam_canary
edition: breaking
backend URL: https://globalpulse-backend-staging.fly.dev
```

Earlier Denmark DFSA OAM scheduled staging evidence is recorded in:

```text
globalpulse_denmark_dfsa_oam_second_followup_scheduled_observation_20260512.md
```

This refresh records two later scheduled canary runs. It is still not a production-promotion approval.

## Additional Successful Denmark Runs

| Run id | Created at UTC | Artifact id | Artifact digest | fetch.mode | fetch.status_code | records_seen | records_inserted | digest_date | digest item_count | digest fallback | Denmark top-N items |
| --- | --- | --- | --- | --- | ---: | ---: | ---: | --- | ---: | --- | ---: |
| 25720174153 | 2026-05-12T07:31:07Z | 6938210592 | sha256:e7ddcc5fb5a7c75ed856c86aeb413c8d2ed65b1b3ffaf1699b8f1c1970ffc5c6 | live | 200 | 25 | 25 | 2026-05-12 | 12 | false | 1 |
| 25730389870 | 2026-05-12T11:04:53Z | 6942439114 | sha256:e6647caff7457acbf197ab8b85a54c30172ea5d3fcf9088af8126f40d9e5aa17 | live | 200 | 25 | 25 | 2026-05-12 | 12 | false | 1 |

Interpretation:

```text
both additional Denmark DFSA OAM scheduled runs completed successfully
both poll artifacts resolved source_key=dk_dfsa_oam_company_announcements
both runs fetched the Denmark DFSA OAM API live endpoint
both runs returned fetch.status_code=200
both runs stayed within the 25-item cap
both digest artifacts preserved metadata.fallback_to_fixture=false
both top-N digest windows included one Denmark DFSA OAM row
```

## Digest Review

Run `25720174153` digest source mix:

```text
india_nse_announcements: 2
dk_dfsa_oam_company_announcements: 1
ch_six_ser_official_notices: 1
eu_belgium_fsma_stori: 1
eu_euronext_company_press_releases: 2
pt_cmvm_portal_info_privi: 1
eu_spain_cnmv_other_relevant_information: 1
hkex_latest_listed_company_information: 2
uk_fca_nsm_regulated_information: 1
```

Run `25730389870` digest source mix:

```text
india_nse_announcements: 3
ch_six_ser_official_notices: 2
dk_dfsa_oam_company_announcements: 1
hkex_latest_listed_company_information: 1
eu_spain_cnmv_other_relevant_information: 1
uk_fca_nsm_regulated_information: 1
eu_euronext_company_press_releases: 1
eu_belgium_fsma_stori: 1
eu_france_info_financiere_oam: 1
```

Interpretation:

```text
both digest artifacts were live-backed with metadata.fallback_to_fixture=false
both top-N windows included Denmark DFSA OAM without dominating the digest
both top-N windows preserved regional/source diversity
```

## Latest Canonical Windows

Run `25720174153` observed this leading canonical item sample:

```text
breaking-2026-05-12-dfsa-oam-300008818
breaking-2026-05-12-dfsa-oam-300008816
breaking-2026-05-12-dfsa-oam-300008815
breaking-2026-05-12-dfsa-oam-300008814
breaking-2026-05-12-dfsa-oam-300008812
```

Run `25730389870` observed a later leading canonical item sample:

```text
breaking-2026-05-12-dfsa-oam-300008838
breaking-2026-05-12-dfsa-oam-300008823
breaking-2026-05-12-dfsa-oam-300008820
breaking-2026-05-12-dfsa-oam-300008819
breaking-2026-05-12-dfsa-oam-300008818
```

This confirms repeated scheduled fetches can observe a moving bounded Denmark DFSA OAM page-1 window without changing the public digest response shape.

## Source State Follow-up

An informational source-health read after run `25730389870` returned:

```text
GET /api/admin/source-health/dk_dfsa_oam_company_announcements
http_status: 200
source_key: dk_dfsa_oam_company_announcements
active: false
candidate_status: manual_staging_only
source_type: api
parser_key: dfsa_oam_company_announcements_json_v1
base_url: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/search
health_status: unknown
last_success_at: 2026-05-12T11:06:11.346053Z
last_seen_published_at: 2026-05-12T11:15:30.000000Z
last_error: null
last_failure_at: null
```

Interpretation:

```text
the source remains inactive and manual-staging-only
the latest source-health timestamp matches the inspected scheduled Denmark poll window
health_status remains informational and should be tracked, but it does not change the scheduled-run pass evidence
```

## Observation Window Status

Current Denmark DFSA OAM observation progress:

```text
later successful scheduled runs inspected here: 2
fixture fallback count in inspected runs: 0
unresolved parser/runtime failures in inspected runs: 0
top-N Denmark visibility in inspected later runs: present
source active flag: false
production scheduled polling: not enabled
promotion decision: not approved
```

This means Denmark DFSA OAM has continued successful scheduled evidence, but it is still not approved for production scheduled polling.

## Guardrails Preserved

```text
production scheduled Denmark polling: not enabled
source active flags: unchanged
candidate_status values: unchanged
Denmark staging-only canary cadence: unchanged
EU canary source list: unchanged
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
1. Continue Denmark DFSA OAM scheduled staging observation across additional time windows.
2. Keep Denmark source active=false and production scheduled polling disabled.
3. Keep Denmark as its own staging-only canary unless a dedicated PR changes that policy.
4. Continue EU canary, India NSE, HKEX, public web smoke, and source-health observation windows in parallel.
```
