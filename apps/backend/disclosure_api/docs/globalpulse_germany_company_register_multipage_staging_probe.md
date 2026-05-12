# GlobalPulse Germany Company Register Multi-Page Staging Probe

This document records the staging-only implementation gate for the Germany Company Register capital-market information multi-page probe.

The change keeps the source inactive, does not enable scheduled polling, does not add Germany Company Register to the EU scheduled canary, does not change public digest JSON shape, and does not add frontend UI.

## Conclusion

```text
GERMANY_COMPANY_REGISTER_MULTIPAGE_STAGING_PROBE_READY
GERMANY_COMPANY_REGISTER_MAX_PAGES_PER_POLL_SET_TO_2_FOR_MANUAL_SMOKE
GERMANY_COMPANY_REGISTER_SOURCE_REMAINS_INACTIVE
GERMANY_COMPANY_REGISTER_SCHEDULED_POLLING_STILL_BLOCKED
```

## Implemented Behavior

The existing inactive/manual source remains:

```text
source_key: de_company_register_capital_market_info
active: false
candidate_status: manual_staging_only
live_fetch_strategy: germany_company_register_token_preflight_v1
parser_key: germany_company_register_capital_market_flight_v1
```

The sample source config now allows a bounded two-page manual staging probe:

```yaml
page_size: 30
max_pages_per_poll: 2
```

This uses the existing fetch path, which already records:

```text
pages_fetched
total_pages
total_results
records_seen
records_kept
over_page_cap
support_status_code
token_status_code
search_status_code
fixture_fallback=false
```

## Required Manual Smoke

Before any scheduling discussion, run a manual Fly staging smoke for the same bounded historical date window:

```text
source_date_from: 2024-09-30
source_date_to: 2024-09-30
page_size: 30
max_pages_per_poll: 2
```

Expected evidence to record:

```text
GET /api/health -> 200
POST /api/admin/sources/de_company_register_capital_market_info/poll?use_live_fetch=true&edition=breaking -> 202
fetch.strategy=germany_company_register_token_preflight_v1
support_status_code=200
token_status_code=200
search_status_code=200
pages_fetched=2 or lower if total_pages ends sooner
total_pages
total_results
records_seen
records_kept
records_inserted
over_page_cap
fixture_fallback=false
date-specific digest visibility
source health after the run
```

The first smoke can still report `over_page_cap=true`; that is acceptable for a manual two-page probe and remains a blocker for scheduled polling.

## Guardrails

```text
do not set Germany Company Register active=true
do not add Germany Company Register to the first EU scheduled staging canary
do not enable production scheduled polling
do not increase max_pages_per_poll above 2 in this track
do not expose page cap through public API or UI
do not change backend digest JSON response shape
do not add public poll UI
do not add public Source Health UI
do not add frontend framework
```

## Next Step

Deploy this branch to Fly staging after merge, run the manual two-page poll once, and record the result in a docs-only smoke PR.

Only after repeated multi-page manual smokes pass without captcha/security-query/login hard stops should a separate runbook consider Germany Company Register for a scheduled staging canary.
