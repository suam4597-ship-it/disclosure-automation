# GlobalPulse Germany Company Register Staging Live Poll Smoke Results

This document records the staging live-poll smoke for the Germany Company Register capital-market information manual candidate.

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
GERMANY_COMPANY_REGISTER_SOURCE_HEALTH_PASS
GERMANY_COMPANY_REGISTER_STAGING_LIVE_POLL_PASS
GERMANY_COMPANY_REGISTER_CANONICAL_INSERT_PASS
GERMANY_COMPANY_REGISTER_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
GERMANY_COMPANY_REGISTER_PUBLIC_LATEST_UI_VISIBILITY_PENDING
GERMANY_COMPANY_REGISTER_MANUAL_ONLY_READY
```

## Candidate

```text
source_key: de_company_register_capital_market_info
display_name: Germany Company Register Capital Market Information
parser_key: germany_company_register_capital_market_flight_v1
source URL: https://www.unternehmensregister.de/en/search?formType=CAPITAL_MARKET
authority: official German Company Register capital-market information surface
region: eu_central
active: false
candidate_status: manual_staging_only
```

## Validation Context

```text
candidate PR: #442 Add Germany Company Register manual candidate
candidate merge commit: 06d08a0b9f17da908b3403a8ca78e1239bdab482
local candidate validation: mix format; MIX_ENV=test mix compile --warnings-as-errors; fixture parser smoke; mix format --check-formatted; scripts/validate_phase0_artifacts.py; git diff --check; MIX_ENV=test mix test
local parser smoke: fixture_records=3, first record title/url/published_at/category/external_id populated
Fly app: globalpulse-backend-staging
Fly deploy image: registry.fly.io/globalpulse-backend-staging:deployment-01KR6MQGGV7DHYBMNETWZXRZX4
Fly release_command: success
```

`MIX_ENV=test mix test` reported no tests to run.

## Backend Health

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/health
status: 200
response:
  status: ok
```

## Source Health

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/de_company_register_capital_market_info
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  parser_key: germany_company_register_capital_market_flight_v1
  fixture_path: source_payloads/de_company_register_capital_market_info.json
  health_status: healthy
  last_error: null
  last_success_at: 2026-05-09T15:14:30.157080Z
  last_seen_published_at: 2024-09-30T00:00:00.000000Z
```

## Live Poll

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/de_company_register_capital_market_info/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.strategy: germany_company_register_token_preflight_v1
fetch.support_status_code: 200
fetch.token_status_code: 200
fetch.search_status_code: 200
fetch.status_code: 200
fetch.url: https://www.unternehmensregister.de/en/search?formType=CAPITAL_MARKET
fetch.source_date_from: 2024-09-30
fetch.source_date_to: 2024-09-30
fetch.page_size: 30
fetch.max_pages_per_poll: 1
fetch.pages_fetched: 1
fetch.total_pages: 7
fetch.total_results: 188
fetch.over_page_cap: true
fetch.records_seen: 30
fetch.records_kept: 25
fetch.bytes: 52039
pipeline.records_seen: 25
records_inserted: 25
canonical_items: 25
fixture fallback: false
first observed canonical key: breaking-2024-09-30-de-company-register-e3bec60458663473471110cdedef4ccf
```

Interpretation:

```text
The live poll passed through the official support page, search-token endpoint, and tokenized ISO date query.
The adapter correctly recorded the over-page-cap condition for the 2024-09-30 source date.
The poll intentionally kept 25 canonical items because max_items_per_poll=25.
The over-page-cap condition remains a scheduled-promotion design blocker, not a manual smoke failure.
```

## Digest Visibility

Latest digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 3
germany_company_register_count: 0
observed source distribution: india_nse_announcements
```

Date-specific digest top-n check:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2024-09-30/breaking
status: 200
digest_date: 2024-09-30
item_count: 12
fallback_to_fixture: false
germany_company_register_count: 12
first observed headline: Ad-hoc-Meldung gemaess Art. 17 MAR in Verbindung mit paragraph 4 Abs. 1 S. 1 Nr. 1a WpAV
first observed published_at: 2024-09-30T00:00:00.000000Z
first observed fetch_mode: live
first observed region: eu_central
```

Interpretation:

```text
Germany Company Register live poll and canonical insert paths passed.
Date-specific digest visibility passed for 2024-09-30.
Public latest UI visibility remains pending because the latest digest currently points to 2026-05-09 India items while this manual smoke uses the documented 2024-09-30 source date.
```

## Guardrails

```text
scheduled Germany Company Register live polling remains disabled
source remains active=false
candidate_status remains manual_staging_only
over_page_cap remains true for the smoke date
no backend JSON response shape change
no public Source Health UI
no poll UI
no audit UI
no frontend framework change
no central-bank, macro, or policy feed added
```

## Next Step

```text
Keep this candidate manual-only until over-cap pagination, duplicate handling, rate/captcha behavior, and rollback are designed.
The next EU track step can be EU source batch-promotion design, or another remaining official listed-company disclosure source if the batch-promotion design is deferred.
```
