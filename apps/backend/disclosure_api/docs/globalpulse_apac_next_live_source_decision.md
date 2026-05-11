# GlobalPulse APAC Next Live Source Decision

Date: 2026-05-11 KST

This document records the next-source decision after the first APAC/ASEAN/ANZ live endpoint expansion pass.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or scheduled polling.

## Decision

```text
APAC_NEXT_LIVE_SOURCE_DECISION_RECORDED
ASX_IS_STRONGEST_NEXT_TECHNICAL_ADAPTER_CANDIDATE
ASX_ACCESS_POLICY_DECISION_RECORDED
ASX_ADAPTER_BLOCKED_UNTIL_WRITTEN_AUTHORITY_OR_APPROVED_INFORMATION_SERVICE_PATH
SET_IS_FIRST_ASEAN_RUNTIME_PROBE_CANDIDATE
SET_FLY_ELIXIR_RUNTIME_PROBE_PASS
SET_BOUNDED_INACTIVE_ADAPTER_SOURCE_CANDIDATE_ADDED
SET_MANUAL_STAGING_SMOKE_PASS
SET_REPEATED_MANUAL_STAGING_POLL_PASS
INDIA_NSE_FIRST_AUTOMATED_STAGING_SCHEDULE_RUN_PASS
INDIA_NSE_7_DAY_STAGING_OBSERVATION_WINDOW_PENDING
VIETNAM_HNX_ISSUER_DISCLOSURE_RSS_CONFIRMED
VIETNAM_HNX_ISSUER_DISCLOSURE_SOURCE_REGISTERED_INACTIVE
VIETNAM_HNX_MANUAL_STAGING_SMOKE_PASS
VIETNAM_HNX_REPEATED_MANUAL_STAGING_SMOKE_PASS
VIETNAM_HNX_DIGEST_VISIBLE_LIVE
VIETNAM_HSX_LISTED_COMPANY_NEWS_RSS_CONFIRMED
VIETNAM_HSX_LISTED_COMPANY_NEWS_SOURCE_REGISTERED_INACTIVE
VIETNAM_HSX_MANUAL_STAGING_SMOKE_PASS
VIETNAM_HSX_REPEATED_MANUAL_STAGING_SMOKE_PASS
VIETNAM_HSX_DIGEST_VISIBLE_LIVE
TAIWAN_MOPS_DAILY_MATERIAL_INFO_JSON_CONFIRMED
TAIWAN_MOPS_DAILY_MATERIAL_INFO_SOURCE_REGISTERED_INACTIVE
TAIWAN_MOPS_MANUAL_STAGING_LIVE_POLL_PASS
TAIWAN_MOPS_REPEATED_MANUAL_STAGING_LIVE_POLL_PASS
TAIWAN_MOPS_DAILY_MATERIAL_INFO_DIGEST_VISIBLE_LIVE
IDX_IS_SECOND_ASEAN_RUNTIME_PROBE_CANDIDATE
IDX_FLY_ELIXIR_RUNTIME_PROBE_RECORDED
IDX_SOURCE_REGISTRATION_STILL_BLOCKED_BY_CHALLENGE_COOKIE_DEPENDENCY
IDX_CHALLENGE_COOKIE_ACCESS_DECISION_RECORDED
PSE_EDGE_ACCESS_PATH_REVIEW_RECORDED
PSE_EDGE_SOURCE_REGISTRATION_BLOCKED_PENDING_APPROVED_DATA_ACCESS_PATH
KR_LIVE_SOURCE_TRACK_DEFERRED_UNTIL_DEDICATED_BACKEND_EXISTS
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
PRODUCTION_APAC_SCHEDULED_LIVE_POLLING_NOT_ENABLED
```

## Inputs Reviewed

```text
India NSE official RSS: staging-live verified, conservative staging schedule configured, and first automated scheduled staging run passed on GitHub Actions run 25650796284
SGX: official browser JSON path confirmed, blocked by policy/runtime review
Bursa Malaysia: official browser JSON path confirmed, blocked by Cloudflare/runtime fetch
SET Thailand: bounded inactive source candidate added and repeated manual staging smoke passed; still inactive and production scheduling remains disabled
Vietnam HNX: official issuer-disclosure RSS returned 200 application/rss+xml; bounded inactive rss_v1 source candidate added with fixture fallback disabled; repeated manual Fly staging smoke passed with digest visibility
Vietnam HSX: official listed-company RSS returned 200 application/rss+xml; bounded inactive rss_v1 source candidate added with fixture fallback disabled; repeated manual Fly staging smoke passed with digest visibility
Taiwan MOPS: official daily material-information JSON endpoint returned 200 application/json; bounded inactive date-aware parser/source candidate added with fixture fallback disabled; repeated manual Fly staging smoke passed with digest visibility
IDX Indonesia: official JSON path confirmed; Fly/Elixir direct API/page bootstrap returned Cloudflare 403, cookie-mediated API returned 200 JSON; access decision blocks source registration until a clean backend runtime or approved data-access path exists
Philippines PSE EDGE: official disclosure surface confirmed; official CAF/ITCH data-access products found; public-site access is not enough for backend polling without approved data-access path
ASX: official MarkitDigital JSON path confirmed, direct Node/PowerShell fetch passed, blocked by access-policy decision until written authority or approved ASX Information Services path exists
NZX: official contingency HTML surface confirmed, no machine-readable endpoint accepted
KR: explicitly deferred by product direction because the dedicated backend is not ready
JP: remains blocked by source-authority issue #339
```

