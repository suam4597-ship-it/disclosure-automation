# GlobalPulse Slovenia OAM Regulated Information Staging Live Poll Smoke Results

This document records the staging live-poll smoke for the Slovenia OAM / INFO STORAGE regulated-information candidate.

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
SLOVENIA_OAM_REGULATED_INFORMATION_SOURCE_HEALTH_PASS
SLOVENIA_OAM_REGULATED_INFORMATION_STAGING_LIVE_POLL_PASS
SLOVENIA_OAM_REGULATED_INFORMATION_CANONICAL_INSERT_PASS
SLOVENIA_OAM_REGULATED_INFORMATION_DIGEST_TOP_N_VISIBILITY_PENDING
SLOVENIA_OAM_REGULATED_INFORMATION_MANUAL_ONLY_READY
```

## Candidate

```text
source_key: si_oam_regulated_information
display_name: Slovenia OAM Regulated Information
parser_key: rss_v1
source URL: https://www.oam.si/rss
authority: official Ljubljana Stock Exchange INFO STORAGE / OAM regulated-information RSS feed
region: eu_central
active: false
candidate_status: manual_staging_only
```

## Validation Context

```text
candidate PR: #415 Add Slovenia OAM regulated information candidate
candidate merge commit: 0a2355b0c6d4afd3950de5e3c4056d13e7ddae14
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
Fly app: globalpulse-backend-staging
Fly deploy image: registry.fly.io/globalpulse-backend-staging:deployment-01KR59VCYKTKTFNXE795ZMGQ4X
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
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/si_oam_regulated_information
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  fixture_path: source_payloads/si_oam_regulated_information.xml
```

## Live Poll

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/si_oam_regulated_information/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.url: https://www.oam.si/rss
fetch.bytes: 4656
records_seen: 11
records_inserted: 11
canonical_items: 11
fixture fallback: false
```

Observed canonical item keys included:

```text
breaking-2026-05-08-https-www-oam-si-doc-id-39648
breaking-2026-05-08-https-www-oam-si-doc-id-39649
breaking-2026-05-08-https-www-oam-si-doc-id-39650
breaking-2026-05-08-https-www-oam-si-doc-id-39651
breaking-2026-05-08-https-www-oam-si-doc-id-39652
breaking-2026-05-07-https-www-oam-si-doc-id-39646
breaking-2026-05-07-https-www-oam-si-doc-id-39647
breaking-2026-05-05-https-www-oam-si-doc-id-39644
breaking-2026-05-05-https-www-oam-si-doc-id-39645
breaking-2026-05-04-https-www-oam-si-doc-id-39642
breaking-2026-05-04-https-www-oam-si-doc-id-39643
```

## Digest Visibility

Latest digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 3
slovenia_count: 0
observed source distribution: india_nse_announcements
```

Date-specific digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-08/breaking
status: 200
digest_date: 2026-05-08
item_count: 12
slovenia_count: 0
observed source distribution:
  india_nse_announcements
  eu_nasdaq_nordic_company_news
  gr_athex_issuer_announcements
  no_oslo_bors_newsweb_main_market
  hu_bse_issuers_news
  eu_italy_emarket_storage_regulated_communications
  uk_fca_nsm_regulated_information
  de_xetra_frankfurt_newsboard
  eu_euronext_company_press_releases
```

Interpretation:

```text
The live poll and canonical insert path passed.
Public latest and date-specific top-n digest visibility is still pending because the existing digest windows are already filled by higher-ranked/diverse items.
This is not a parser or live-fetch failure.
```

## Guardrails

```text
scheduled Slovenia OAM live polling remains disabled
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
Continue Europe listed-company disclosure discovery with Croatia ZSE/EHO issuer news or Slovakia CERI.
Do not batch-promote scheduled EU polling until the wider source list, rollback path, source-specific risk, and staging evidence are documented together.
```
