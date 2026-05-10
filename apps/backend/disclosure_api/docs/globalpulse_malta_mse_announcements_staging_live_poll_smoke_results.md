# GlobalPulse Malta MSE Announcements Staging Live Poll Smoke Results

This document records the Fly staging live-poll smoke for the Malta Stock Exchange announcements manual candidate.

The source remains manual-only. This smoke does not enable scheduling, does not add Malta MSE to the EU canary, does not change public digest JSON shape, and does not add frontend UI.

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
MALTA_MSE_ANNOUNCEMENTS_SOURCE_HEALTH_PASS
MALTA_MSE_ANNOUNCEMENTS_STAGING_LIVE_POLL_PASS
MALTA_MSE_ANNOUNCEMENTS_CANONICAL_INSERT_PASS
MALTA_MSE_ANNOUNCEMENTS_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
MALTA_MSE_ANNOUNCEMENTS_MANUAL_ONLY_READY
MALTA_MSE_SCHEDULED_POLLING_STILL_BLOCKED
```

## Candidate

```text
source_key: mt_mse_announcements
display_name: Malta Stock Exchange Announcements
parser_key: malta_mse_announcements_html_v1
source URL: https://www.borzamalta.com.mt/news-and-articles/announcements
authority: official Malta Stock Exchange announcement surface
region: eu_south
active: false
candidate_status: manual_staging_only
```

## Validation Context

```text
candidate PR: #457 Add Malta MSE announcements candidate
candidate merge commit: 184d5bd871ec0c2e10792ffe80b3441980b5a7d2
local candidate validation: MIX_ENV=test mix compile --warnings-as-errors; fixture parser smoke; live parser smoke; git diff --cached --check
fixture parser smoke: fixture_records=3, first record issuer/title/url/published_at populated
live parser smoke: HTTP 200, live_records=9, first live record Loqus Holding plc - Interim Update
Fly app: globalpulse-backend-staging
Fly deploy image: registry.fly.io/globalpulse-backend-staging:deployment-01KR8KTSQBHDSBA1AKZW3HGC95
Fly deploy: success
Fly release_command: success
```

`scripts/validate_phase0_artifacts.py` was not run locally because this Windows environment did not have `python` or `py` on PATH.

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
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/mt_mse_announcements
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  parser_key: malta_mse_announcements_html_v1
  fixture_path: source_payloads/mt_mse_announcements.html
  health_status: unknown
```

After live poll:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/mt_mse_announcements
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  parser_key: malta_mse_announcements_html_v1
  health_status: healthy
  last_success_at: 2026-05-10T09:37:17.966161Z
  last_seen_published_at: 2026-05-08T00:00:00.000000Z
```

## Live Poll

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/mt_mse_announcements/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.url: https://www.borzamalta.com.mt/news-and-articles/announcements
fetch.bytes: 229450
records_seen: 9
records_inserted: 9
canonical_items: 9
raw_documents: 9
fixture fallback: false
first observed canonical key: breaking-2026-05-08-lqs248-pdf
```

Interpretation:

```text
The official Malta Stock Exchange announcements page returned server-rendered HTML and the bounded parser extracted issuer announcement cards.
The live poll inserted canonical items without fixture fallback.
```

## Digest Visibility

Latest digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 12
metadata.fallback_to_fixture: false
malta_count: 0
observed source distribution: ch_six_ser_official_notices=9, india_nse_announcements=3
```

Date-specific digest checks:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-07/breaking
status: 200
item_count: 12
metadata.fallback_to_fixture: false
malta_count: 3
observed source distribution includes: mt_mse_announcements=3
```

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-06/breaking
status: 200
item_count: 12
metadata.fallback_to_fixture: false
malta_count: 4
observed source distribution includes: mt_mse_announcements=4
```

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-05/breaking
status: 200
item_count: 12
metadata.fallback_to_fixture: false
malta_count: 1
observed Malta headline: RS2 plc - Information to the market
```

Interpretation:

```text
Malta MSE live poll and canonical insert paths passed.
Date-specific digest visibility passed for Malta rows dated 2026-05-07, 2026-05-06, and 2026-05-05.
The latest digest did not include Malta rows because the current latest digest date is 2026-05-09 and is filled by Switzerland SIX and India NSE items.
```

## Guardrails

```text
scheduled Malta MSE live polling remains disabled
source remains active=false
candidate_status remains manual_staging_only
Malta MSE is not added to the EU scheduled canary
no backend JSON response shape change
no public Source Health UI
no public poll UI
no audit UI
no frontend framework change
no central-bank, macro, or policy feed added
JP live polling remains blocked pending issue #339 source-authority decision
```

## Next Step

```text
Keep Malta MSE manual-only.
Do not add it to the scheduled EU canary until the broader batch-promotion guardrails, rollback path, source-specific risk, and observation-window criteria are reviewed together.
```
