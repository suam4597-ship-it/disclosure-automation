# GlobalPulse Austria Wiener Boerse Staging Live Poll Smoke Results

This records the first staging live poll smoke for the official Vienna Stock Exchange announcements candidate.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity-provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or scheduled polling.

## Source

```text
source_key: eu_austria_wiener_borse_announcements
display_name: Austria Wiener Boerse Announcements
authority: Vienna Stock Exchange / Wiener Boerse
source class: official exchange announcement surface
supporting URL: https://www.wienerborse.at/en/legal/announcements/
parser: wiener_borse_announcements_html_v1
candidate_status: manual_staging_only
active: false
scheduled polling: disabled
```

## Deployment

```text
phase0-foundation merge commit: c1f532ed6ac85a7c5d6edab7d2fa5ac2797426dd
PR: #400 Add Austria Wiener Boerse announcements candidate
CI:
- Phase 0 validate: success
- Phase 0 report: success
- Phase 1 backend verify: success
- Phase 1 runtime smoke: success
- Phase 1 backend report: success
- Phase 1 backend diagnose: success
- Phase 1 backend trace: success
Fly app: globalpulse-backend-staging
Fly deploy: success
release_command: success
backend health: GET /api/health -> 200
```

## Live Poll

```text
request:
POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/eu_austria_wiener_borse_announcements/poll?edition=breaking

response status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 313897
records_seen: 22
records_inserted: 22
metadata.fallback_to_fixture: false
```

Representative canonical item keys:

```text
breaking-2026-05-08-50353
breaking-2026-05-08-50354
breaking-2026-05-08-50356
```

Representative parsed records:

```text
Erste Group Bank AG - New Listing
SANTANDER INTERNATIONAL PRODUCTS PLC - Inclusion
Harp Issuer plc - Inclusion
```

## Source Health

```text
GET /api/admin/source-health/eu_austria_wiener_borse_announcements -> 200
health_status: healthy
last_success_at: 2026-05-08T23:55:21.839290Z
last_seen_published_at: 2026-05-08T00:00:00.000000Z
active: false
parser_key: wiener_borse_announcements_html_v1
```

## Digest Visibility

```text
GET /api/feed/digest/2026-05-08/breaking -> 200
metadata.fallback_to_fixture: false
```

The poll inserted Austria canonical items for digest date `2026-05-08`. The public GlobalPulse Pages shell currently renders the backend `latest` digest. At smoke time, `latest` pointed to `2026-05-09`, so the Austria items were not visible on the public latest UI without adding a date selector or changing the public response contract.

This is not a parser or source failure. It is a visibility limitation of the current latest-only public UI.

## Conclusions

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
AUSTRIA_WIENER_BORSE_OFFICIAL_SURFACE_PASS
AUSTRIA_WIENER_BORSE_STAGING_LIVE_POLL_PASS
AUSTRIA_WIENER_BORSE_FIXTURE_FALLBACK_FALSE
AUSTRIA_WIENER_BORSE_SOURCE_HEALTH_HEALTHY
AUSTRIA_WIENER_BORSE_PUBLIC_LATEST_UI_VISIBILITY_PENDING
EU_SCHEDULED_LIVE_POLLING_STILL_DISABLED
```

## Guardrails

```text
scheduled live Austria polling is still disabled
EU batch promotion is still blocked pending target list and rollback documentation
public latest UI was not changed to force historical-date display
backend JSON response shape was not changed
frontend framework was not added
poll UI was not added
audit UI was not added
public Source Health UI was not added
OeKB issuerinfo is not registered because no stable unauthenticated machine endpoint was confirmed
```
