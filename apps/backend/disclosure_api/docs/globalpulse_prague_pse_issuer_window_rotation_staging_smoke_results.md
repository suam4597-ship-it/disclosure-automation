# GlobalPulse Prague PSE Issuer Window Rotation Staging Smoke Results

This document records the Fly staging smoke for Prague Stock Exchange issuer report calendar deterministic issuer-window rotation.

The source remains manual-only. This smoke does not enable scheduling, does not set PSE sources active, does not add PSE to the EU canary, and does not expose issuer-window controls through public API or UI.

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
PRAGUE_PSE_REPORT_CALENDAR_OFFSET_0_SMOKE_PASS
PRAGUE_PSE_REPORT_CALENDAR_OFFSET_10_SMOKE_PASS
PRAGUE_PSE_ISSUER_WINDOW_ROTATION_SMOKE_PASS
PRAGUE_PSE_FIXTURE_FALLBACK_FALSE_PASS
PRAGUE_PSE_OFFSET_RESTORED_TO_0
PRAGUE_PSE_REMAINS_MANUAL_STAGING_ONLY
PRAGUE_PSE_SCHEDULED_POLLING_STILL_BLOCKED
```

## Candidate

```text
source_key: cz_pse_issuer_report_calendar_multi_isin
display_name: Prague PSE Issuer Report Calendar Multi-ISIN
parser_key: pse_multi_isin_issuer_report_calendar_json_v1
fetch strategy: pse_multi_isin_report_calendar_v1
authority: official Prague Stock Exchange issuer report/calendar surface
region: eu_central
active: false
candidate_status: manual_staging_only
```

## Validation Context

```text
implementation PR: #454 Add PSE issuer window rotation
implementation merge commit: 95b8d6f9b92bbd7355fc00ab45abc1d06e20f43f
staging deploy base commit: c866156af03727fc792a0c0d296de4a155ac86f3
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

After the offset rotation smoke and restore:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/cz_pse_issuer_report_calendar_multi_isin
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  parser_key: pse_multi_isin_issuer_report_calendar_json_v1
  live_fetch_strategy: pse_multi_isin_report_calendar_v1
  max_issuers_per_poll: 10
  max_calendar_items_per_issuer: 8
  pse_issuer_window_strategy: static_offset
  pse_issuer_window_offset: 0
  health_status: healthy
  last_success_at: 2026-05-10T08:58:16.377745Z
  last_seen_published_at: 2026-04-30T00:00:00.000000Z
```

## Offset 0 Live Poll

The default staging config uses the first deterministic 10-issuer window.

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/cz_pse_issuer_report_calendar_multi_isin/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.fixture_fallback: false
fetch.strategy: pse_multi_isin_report_calendar_v1
fetch.status_code: 200
fetch.universe_count: 63
fetch.selected_issuer_count: 10
fetch.selected_issuer_window_strategy: static_offset
fetch.selected_issuer_window_offset: 0
fetch.selected_issuer_window_size: 10
fetch.selected_issuer_window_universe_count: 63
fetch.calendar_request_count: 10
records_seen: 20
records_inserted: 20
canonical_items: 20
raw_documents: 20
```

## Offset 10 Live Poll

For the second manual smoke, staging source config was temporarily updated to:

```text
pse_issuer_window_strategy: static_offset
pse_issuer_window_offset: 10
```

The same source was then polled again:

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/cz_pse_issuer_report_calendar_multi_isin/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.fixture_fallback: false
fetch.strategy: pse_multi_isin_report_calendar_v1
fetch.status_code: 200
fetch.universe_count: 63
fetch.selected_issuer_count: 10
fetch.selected_issuer_window_strategy: static_offset
fetch.selected_issuer_window_offset: 10
fetch.selected_issuer_window_size: 10
fetch.selected_issuer_window_universe_count: 63
fetch.calendar_request_count: 10
records_seen: 11
records_inserted: 11
canonical_items: 11
raw_documents: 11
```

Interpretation:

```text
Both deterministic issuer windows reached the official PSE issuer universe and report-calendar API without fixture fallback.
The bounded window metadata proves that the two staging smokes used different issuer windows.
The manual offset override was restored to 0 after the offset 10 smoke.
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

Date-specific PSE digest visibility was previously recorded for report-calendar rows dated 2026-04-27, 2026-04-28, and 2026-04-30 in `globalpulse_prague_pse_issuer_report_calendar_staging_live_poll_smoke_results.md`.

For this rotation smoke, the success criteria are the live poll responses, selected-window metadata, canonical insert counts, fixture_fallback=false, and final source-health confirmation that the offset was restored to 0.

## Guardrails

```text
source remains active=false
candidate_status remains manual_staging_only
scheduled Prague PSE polling remains disabled
PSE is not added to the EU scheduled canary
issuer-window offset is not exposed through public API or UI
max_issuers_per_poll remains bounded at 10
do not run issuer news and report calendar simultaneously
no backend JSON response shape change
no public Source Health UI
no public poll UI
no audit UI
no frontend framework change
no central-bank, macro, or policy feed added
JP live polling remains blocked pending source authority decision
```

## Next Step

```text
Keep PSE manual-only.
Before any scheduled staging canary discussion, run repeated offset-window smokes and document request budget, cadence, rollback, and source separation behavior under globalpulse_prague_pse_cadence_rate_design.md.
```