## Recommended Order

```text
1. Keep observing India NSE until the 7-day staging schedule window is complete
2. Keep SET inactive; if cadence is considered later, design staging-only schedule first
3. Keep IDX blocked unless a clean backend runtime or approved data-access path is documented
4. Continue APAC official-source scanning within official exchange/OAM surfaces
5. Revisit Taiwan MOPS only through another explicit staging-only cadence design or manual observation
6. Revisit ASX only after written authority or approved ASX Information Services path exists
7. Revisit SGX only after policy/permission and runtime compatibility are explicitly accepted
8. Revisit Bursa only if a non-bypass backend runtime fetch path is accepted
9. Revisit PSE only after approved PSE data-product or written permission path exists
10. Keep KR last until its dedicated backend/source authority path exists
```

## Rationale

ASX is the strongest next technical candidate because:

```text
official ASX announcement surface confirmed
official ASX/MarkitDigital JSON endpoint observed
bounded page-0 query returned 200 application/json from PowerShell
bounded page-0 query returned 200 application/json from Node fetch
response shape is typed JSON and does not require parsing HTML table fragments
```

ASX is still blocked from source registration because:

```text
ASX market-announcement access is subject to ASX terms of use
market-data copyright restrictions are disclosed on the ASX announcement surface
GlobalPulse recorded an access-policy decision that public-site access is not enough for backend polling
ASX terms describe Market Announcements as private/personal-use only unless ASX gives express written authority
ASX Company News/Information Services is the appropriate authority path for reuse or redistribution
no bounded ASX parser/source candidate exists yet
no Fly staging live-poll smoke exists yet
```

SET is the first ASEAN implementation fallback because:

```text
official SET company-news JSON path was observed
the response shape is typed JSON
local PowerShell could fetch JSON after normal page bootstrap and documented SET browser headers
Fly staging could fetch JSON through the application Erlang :httpc wrapper with bounded SET headers
```

SET remains bounded because:

```text
the API is not a simple standalone endpoint
some fresh direct API probes previously returned Incapsula challenge HTML
bounded parser/source candidate remains active=false
repeated manual staging smoke has passed
any cadence discussion must start as a staging-only schedule design before activation or production scheduling
```

IDX is behind SET because:

```text
official IDX JSON path was observed
bounded YYYYMMDD date-window query returned 200 JSON through Chromium network
direct Node and PowerShell probes returned Cloudflare/403
Fly/Elixir direct API and page-bootstrap probes returned Cloudflare 403 HTML
Fly/Elixir cookie-mediated API retry returned 200 JSON, which is diagnostic but not source-registration approval
IDX challenge-cookie access decision is recorded
unbounded query shapes returned Varnish 503 HTML
```

## Guardrails

```text
Do not enable production APAC scheduled polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change backend digest JSON response shape.
Do not fetch ASX, IDX, SET, SGX, Bursa, or NZX document/PDF attachments in initial candidates.
Do not treat browser-only success as backend live-source readiness.
Do not treat fixture fallback as live success.
Do not use third-party aggregators by default.
Do not start KR live polling until the dedicated KR backend/source path exists.
Do not start JP live polling until issue #339 is resolved.
```

## Next PR Candidates

```text
1. Keep observing India NSE until the 7-day staging schedule window is complete
2. Keep SET inactive; if cadence is considered later, design staging-only schedule first
3. Keep IDX blocked unless a clean backend runtime or approved data-access path is documented
4. Continue APAC official-source scanning within official exchange/OAM surfaces
5. Revisit Taiwan MOPS only through another explicit staging-only cadence design or manual observation
6. Revisit ASX only after written authority or approved ASX Information Services path exists
7. Revisit PSE only after approved PSE data-product or written permission path exists
```
