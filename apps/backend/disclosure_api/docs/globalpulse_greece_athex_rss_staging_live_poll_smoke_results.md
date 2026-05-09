# GlobalPulse Greece ATHEX RSS Staging Live Poll Smoke Results

Date: 2026-05-09

## Scope

This record covers the manual staging live smoke for the Greece Euronext Athens / ATHEX RSS sources added by PR #404 and stabilized by the bounded summary fallback in PR #405.

```text
source_key: gr_athex_issuer_announcements
display_name: Greece ATHEX Issuer Announcements
source_type: rss
parser_key: rss_v1
candidate_status: manual_staging_only
active: false

source_key: gr_athex_corporate_actions
display_name: Greece ATHEX Corporate Actions
source_type: rss
parser_key: rss_v1
candidate_status: manual_staging_only
active: false
```

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
GREECE_ATHEX_ISSUER_ANNOUNCEMENTS_OFFICIAL_RSS_PASS
GREECE_ATHEX_CORPORATE_ACTIONS_OFFICIAL_RSS_PASS
GREECE_ATHEX_ISSUER_ANNOUNCEMENTS_STAGING_LIVE_POLL_PASS
GREECE_ATHEX_CORPORATE_ACTIONS_STAGING_LIVE_POLL_PASS
GREECE_ATHEX_FIXTURE_FALLBACK_FALSE
GREECE_ATHEX_SOURCE_HEALTH_HEALTHY
GREECE_ATHEX_DATE_DIGEST_RENDERABLE_PASS
GREECE_ATHEX_PUBLIC_LATEST_UI_VISIBILITY_PENDING
EU_SCHEDULED_LIVE_POLLING_STILL_DISABLED
```

## Evidence

```text
backend URL: https://globalpulse-backend-staging.fly.dev
deploy target: globalpulse-backend-staging
deploy result: success
release_command result: success
health endpoint: GET /api/health -> 200
health body: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

Issuer announcements poll:

```text
POST /api/admin/sources/gr_athex_issuer_announcements/poll?edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 18327
records_seen: 20
records_inserted: 20
metadata.fallback_to_fixture: false
source_health: healthy
last_seen_published_at: 2026-05-08T21:37:14.000000Z
```

Corporate actions poll:

```text
POST /api/admin/sources/gr_athex_corporate_actions/poll?edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 21909
records_seen: 20
records_inserted: 20
metadata.fallback_to_fixture: false
source_health: healthy
last_seen_published_at: 2026-05-05T13:00:00.000000Z
```

Date-specific digest renderability:

```text
GET /api/feed/digest/2026-05-08/breaking -> 200
rendered source: Greece ATHEX Issuer Announcements
rendered headline: Announcement on the Greek Information Document
rendered region: eu_south

GET /api/feed/digest/2026-05-05/breaking -> 200
rendered source: Greece ATHEX Corporate Actions
rendered headline: BRIQ PROPERTIES REIC & BLE KEDROS REIC - CASH DISTRIBUTIONS 06 - 05 - 2026
rendered region: eu_south
```

Latest digest note:

```text
GET /api/feed/digest/latest?edition=breaking -> 200
latest digest_date at smoke time: 2026-05-09
latest digest rendered India NSE Announcements items
ATHEX items were published on 2026-05-08 and 2026-05-05 and therefore did not appear in the public latest-only shell at smoke time
```

## Guardrails

```text
scheduled live Greece polling remains disabled
sources remain active=false
sources remain manual_staging_only
public latest UI visibility is pending because the sources did not land on the current latest digest date
no public poll UI was added
no audit UI was added
no public Source Health UI was added
backend JSON response shape was not changed
frontend framework was not added
these are issuer/exchange RSS surfaces, not central-bank, ECB, macro, or policy feeds
```
