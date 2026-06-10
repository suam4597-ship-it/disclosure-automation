# GlobalPulse Latvia CSRI Staging Live Poll Smoke Results

This document records the staging live-poll smoke for the Latvia CSRI / ORICGS regulated-information candidate.

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
LATVIA_CSRI_SOURCE_HEALTH_PASS
LATVIA_CSRI_STAGING_LIVE_POLL_PASS
LATVIA_CSRI_CANONICAL_INSERT_PASS
LATVIA_CSRI_DIGEST_TOP_N_VISIBILITY_PENDING
LATVIA_CSRI_MANUAL_ONLY_READY
```

## Candidate

```text
source_key: lv_csri_regulated_information
display_name: Latvia CSRI Regulated Information
parser_key: lv_csri_regulated_information_html_v1
source URL: https://csri.investinfo.lv/en/?view=csridocuments
authority: official Latvia central storage of regulated information, reached from ORICGS / csri.investinfo.lv
region: eu_north
active: false
candidate_status: manual_staging_only
```

## Validation Context

```text
candidate PR: #425 Add Latvia CSRI regulated information candidate
candidate merge commit: 99c0223b4b5e7e6a919f1724bc9a80911a2b9a39
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
Fly app: globalpulse-backend-staging
Fly deploy image: registry.fly.io/globalpulse-backend-staging:deployment-01KR5E0X6C4982CN0ZZQ6ZW9Z4
Fly release_command: success
```

## Backend Health

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/health
status: 200
response:
  status: ok
  service: disclosure_automation
  phase: phase1
  repo: up
```

## Source Health

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/lv_csri_regulated_information
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  parser_key: lv_csri_regulated_information_html_v1
  fixture_path: source_payloads/lv_csri_regulated_information.html
  health_status: healthy
  last_seen_published_at: 2026-05-08T14:02:41.000000Z
```

## Live Poll

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/lv_csri_regulated_information/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.url: https://csri.investinfo.lv/en/?view=csridocuments
fetch.bytes: 71883
records_seen: 20
records_inserted: 20
canonical_items: 20
fixture fallback: false
first observed canonical key: breaking-2026-05-08-24937
```

## Digest Visibility

Latest digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 3
latvia_count: 0
observed source distribution: india_nse_announcements
```

Date-specific digest top-n checks:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-08/breaking
status: 200
item_count: 12
latvia_count: 0
observed source distribution: de_xetra_frankfurt_newsboard, eu_euronext_company_press_releases, eu_italy_emarket_storage_regulated_communications, eu_nasdaq_nordic_company_news, gr_athex_issuer_announcements, hu_bse_issuers_news, india_nse_announcements, no_oslo_bors_newsweb_main_market, uk_fca_nsm_regulated_information
```

Interpretation:

```text
Latvia CSRI live poll and canonical insert paths passed.
Current public digest top-n windows did not include Latvia CSRI rows because existing higher-ranked/diverse items filled the visible digest windows.
This is not a parser or live-fetch failure.
```

## Guardrails

```text
scheduled Latvia CSRI live polling remains disabled
source remains active=false
candidate_status remains manual_staging_only
no backend JSON response shape change
no public Source Health UI
no poll UI
no audit UI
no frontend framework change
no central-bank, macro, or policy feed added
```

## Next Step

```text
Continue Europe listed-company disclosure discovery with Prague/PSE, Portugal CMVM exact endpoint discovery, OeKB issuerinfo, or other official issuer-announcement surfaces.
Do not batch-promote scheduled EU polling until the wider source list, rollback path, source-specific risk, and staging evidence are documented together.
```
