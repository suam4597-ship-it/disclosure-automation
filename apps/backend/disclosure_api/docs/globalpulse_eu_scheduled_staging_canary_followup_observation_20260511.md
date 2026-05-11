# GlobalPulse EU Scheduled Staging Canary Follow-up Observation

Date: 2026-05-12 KST

This document records a follow-up automatic EU scheduled staging canary run observed while waiting for the HKEX scheduled staging window.

This is documentation-only. It does not enable production scheduled polling, does not set any source `active=true`, does not expand the canary source list, does not change backend runtime behavior, does not change frontend runtime behavior, does not change routes or public API response shapes, and does not add public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
EU_CANARY_FOLLOWUP_AUTOMATED_CRON_OBSERVED
EU_CANARY_FOLLOWUP_AUTOMATED_CRON_RUN_SUCCESS
EU_CANARY_ALL_EIGHT_SOURCE_POLL_STEPS_PASS
EU_CANARY_DIGEST_CONTRACT_PASS
EU_CANARY_ARTIFACT_METADATA_RECORDED
EU_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Workflow Run

```text
workflow: GlobalPulse live staging poll
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
event: schedule
run URL: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25680178601
run id: 25680178601
head sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
status: completed
conclusion: success
created_at: 2026-05-11T15:35:46Z
```

## Schedule Resolution

```text
SCHEDULE_EXPR: 17 */4 * * 1-5
SOURCE_KEY: eu_scheduled_staging_canary
RUN_MODE: eu_canary
edition: breaking
backend URL: https://globalpulse-backend-staging.fly.dev
```

This is not the pending HKEX run. HKEX still requires a separate scheduled run with:

```text
SCHEDULE_EXPR: 22 */2 * * 1-5
SOURCE_KEY: hkex_latest_listed_company_information
RUN_MODE: single_source
```

## Artifact

```text
artifact name: globalpulse-live-staging-poll-25680178601
artifact id: 6922798237
artifact size: 11405 bytes
expired: false
created_at: 2026-05-11T15:36:20Z
expires_at: 2026-08-09T15:35:46Z
archive_download_url: https://api.github.com/repos/suam4597-ship-it/disclosure-automation/actions/artifacts/6922798237/zip
```

## Source Poll Review

The scheduled canary loop ran the bounded first-canary source list. All eight sources passed the live poll contract:

| Source | fetch.mode | fetch.status_code | records_seen | records_inserted | canonical_items |
| --- | --- | --- | ---: | ---: | ---: |
| eu_france_info_financiere_oam | live | 200 | 25 | 25 | 25 |
| eu_spain_cnmv_inside_information | live | 200 | 1 | 1 | 1 |
| eu_spain_cnmv_other_relevant_information | live | 200 | 25 | 25 | 25 |
| eu_belgium_fsma_stori | live | 200 | 25 | 25 | 25 |
| uk_fca_nsm_regulated_information | live | 200 | 25 | 25 | 25 |
| ch_six_ser_official_notices | live | 200 | 25 | 25 | 25 |
| eu_euronext_company_press_releases | live | 200 | 6 | 6 | 6 |
| pt_cmvm_portal_info_privi | live | 200 | 3 | 3 | 3 |

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
digest_date: 2026-05-11
edition: breaking
item_count: 12
metadata.fallback_to_fixture: false
digest contract: pass
```

Observed digest source mix:

```text
india_nse_announcements
ch_six_ser_official_notices
eu_euronext_company_press_releases
uk_fca_nsm_regulated_information
eu_spain_cnmv_other_relevant_information
dk_dfsa_oam_company_announcements
eu_france_info_financiere_oam
eu_belgium_fsma_stori
hkex_latest_listed_company_information
```

The digest is a global top-N latest feed, so non-EU live items in the digest are expected and do not indicate EU canary failure.

## Observation Window Status

This run adds one more successful automatic canary observation for the first EU canary set. It does not approve production polling.

The production-promotion gate remains:

```text
minimum duration: 7 calendar days
minimum successful scheduled runs per included source: 5
fixture fallback count: 0
unresolved parser/content-type failures: 0
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
HKEX first automated scheduled staging run: still pending
JP live polling: still blocked pending issue #339 source-authority decision
KR live source track: still deferred until the dedicated backend/source authority path exists
```

