# GlobalPulse Germany Company Register Multi-Page Staging Smoke Results

This document records the Fly staging smoke for the Germany Company Register capital-market information two-page manual probe.

The source remains manual-only. This smoke does not enable scheduling, does not set the source active, does not add the source to the EU canary, and does not change public digest JSON shape.

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
GERMANY_COMPANY_REGISTER_MULTIPAGE_STAGING_SMOKE_PASS
GERMANY_COMPANY_REGISTER_PAGES_FETCHED_2_PASS
GERMANY_COMPANY_REGISTER_FIXTURE_FALLBACK_FALSE_PASS
GERMANY_COMPANY_REGISTER_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
GERMANY_COMPANY_REGISTER_OVER_PAGE_CAP_STILL_TRUE_EXPECTED
GERMANY_COMPANY_REGISTER_REMAINS_MANUAL_STAGING_ONLY
GERMANY_COMPANY_REGISTER_SCHEDULED_POLLING_STILL_BLOCKED
```

## Candidate

```text
source_key: de_company_register_capital_market_info
display_name: Germany Company Register Capital Market Information
parser_key: germany_company_register_capital_market_flight_v1
fetch strategy: germany_company_register_token_preflight_v1
authority: official German Company Register capital-market information surface
region: eu_central
active: false
candidate_status: manual_staging_only
```

## Validation Context

```text
implementation PR: #455 Add Germany Company Register multipage staging probe
implementation merge commit: c866156af03727fc792a0c0d296de4a155ac86f3
Fly app: globalpulse-backend-staging
Fly release version: 54
Fly release created_at: 2026-05-10T08:54:35Z
Fly deploy image: registry.fly.io/globalpulse-backend-staging:deployment-01KR8HEBY3E5K4D53VTXAB5MQ4
Fly deploy: success
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

After deploying and refreshing staging source config:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/de_company_register_capital_market_info
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  parser_key: germany_company_register_capital_market_flight_v1
  live_fetch_strategy: germany_company_register_token_preflight_v1
  page_size: 30
  max_pages_per_poll: 2
  source_date_from: 2024-09-30
  source_date_to: 2024-09-30
  health_status: healthy
  last_success_at: 2026-05-10T08:57:02.678581Z
  last_seen_published_at: 2024-09-30T00:00:00.000000Z
```

## Multi-Page Live Poll

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/de_company_register_capital_market_info/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.fixture_fallback: false
fetch.strategy: germany_company_register_token_preflight_v1
fetch.support_status_code: 200
fetch.token_status_code: 200
fetch.search_status_code: 200
fetch.page_size: 30
fetch.max_pages_per_poll: 2
fetch.pages_fetched: 2
fetch.total_pages: 7
fetch.total_results: 188
fetch.records_seen: 60
fetch.records_kept: 25
fetch.over_page_cap: true
pipeline.records_seen: 25
records_inserted: 25
canonical_items: 25
raw_documents: 25
```

Interpretation:

```text
The official support-page preflight, token fetch, and tokenized search request all returned 200.
The bounded two-page probe fetched two result pages and inserted canonical items without fixture fallback.
The over-page-cap condition remains true for the historical smoke date. That is expected for this manual probe and remains a blocker for any scheduled polling discussion.
```

## Digest Visibility

Latest digest after the smoke:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 12
metadata.fallback_to_fixture: false
```

Date-specific digest check:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2024-09-30/breaking
status: 200
digest_date: 2024-09-30
item_count: 12
metadata.fallback_to_fixture: false
germany_company_register_count: 12
first observed region: eu_central
```

Interpretation:

```text
Germany Company Register live poll and canonical insert paths passed.
Date-specific digest visibility passed for the 2024-09-30 bounded historical smoke date.
Public latest UI visibility is not the success criterion for this candidate because the current latest digest points to newer 2026-05-09 live items.
```

## Guardrails

```text
source remains active=false
candidate_status remains manual_staging_only
scheduled Germany Company Register polling remains disabled
Germany Company Register is not added to the EU scheduled canary
max_pages_per_poll remains bounded at 2 for this track
over_page_cap remains a scheduled-promotion blocker
no backend JSON response shape change
no public Source Health UI
no public poll UI
no audit UI
no frontend framework change
no central-bank, macro, or policy feed added
```

## Next Step

```text
Keep Germany Company Register manual-only.
Before scheduling, record repeated multi-page smokes and resolve the over-page-cap, duplicate handling, rate/captcha behavior, and rollback plan described in globalpulse_germany_company_register_pagination_rate_captcha_design.md.
```
