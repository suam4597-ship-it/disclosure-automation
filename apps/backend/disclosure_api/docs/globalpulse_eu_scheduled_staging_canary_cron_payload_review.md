# GlobalPulse EU Scheduled Staging Canary Cron Payload Review

This document records a subsequent automatic EU scheduled staging canary run where the job logs and artifact metadata were available through the GitHub connector.

This is documentation-only. It does not enable production scheduled polling, does not set any source `active=true`, does not expand the canary source list, does not change backend response shape, and does not add frontend UI, poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
EU_CANARY_AUTOMATED_CRON_PAYLOAD_REVIEW_RECORDED
EU_CANARY_AUTOMATED_CRON_RUN_SUCCESS
EU_CANARY_ALL_SOURCE_POLL_STEPS_PASS
EU_CANARY_DIGEST_CONTRACT_PASS
EU_CANARY_ARTIFACT_METADATA_RECORDED
EU_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Workflow Run

```text
workflow: GlobalPulse live staging poll
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
event: schedule
run URL: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25650523685
run id: 25650523685
job id: 75287758519
head branch: main
head sha: 8445ae20f87432f58602482dcea772e994702a6c
status: completed
conclusion: success
created_at: 2026-05-11T04:36:05Z
updated_at: 2026-05-11T04:36:39Z
```

## Schedule Resolution

```text
SCHEDULE_EXPR: 17 */4 * * 1-5
SOURCE_KEY: eu_scheduled_staging_canary
RUN_MODE: eu_canary
edition: breaking
backend URL: https://globalpulse-backend-staging.fly.dev
```

The resolved source list remained the bounded first-canary list:

```text
eu_france_info_financiere_oam
eu_spain_cnmv_inside_information
eu_spain_cnmv_other_relevant_information
eu_belgium_fsma_stori
uk_fca_nsm_regulated_information
ch_six_ser_official_notices
eu_euronext_company_press_releases
pt_cmvm_portal_info_privi
```

## Artifact

```text
artifact name: globalpulse-live-staging-poll-25650523685
artifact id: 6910429929
artifact digest: sha256:849db8ce90b688f1b95cfb93b0da89d8d1d66601d53106fa5331bae9492871d5
artifact size: 8684 bytes
artifact URL: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25650523685/artifacts/6910429929
uploaded files: 10
```

## Health

```text
GET /api/health
status: 200
response.status: ok
response.service: disclosure_automation
response.phase: phase1
response.repo: up
```

## Source Poll Review

The job log showed the canary loop running against all eight configured sources, and the `Poll live source` step completed successfully.

The visible log payloads confirmed:

```text
eu_france_info_financiere_oam: poll status=202, fetch.mode=live, fetch.status_code=200, records_seen=25, records_inserted=25
eu_spain_cnmv_inside_information: poll status=202, fetch.mode=live, fetch.status_code=200, records_seen=0, records_inserted=0
eu_spain_cnmv_other_relevant_information: poll status=202, fetch.mode=live, fetch.status_code=200, records_seen=6, records_inserted=6
eu_belgium_fsma_stori: poll status=202, fetch.mode=live, fetch.status_code=200, records_seen=25, records_inserted=25
pt_cmvm_portal_info_privi: poll status=202, fetch.mode=live, fetch.status_code=200, records_seen=3, records_inserted=3
```

The job-level step result confirms the remaining configured sources also satisfied the workflow contract in this run:

```text
uk_fca_nsm_regulated_information: poll contract pass
ch_six_ser_official_notices: poll contract pass
eu_euronext_company_press_releases: poll contract pass
```

Interpretation:

```text
all eight first-canary sources passed the workflow poll contract
all accepted poll responses were live fetches
no source exceeded the 25-item canary cap
Spain CNMV inside-information again returned an accepted empty live feed
no fixture fallback was claimed as live success
```

## Digest Review

```text
GET /api/feed/digest/latest?edition=breaking
digest status: 200
digest_date: 2026-05-11
edition: breaking
generated_at: 2026-05-11T04:36:36Z
item_count: 12
metadata.fallback_to_fixture: false
digest contract: pass
```

Representative EU visibility in the latest digest:

```text
source_key: eu_euronext_company_press_releases
display_name: Euronext Company Press Releases
headline: Biomethane Station Data April 2026
metadata.fetch_mode: live
regions: eu
```

The latest digest window also contained APAC/ASEAN live items. That is expected for the global latest top-N digest and does not indicate EU source poll failure.

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

## Next Gate

Continue the EU scheduled staging observation window until at least:

```text
minimum duration: 7 calendar days
minimum successful scheduled runs per included source: 5
fixture fallback count: 0
unresolved parser/content-type failures: 0
```

This payload review does not approve production scheduled EU polling.
