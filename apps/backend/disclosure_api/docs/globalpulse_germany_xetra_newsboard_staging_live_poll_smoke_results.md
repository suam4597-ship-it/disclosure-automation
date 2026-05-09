# GlobalPulse Germany Xetra Frankfurt Newsboard Staging Live Poll Smoke Results

Date: 2026-05-09

## Scope

This record covers the manual staging live smoke for the Germany Xetra Frankfurt Newsboard source added by PR #402.

```text
source_key: de_xetra_frankfurt_newsboard
display_name: Germany Xetra Frankfurt Newsboard
source_type: html
parser_key: xetra_newsboard_html_v1
candidate_status: manual_staging_only
active: false
```

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
GERMANY_XETRA_NEWSBOARD_OFFICIAL_SURFACE_PASS
GERMANY_XETRA_NEWSBOARD_STAGING_LIVE_POLL_PASS
GERMANY_XETRA_NEWSBOARD_FIXTURE_FALLBACK_FALSE
GERMANY_XETRA_NEWSBOARD_SOURCE_HEALTH_HEALTHY
GERMANY_XETRA_NEWSBOARD_DATE_DIGEST_RENDERABLE_PASS
GERMANY_XETRA_NEWSBOARD_PUBLIC_LATEST_UI_VISIBILITY_PENDING
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

Manual source poll:

```text
POST /api/admin/sources/de_xetra_frankfurt_newsboard/poll?edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 234647
records_seen: 25
records_inserted: 25
metadata.fallback_to_fixture: false
```

Source health:

```text
GET /api/admin/source-health/de_xetra_frankfurt_newsboard -> 200
health_status: healthy
last_success_at: 2026-05-09T00:10:24.188342Z
last_seen_published_at: 2026-05-08T18:34:37.000000Z
active: false
candidate_status: manual_staging_only
```

Date-specific digest:

```text
GET /api/feed/digest/2026-05-08/breaking -> 200
digest_date: 2026-05-08
item_count: 12
metadata.fallback_to_fixture: false
rendered source: Germany Xetra Frankfurt Newsboard
rendered headline: XFRA: Deletion of Instruments from Boerse Frankfurt - 08.05.2026
rendered region: eu_central
```

Latest digest note:

```text
GET /api/feed/digest/latest?edition=breaking -> 200
latest digest_date at smoke time: 2026-05-09
latest digest rendered India NSE Announcements items
Xetra items were published on 2026-05-08 and therefore did not appear in the public latest-only shell at smoke time
```

## Guardrails

```text
scheduled live Germany polling remains disabled
source remains active=false
source remains manual_staging_only
public latest UI visibility is pending because the source did not land on the current latest digest date
no public poll UI was added
no audit UI was added
no public Source Health UI was added
backend JSON response shape was not changed
frontend framework was not added
operational service notices are filtered out by parser contract
this is not a central-bank, macro-policy, or ECB feed
```
