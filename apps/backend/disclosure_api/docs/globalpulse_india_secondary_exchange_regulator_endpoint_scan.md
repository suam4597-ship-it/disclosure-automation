# GlobalPulse India Secondary Exchange And Regulator Endpoint Scan

Date: 2026-05-11 KST

This document records a bounded follow-up scan for India secondary official sources after the NSE online announcements source passed staging-live verification and its first automated staging run.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework dependencies, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or production scheduled polling.

## Conclusion

```text
INDIA_SECONDARY_ENDPOINT_SCAN_RECORDED
INDIA_NSE_REMAINS_PRIMARY_ACCEPTED_LIVE_CANDIDATE
BSE_CORPORATE_ANNOUNCEMENTS_SURFACE_RELEVANT
BSE_BACKEND_COMPATIBLE_FETCH_NOT_PROVEN
BSE_SOURCE_REGISTRATION_BLOCKED
SEBI_MEDIA_AND_NOTIFICATIONS_SURFACE_REVIEWED
SEBI_IS_REGULATOR_POLICY_MEDIA_TRACK_NOT_LISTED_COMPANY_DISCLOSURE_TRACK
NO_SECONDARY_INDIA_SOURCE_REGISTERED
NO_INDIA_PRODUCTION_SCHEDULED_POLLING_ENABLED
KR_LIVE_SOURCE_TRACK_DEFERRED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Scope

The scan considered only official India-owned surfaces already adjacent to the GlobalPulse India disclosure track:

```text
BSE corporate announcements
SEBI media and notification listings
SEBI RSS landing page
```

The purpose was not to replace NSE. The purpose was to decide whether a second India source is ready for a bounded inactive parser/source PR.

## BSE Corporate Announcements

Candidate surface:

```text
owner: BSE Limited
surface: Latest Corporate Announcements
URL: https://www.bseindia.com/corporates/ann.html
candidate API shape observed from public web references: BseIndiaAPI AnnGetData JSON
candidate category: listed-company announcements
```

Local fetch probes:

```text
GET https://www.bseindia.com/corporates/ann.html
client: PowerShell Invoke-WebRequest with browser User-Agent
result: 403 Access Denied from Akamai edge

HEAD https://www.bseindia.com/corporates/ann.html
client: curl.exe with browser User-Agent
result: 403 Forbidden

GET https://api.bseindia.com/BseIndiaAPI/api/AnnGetData/w?strCat=-1&strPrevDate=20260511&strScrip=&strSearch=P&strToDate=20260511&strType=C
client: PowerShell Invoke-WebRequest with browser User-Agent, Accept application/json, Referer, and Origin
result: 403 Forbidden
```

Decision:

```text
BSE is relevant for a future listed-company disclosure source.
BSE is not accepted for source registration from this scan.
The exact backend-compatible fetch contract is not proven.
The current local probe shape would likely fail a Fly/Elixir backend poll or depend on edge/session behavior that has not been accepted.
```

Required before any BSE source PR:

```text
stable official endpoint URL and query contract
backend-compatible 2xx fetch from Fly staging or an approved data-access path
bounded date/page/item limits
terms/access-policy review for backend polling and redistribution
fixture-fallback disabled
source active=false
manual staging-only status
no attachment/detail fetch in the first candidate
```

## SEBI Media And Notifications

Candidate surface:

```text
owner: Securities and Exchange Board of India
surface: Media & Notifications / Press Releases
URL: https://www.sebi.gov.in/sebiweb/home/HomeAction.do?doListing=yes&sid=6&smid=0&ssid=23
observed shape: HTML listing
records visible: 1 to 25 of 5841 records
example categories: Press Releases, Public Notices, News Clarifications, Speeches, Notifications
```

Local fetch probes:

```text
GET https://www.sebi.gov.in/rss.html
client: PowerShell Invoke-WebRequest with browser User-Agent
result: connection closed / send error

GET https://www.sebi.gov.in/rss.html
client: curl.exe with browser User-Agent
result: connection reset
```

Decision:

```text
SEBI is official and relevant to India capital markets.
The reviewed SEBI surface is a regulator media/policy listing, not a listed-company issuer-announcement source.
Do not add SEBI to the GlobalPulse listed-company disclosure track from this scan.
If SEBI is added later, keep it as a separate regulator/policy track with distinct coverage tags and product copy.
```

## Accepted India State After This Scan

```text
primary accepted India live source: india_nse_announcements
NSE status: staging-live verified, conservative staging schedule configured, first automated scheduled staging run passed
NSE observation window: 7-day staging observation still pending
BSE status: relevant official candidate, blocked pending backend-compatible official access path
SEBI status: separate regulator/policy track, not accepted as listed-company disclosure source
production India scheduled polling: not enabled
```

## Guardrails

```text
no new India source registration
no source active=true
no production scheduled polling
no workflow schedule changes
no public poll UI
no audit UI
no public Source Health UI
no backend digest JSON response-shape change
no frontend framework dependency
no BSE attachment/detail fetch
no SEBI regulator-policy feed blended into listed-company disclosure coverage
fixture fallback cannot be claimed as live success
KR remains deferred until the dedicated backend/source path exists
JP remains blocked until issue #339 is resolved
```

## Next Allowed Steps

```text
1. Keep observing India NSE scheduled staging runs until the 7-day window matures.
2. Revisit BSE only after a backend-compatible official endpoint or approved data-access path is proven.
3. Keep SEBI out of the listed-company disclosure track unless a separate regulator/policy product lane is approved.
4. Continue non-KR APAC official-source scans within official exchange/OAM surfaces.
```
