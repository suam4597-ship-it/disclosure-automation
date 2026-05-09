# GlobalPulse Portugal CMVM Staging Live Poll Smoke Results

This document records the staging live-poll smoke for the Portugal CMVM Portal InfoPrivi issuer-information candidate.

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
PORTUGAL_CMVM_SOURCE_HEALTH_PASS
PORTUGAL_CMVM_STAGING_LIVE_POLL_PASS
PORTUGAL_CMVM_CANONICAL_INSERT_PASS
PORTUGAL_CMVM_DIGEST_TOP_N_VISIBILITY_PENDING
PORTUGAL_CMVM_MANUAL_ONLY_READY
```

## Candidate

```text
source_key: pt_cmvm_portal_info_privi
display_name: Portugal CMVM Inside Information and Other Issuer Information
parser_key: cmvm_portal_info_privi_json_v1
source URL: https://www.cmvm.pt/PInstitucional/screenservices/PInstitucional/MainFlow/PortalInstitucional/DataActionFetchSectionsInfo
authority: official Portugal CMVM issuer information disclosure portal
region: eu_south
active: false
candidate_status: manual_staging_only
```

## Validation Context

```text
candidate PR: #428 Add Portugal CMVM disclosure candidate
candidate merge commit: 1e0b15452791a6e82f98df0bdfbcde8c859e7199
local candidate validation: mix deps.get, mix format --check-formatted, MIX_ENV=test mix compile --warnings-as-errors, scripts/validate_phase0_artifacts.py
local parser smoke: fixture_records=3, live HTTP 200, live_records=3, first record issuer/title/url/published_at/category populated
Fly app: globalpulse-backend-staging
Fly deploy image: registry.fly.io/globalpulse-backend-staging:deployment-01KR657TX3EQDH1TFCSB7FZZEB
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
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/pt_cmvm_portal_info_privi
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  parser_key: cmvm_portal_info_privi_json_v1
  fixture_path: source_payloads/pt_cmvm_portal_info_privi.json
  health_status: healthy
  last_seen_published_at: 2026-05-08T16:57:48.000000Z
  last_success_at: 2026-05-09T10:43:43.694415Z
```

## Live Poll

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/pt_cmvm_portal_info_privi/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.url: https://www.cmvm.pt/PInstitucional/screenservices/PInstitucional/MainFlow/PortalInstitucional/DataActionFetchSectionsInfo
fetch.bytes: 2393
records_seen: 3
records_inserted: 3
canonical_items: 3
fixture fallback: false
first observed canonical key: breaking-2026-05-08-cmvm-f-1253421
```

## Digest Visibility

Latest digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 3
portugal_count: 0
observed source distribution: india_nse_announcements
```

Date-specific digest top-n check:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-08/breaking
status: 200
item_count: 12
portugal_count: 0
observed source distribution: de_xetra_frankfurt_newsboard, eu_euronext_company_press_releases, eu_italy_emarket_storage_regulated_communications, eu_nasdaq_nordic_company_news, gr_athex_issuer_announcements, hu_bse_issuers_news, india_nse_announcements, no_oslo_bors_newsweb_main_market, uk_fca_nsm_regulated_information
```

Interpretation:

```text
Portugal CMVM live poll and canonical insert paths passed.
Current public digest top-n windows did not include Portugal CMVM rows because existing higher-ranked/diverse items filled the visible digest windows.
This is not a parser or live-fetch failure.
```

## Guardrails

```text
scheduled Portugal CMVM live polling remains disabled
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
Continue Europe listed-company disclosure discovery with Prague/PSE multi-ISIN issuer endpoints, Austria OeKB issuerinfo machine-readable discovery, or Germany official register deeper discovery.
Do not batch-promote scheduled EU polling until the wider source list, rollback path, source-specific risk, and staging evidence are documented together.
```
