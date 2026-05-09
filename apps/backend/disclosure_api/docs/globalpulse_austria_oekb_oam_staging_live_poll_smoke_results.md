# GlobalPulse Austria OeKB OAM Staging Live Poll Smoke Results

This document records the staging live-poll smoke for the Austria OeKB OAM Issuer Info JSON candidate.

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
AUSTRIA_OEKB_OAM_SOURCE_HEALTH_PASS
AUSTRIA_OEKB_OAM_STAGING_LIVE_POLL_PASS
AUSTRIA_OEKB_OAM_CANONICAL_INSERT_PASS
AUSTRIA_OEKB_OAM_DIGEST_TOP_N_VISIBILITY_PENDING
AUSTRIA_OEKB_OAM_MANUAL_ONLY_READY
```

## Candidate

```text
source_key: at_oekb_oam_issuer_info
display_name: Austria OeKB OAM Issuer Info
parser_key: oekb_oam_issuer_info_json_v1
source URL: https://my.oekb.at/issuer-info/rest/public/meldedaten/iic?startPosition=0&offset=25&locale=en
authority: official Austria OAM / central storage system for listed-issuer information
region: eu_central
active: false
candidate_status: manual_staging_only
```

## Validation Context

```text
candidate PR: #431 Add Austria OeKB OAM issuer info candidate
candidate merge commit: bb7b16f68a8532493143c64255c7cafb7bf75631
local candidate validation: mix deps.get, mix format, MIX_ENV=test mix compile --warnings-as-errors, mix format --check-formatted, scripts/validate_phase0_artifacts.py, git diff --check
local parser smoke: fixture_records=2, live HTTP 200, live_records=25, first record issuer/title/url/published_at/category populated
Fly app: globalpulse-backend-staging
Fly deploy image: registry.fly.io/globalpulse-backend-staging:deployment-01KR67SWRTQ3ZQ8R8EY583HGZQ
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

Before live poll:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/at_oekb_oam_issuer_info
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  parser_key: oekb_oam_issuer_info_json_v1
  fixture_path: source_payloads/at_oekb_oam_issuer_info.json
  health_status: unknown
```

After live poll:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/at_oekb_oam_issuer_info
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  parser_key: oekb_oam_issuer_info_json_v1
  fixture_path: source_payloads/at_oekb_oam_issuer_info.json
  health_status: healthy
  last_seen_published_at: 2026-05-08T16:10:28.230000Z
  last_success_at: 2026-05-09T11:29:45.995562Z
```

## Live Poll

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/at_oekb_oam_issuer_info/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.url: https://my.oekb.at/issuer-info/rest/public/meldedaten/iic?startPosition=0&offset=25&locale=en
fetch.bytes: 19260
records_seen: 25
records_inserted: 25
canonical_items: 25
fixture fallback: false
first observed canonical key: breaking-2026-05-08-oekb-248344
```

## Digest Visibility

Latest digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 3
oekb_count: 0
metadata.fallback_to_fixture: false
observed source distribution: india_nse_announcements
```

Date-specific digest top-n check:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-08/breaking
status: 200
item_count: 12
oekb_count: 0
metadata.fallback_to_fixture: false
observed source distribution: de_xetra_frankfurt_newsboard, eu_euronext_company_press_releases, eu_italy_emarket_storage_regulated_communications, eu_nasdaq_nordic_company_news, gr_athex_issuer_announcements, hu_bse_issuers_news, india_nse_announcements, no_oslo_bors_newsweb_main_market, uk_fca_nsm_regulated_information
```

Interpretation:

```text
Austria OeKB OAM live poll and canonical insert paths passed.
Current public digest top-n windows did not include OeKB rows because existing later items filled the visible 2026-05-08 digest window.
This is not a parser or live-fetch failure.
```

## Guardrails

```text
scheduled Austria OeKB OAM live polling remains disabled
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
Continue Europe listed-company disclosure discovery with Prague/PSE multi-ISIN source design or Germany official register deeper discovery.
Do not batch-promote scheduled EU polling until the wider source list, rollback path, source-specific risk, and staging evidence are documented together.
```
