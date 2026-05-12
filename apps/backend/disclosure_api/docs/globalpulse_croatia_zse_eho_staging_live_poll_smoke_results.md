# GlobalPulse Croatia ZSE EHO Staging Live Poll Smoke Results

This document records the staging live-poll smoke for the Croatia Zagreb Stock Exchange EHO issuer-news and financial-report RSS candidates.

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
CROATIA_ZSE_EHO_ISSUER_NEWS_SOURCE_HEALTH_PASS
CROATIA_ZSE_EHO_FINANCIAL_REPORTS_SOURCE_HEALTH_PASS
CROATIA_ZSE_EHO_ISSUER_NEWS_STAGING_LIVE_POLL_PASS
CROATIA_ZSE_EHO_FINANCIAL_REPORTS_STAGING_LIVE_POLL_PASS
CROATIA_ZSE_EHO_ISSUER_NEWS_CANONICAL_INSERT_PASS
CROATIA_ZSE_EHO_FINANCIAL_REPORTS_CANONICAL_INSERT_PASS
CROATIA_ZSE_EHO_FINANCIAL_REPORTS_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
CROATIA_ZSE_EHO_ISSUER_NEWS_DIGEST_TOP_N_VISIBILITY_PENDING
CROATIA_ZSE_EHO_MANUAL_ONLY_READY
```

## Candidates

```text
source_key: hr_zse_eho_issuer_news
display_name: Croatia ZSE EHO Issuer News
parser_key: rss_v1
source URL: https://eho.zse.hr/en/feed/rss?variant=issuerNews
authority: official Zagreb Stock Exchange EHO issuer-announcement RSS feed
region: eu_south
active: false
candidate_status: manual_staging_only
```

```text
source_key: hr_zse_eho_financial_reports
display_name: Croatia ZSE EHO Financial Reports
parser_key: rss_v1
source URL: https://eho.zse.hr/en/feed/rss?vrsta=financ
authority: official Zagreb Stock Exchange EHO financial-report RSS feed
region: eu_south
active: false
candidate_status: manual_staging_only
```

## Validation Context

```text
candidate PR: #417 Add Croatia ZSE EHO disclosure candidates
candidate merge commit: d8cd6a07de5ca69479fcfb2fcc9d280f6c604412
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
Fly app: globalpulse-backend-staging
Fly deploy image: registry.fly.io/globalpulse-backend-staging:deployment-01KR5AGVXPQJZ48BEFMG8P993S
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
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/hr_zse_eho_issuer_news
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  fixture_path: source_payloads/hr_zse_eho_issuer_news.xml
```

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/hr_zse_eho_financial_reports
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  fixture_path: source_payloads/hr_zse_eho_financial_reports.xml
```

## Live Poll

Issuer news:

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/hr_zse_eho_issuer_news/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.url: https://eho.zse.hr/en/feed/rss?variant=issuerNews
fetch.bytes: 7717
records_seen: 20
records_inserted: 20
canonical_items: 20
fixture fallback: false
first observed canonical key: breaking-2026-05-08-https-eho-zse-hr-en-issuer-announcements-view-66917
```

Financial reports:

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/hr_zse_eho_financial_reports/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.url: https://eho.zse.hr/en/feed/rss?vrsta=financ
fetch.bytes: 8007
records_seen: 20
records_inserted: 20
canonical_items: 20
fixture fallback: false
first observed canonical key: breaking-2026-05-04-https-eho-zse-hr-fileadmin-issuers-tok-fi-tok-d379df3ad1de28f71efdcceeffd71c3b-pdf
```

## Digest Visibility

Latest digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 3
croatia_count: 0
observed source distribution: india_nse_announcements
```

Issuer-news date-specific digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-08/breaking
status: 200
digest_date: 2026-05-08
item_count: 12
croatia_count: 0
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

Financial-report date-specific digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-04/breaking
status: 200
digest_date: 2026-05-04
item_count: 6
croatia_count: 2
croatia_sources: hr_zse_eho_financial_reports
first Croatia headline: TOKIĆ d.d. - Financial report - 2026, First quarter, Unrevised, Unconsolidated - correction
observed source distribution:
  hr_zse_eho_financial_reports
  gr_athex_corporate_actions
  si_oam_regulated_information
```

Interpretation:

```text
Both Croatia EHO live poll and canonical insert paths passed.
Financial reports are visible in the 2026-05-04 date-specific digest.
Issuer news remains pending for digest top-n visibility because the 2026-05-08 digest window is already filled by other higher-ranked/diverse items.
This is not a parser or live-fetch failure.
```

## Guardrails

```text
scheduled Croatia EHO live polling remains disabled
both sources remain active=false
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
Continue Europe listed-company disclosure discovery with Slovakia CERI, Prague/PSE, Portugal CMVM exact endpoint discovery, or other official issuer-announcement surfaces.
Do not batch-promote scheduled EU polling until the wider source list, rollback path, source-specific risk, and staging evidence are documented together.
```
