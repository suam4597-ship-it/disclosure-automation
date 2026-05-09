# GlobalPulse Prague PSE Issuer Report Calendar Staging Live Poll Smoke Results

This document records the staging live-poll smoke for the Prague Stock Exchange issuer report calendar multi-ISIN candidate.

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
PRAGUE_PSE_ISSUER_REPORT_CALENDAR_SOURCE_HEALTH_PASS
PRAGUE_PSE_ISSUER_REPORT_CALENDAR_STAGING_LIVE_POLL_PASS
PRAGUE_PSE_ISSUER_REPORT_CALENDAR_CANONICAL_INSERT_PASS
PRAGUE_PSE_ISSUER_REPORT_CALENDAR_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
PRAGUE_PSE_ISSUER_REPORT_CALENDAR_MANUAL_ONLY_READY
```

## Candidate

```text
source_key: cz_pse_issuer_report_calendar_multi_isin
display_name: Prague PSE Issuer Report Calendar Multi-ISIN
parser_key: pse_multi_isin_issuer_report_calendar_json_v1
source URL: https://www.pse.cz/en/market-data/shares/prime-market
fetch strategy: pse_multi_isin_report_calendar_v1
authority: official Prague Stock Exchange issuer report/calendar surface
region: eu_central
active: false
candidate_status: manual_staging_only
```

## Validation Context

```text
candidate PR: #438 Add Prague PSE report calendar candidate
candidate merge commit: 2603aab0bd475635b8e0127bd2d5528a774a2bbb
local candidate validation: mix deps.get, mix format, MIX_ENV=test mix compile --warnings-as-errors, mix format --check-formatted, scripts/validate_phase0_artifacts.py, git diff --check
local parser smoke: fixture_records=4; live aggregate parser smoke universe_count=63, selected_count=10, response_count=10, response_records=65, strict_records=20
Fly app: globalpulse-backend-staging
Fly deploy image: registry.fly.io/globalpulse-backend-staging:deployment-01KR6GGP6M143CQ09SSVY7C6JA
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
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/cz_pse_issuer_report_calendar_multi_isin
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  disable_live_fixture_fallback: true
  parser_key: pse_multi_isin_issuer_report_calendar_json_v1
  fixture_path: source_payloads/cz_pse_issuer_report_calendar_multi_isin.json
  live_fetch_strategy: pse_multi_isin_report_calendar_v1
  max_issuers_per_poll: 10
  max_calendar_items_per_issuer: 8
  health_status: unknown
```

After live poll:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/cz_pse_issuer_report_calendar_multi_isin
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  parser_key: pse_multi_isin_issuer_report_calendar_json_v1
  health_status: healthy
  last_seen_published_at: 2026-04-30T00:00:00.000000Z
  last_success_at: 2026-05-09T14:00:54.920610Z
```

## Live Poll

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/cz_pse_issuer_report_calendar_multi_isin/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.strategy: pse_multi_isin_report_calendar_v1
fetch.status_code: 200
fetch.url: https://www.pse.cz/en/market-data/shares/prime-market
fetch.bytes: 27656
fetch.universe_count: 63
fetch.selected_issuer_count: 10
fetch.calendar_request_count: 10
records_seen: 20
records_inserted: 20
canonical_items: 20
raw_documents: 20
fixture fallback: false
first observed canonical key: breaking-2026-04-27-pse-report-calendar-cz0009008942-3566236
last observed canonical key: breaking-2026-04-30-pse-report-calendar-cz0005135970-3566233
```

## Digest Visibility

Latest digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 3
pse_report_calendar_count: 0
metadata.fallback_to_fixture: false
metadata.top_n: 12
```

Date-specific digest checks:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-04-30/breaking
status: 200
item_count: 12
metadata.fallback_to_fixture: false
observed:
  headline: Annual Financial Report
  canonical_url: https://www.pse.cz/en/detail/CZ1008000310?do=download&path=Issuers.dta/Emitenti2/DSPWXC012025.zip
  duplicate_group_key: cz_pse_issuer_report_calendar_multi_isin-pse-report-calendar-cz1008000310-3566251
  published_at: 2026-04-30T00:00:00.000000Z
  regions: eu_central
  category: PSE issuer report
  fetch_mode: live
```

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-04-28/breaking
status: 200
item_count: 7
metadata.fallback_to_fixture: false
observed:
  headline: Annual Financial Report
  canonical_url: https://www.pse.cz/en/detail/CZ0005112300?do=download&path=Issuers.dta/Emitenti2/CEZXE012025.pdf
  duplicate_group_key: cz_pse_issuer_report_calendar_multi_isin-pse-report-calendar-cz0005112300-3566196
  published_at: 2026-04-28T00:00:00.000000Z
  regions: eu_central
  category: PSE issuer report
  fetch_mode: live
```

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-04-27/breaking
status: 200
item_count: 2
metadata.fallback_to_fixture: false
observed:
  headline: Annual Financial Report
  canonical_url: https://www.pse.cz/en/detail/CZ0009008942?do=download&path=Issuers.dta/Emitenti2/CZGCEXE012025.pdf
  duplicate_group_key: cz_pse_issuer_report_calendar_multi_isin-pse-report-calendar-cz0009008942-3566236
  published_at: 2026-04-27T00:00:00.000000Z
  regions: eu_central
  category: PSE issuer report
  fetch_mode: live
```

Interpretation:

```text
Prague PSE issuer report calendar live poll, source-specific fan-out fetch, parser, and canonical insert paths passed.
The latest digest did not include PSE report calendar rows because the current latest digest date is 2026-05-09 and report calendar rows are dated February-April 2026.
Date-specific digest visibility passed for PSE report calendar rows without fixture fallback.
```

## Guardrails

```text
scheduled Prague PSE report calendar live polling remains disabled
source remains active=false
candidate_status remains manual_staging_only
direct file-reports rows remain non-canonical because they do not carry publication-date fields
no backend JSON response shape change
no public Source Health UI
no poll UI
no audit UI
no frontend framework change
no central-bank, macro, or policy feed added
```

## Next Step

```text
Continue Europe listed-company disclosure expansion with Germany Company Register browser/network preflight, or start an EU source batch promotion design that keeps scheduled polling disabled until rollback and source-risk controls are documented.
```
