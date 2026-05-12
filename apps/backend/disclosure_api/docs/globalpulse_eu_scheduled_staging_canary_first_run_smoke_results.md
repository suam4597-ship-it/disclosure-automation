# GlobalPulse EU Scheduled Staging Canary First Run Smoke Results

This document records the first EU staging canary workflow run using the manual-dispatch sentinel.

## Conclusion

```text
EU_CANARY_WORKFLOW_DISPATCH_PASS
EU_CANARY_HEALTH_PASS
EU_CANARY_ALL_SOURCE_POLLS_PASS
EU_CANARY_DIGEST_PASS
EU_CANARY_ARTIFACTS_RECORDED
EU_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Workflow Run

```text
workflow: GlobalPulse live staging poll
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
event: workflow_dispatch
run URL: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25606512644
run id: 25606512644
job id: 75169255515
head branch: main
head sha: 2ff6e437b934ebc6c17934785473009e13a142d2
status: completed
conclusion: success
created_at: 2026-05-09T16:52:53Z
updated_at: 2026-05-09T16:53:27Z
```

Dispatch inputs:

```text
backend_url: https://globalpulse-backend-staging.fly.dev
source_key: eu_scheduled_staging_canary
edition: breaking
```

Resolved workflow target:

```text
SOURCE_KEY: eu_scheduled_staging_canary
RUN_MODE: eu_canary
EU_CANARY_SOURCES: eu_france_info_financiere_oam, eu_spain_cnmv_inside_information, eu_spain_cnmv_other_relevant_information, eu_belgium_fsma_stori, uk_fca_nsm_regulated_information, ch_six_ser_official_notices, eu_euronext_company_press_releases, pt_cmvm_portal_info_privi
```

## Artifact

```text
artifact name: globalpulse-live-staging-poll-25606512644
artifact id: 6897155471
artifact digest: sha256:ff17a0886801f424e2565ab137b372dc7afb0f05642f9914901a339f461f4b19
artifact size: 8721 bytes
artifact URL: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25606512644/artifacts/6897155471
uploaded files: health.json, digest-eu-canary.json, and one poll-<source_key>.json file for each of the eight first-canary sources
```

## Health

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/health
status: 200
response:
  status: ok
  service: disclosure_automation
  phase: phase1
  repo: up
```

## Source Poll Results

```text
eu_france_info_financiere_oam: poll status=202, fetch.mode=live, fetch.status_code=200, records_seen=25, records_inserted=25, canonical_items=25, raw_documents=25
eu_spain_cnmv_inside_information: poll status=202, fetch.mode=live, fetch.status_code=200, records_seen=0, records_inserted=0, canonical_items=0, raw_documents=0
eu_spain_cnmv_other_relevant_information: poll status=202, fetch.mode=live, fetch.status_code=200, records_seen=6, records_inserted=6, canonical_items=6, raw_documents=6
eu_belgium_fsma_stori: poll status=202, fetch.mode=live, fetch.status_code=200, records_seen=25, records_inserted=25, canonical_items=25, raw_documents=25
uk_fca_nsm_regulated_information: poll status=202, fetch.mode=live, fetch.status_code=200, records_seen=25, records_inserted=25, canonical_items=25, raw_documents=25
ch_six_ser_official_notices: poll status=202, fetch.mode=live, fetch.status_code=200, records_seen=9, records_inserted=9, canonical_items=9, raw_documents=9
eu_euronext_company_press_releases: poll status=202, fetch.mode=live, fetch.status_code=200, records_seen=8, records_inserted=8, canonical_items=8, raw_documents=8
pt_cmvm_portal_info_privi: poll status=202, fetch.mode=live, fetch.status_code=200, records_seen=3, records_inserted=3, canonical_items=3, raw_documents=3
```

Interpretation:

```text
All eight first-canary sources passed the workflow poll contract.
No source exceeded the 25-item canary cap.
Spain CNMV inside-information returned an empty live feed, which is accepted as a live 200 empty-feed pass.
No rollback action was required.
```

## Digest Checks

Latest digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 12
fallback_to_fixture: false
observed source distribution: ch_six_ser_official_notices=9, india_nse_announcements=3
```

Date-specific digest sampling:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-08/breaking
status: 200
item_count: 12
fallback_to_fixture: false
observed source distribution: eu_belgium_fsma_stori=1, eu_euronext_company_press_releases=1, eu_italy_emarket_storage_regulated_communications=1, eu_nasdaq_nordic_company_news=1, gr_athex_issuer_announcements=1, hu_bse_issuers_news=1, india_nse_announcements=4, no_oslo_bors_newsweb_main_market=1, uk_fca_nsm_regulated_information=1

request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-07/breaking
status: 200
item_count: 12
fallback_to_fixture: false
observed source distribution: eu_france_info_financiere_oam=4, eu_luxembourg_luxse_oam=3, eu_spain_cnmv_inside_information=2, lt_oam_regulated_information=1, si_oam_regulated_information=1, sk_ceri_regulated_information=1
```

Interpretation:

```text
The workflow digest contract passed.
Latest digest visibility is dominated by Switzerland SIX and India NSE because the current latest digest date is 2026-05-09.
Date-specific sampling confirms additional EU source visibility for 2026-05-08 and 2026-05-07.
Some first-canary sources are still not guaranteed to appear in the public top-N digest after every run because existing higher-ranked/diverse items can fill the window; this is a digest-window observation, not a live-fetch failure.
```

## Guardrails Preserved

```text
production scheduled EU polling: not enabled
source active flags: unchanged
candidate_status: unchanged
Germany Company Register scheduled polling: not enabled
Prague/PSE scheduled polling: not enabled
public digest JSON response shape change: none
frontend shell change: none
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
JP live polling: still blocked pending issue #339 source-authority decision
```

## Next Step

```text
Wait for the next automatic EU cron run from main, then record the first automated scheduled canary smoke.
After at least 7 calendar days and at least 5 successful scheduled runs per included source, record the EU canary observation summary.
Do not approve production scheduled EU polling from this first workflow_dispatch smoke.
```
