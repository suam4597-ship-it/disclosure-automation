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
INDIA_SECONDARY_ENDPOINT_SCAN_RECORDED
BSE_SOURCE_REGISTRATION_BLOCKED_PENDING_BACKEND_COMPATIBLE_ACCESS_PATH
SEBI_REVIEWED_AS_SEPARATE_REGULATOR_POLICY_TRACK
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
HKEX_LISTED_COMPANY_ENDPOINT_SCAN_RECORDED
HKEX_LOCAL_ELIXIR_RUNTIME_PROBE_PASS
HKEX_LATEST_LISTED_COMPANY_ASSET_SCAN_RECORDED
HKEX_LATEST_LISTED_COMPANY_JSON_ASSET_CONFIRMED
HKEX_LATEST_LISTED_COMPANY_PARSER_CONTRACT_RECORDED
HKEX_FLY_RUNTIME_HOMECAT0_JSON_FETCH_PASS
HKEX_INACTIVE_SOURCE_CANDIDATE_ADDED
HKEX_SOURCE_ACTIVE_FALSE
HKEX_MANUAL_STAGING_LIVE_POLL_PASS
HKEX_DIGEST_VISIBLE_LIVE
HKEX_SOURCE_HEALTH_HEALTHY
HKEX_CADENCE_NOT_APPROVED
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
India secondary endpoints: BSE corporate-announcement surface is relevant but backend-compatible fetch is not proven; SEBI media/notification surface is a separate regulator-policy track, not a listed-company disclosure source
SGX: official browser JSON path confirmed, blocked by policy/runtime review
Bursa Malaysia: official browser JSON path confirmed, blocked by Cloudflare/runtime fetch
SET Thailand: bounded inactive source candidate added and repeated manual staging smoke passed; still inactive and production scheduling remains disabled
Vietnam HNX: official issuer-disclosure RSS returned 200 application/rss+xml; bounded inactive rss_v1 source candidate added with fixture fallback disabled; repeated manual Fly staging smoke passed with digest visibility
Vietnam HSX: official listed-company RSS returned 200 application/rss+xml; bounded inactive rss_v1 source candidate added with fixture fallback disabled; repeated manual Fly staging smoke passed with digest visibility
Taiwan MOPS: official daily material-information JSON endpoint returned 200 application/json; bounded inactive date-aware parser/source candidate added with fixture fallback disabled; repeated manual Fly staging smoke passed with digest visibility
HKEXnews: official listed-company title-search HTML surface returned bounded issuer rows, and official Latest Listed Company Information JSON assets were confirmed
HKEX local/Fly runtime probes and inactive candidate: bounded title-search URL returned 200 text/html through local Erlang :httpc with total_records=877; homecat0_e.json returned 200 application/json through local Erlang :httpc and Fly staging release eval; bounded homecat0_e.json parser/source contract recorded; inactive/manual staging-only source candidate added; manual Fly staging live poll passed with digest visibility while active=false
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
2. Revisit BSE only after a backend-compatible official endpoint or approved data-access path is proven
3. Keep SET inactive; if cadence is considered later, design staging-only schedule first
4. Keep IDX blocked unless a clean backend runtime or approved data-access path is documented
5. Continue APAC official-source scanning within official exchange/OAM surfaces
6. Revisit HKEX through an additional manual observation window and staging-only cadence design before any schedule change
7. Revisit Taiwan MOPS only through another explicit staging-only cadence design or manual observation
8. Revisit ASX only after written authority or approved ASX Information Services path exists
9. Revisit SGX only after policy/permission and runtime compatibility are explicitly accepted
10. Revisit Bursa only if a non-bypass backend runtime fetch path is accepted
11. Revisit PSE only after approved PSE data-product or written permission path exists
12. Keep KR last until its dedicated backend/source authority path exists
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

India secondary sources remain behind NSE because:

```text
BSE corporate announcements are relevant, but local page/API probes returned 403 and no Fly/backend-compatible fetch contract is proven
SEBI media and notifications are official, but they are regulator media/policy records rather than listed-company issuer announcements
NSE already has a working official RSS source with staging schedule evidence
```

HKEX remains blocked from cadence or production scheduling because:

```text
official HKEXnews listed-company HTML rows were confirmed
local Erlang :httpc returned 200 HTML for the bounded title-search URL
official HKEXnews LLCI JSON assets were confirmed
local Erlang :httpc returned 200 application/json for homecat0_e.json
homecat0_e.json parser/source contract is recorded in globalpulse_hkex_latest_listed_company_parser_contract.md
Fly runtime compatibility is recorded in globalpulse_hkex_fly_runtime_probe_results.md
inactive source candidate is recorded in globalpulse_hkex_inactive_source_candidate_notes.md
manual staging live poll is recorded in globalpulse_hkex_manual_staging_smoke_results.md
source remains active=false and candidate_status=manual_staging_only
no staging-only cadence proposal has been approved yet
attachment/detail/PDF fetch must remain excluded from the first candidate
```

## Guardrails

```text
Do not enable production APAC scheduled polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change backend digest JSON response shape.
Do not fetch ASX, IDX, SET, SGX, Bursa, HKEX, or NZX document/PDF attachments in initial candidates.
Do not treat browser-only success as backend live-source readiness.
Do not treat fixture fallback as live success.
Do not use third-party aggregators by default.
Do not start KR live polling until the dedicated KR backend/source path exists.
Do not start JP live polling until issue #339 is resolved.
```

## Next PR Candidates

```text
1. Keep observing India NSE until the 7-day staging schedule window is complete
2. Revisit BSE only after a backend-compatible official endpoint or approved data-access path is proven
3. Keep SET inactive; if cadence is considered later, design staging-only schedule first
4. Keep IDX blocked unless a clean backend runtime or approved data-access path is documented
5. Continue APAC official-source scanning within official exchange/OAM surfaces
6. Revisit HKEX through an additional manual observation window and staging-only cadence design before any schedule change
7. Revisit Taiwan MOPS only through another explicit staging-only cadence design or manual observation
8. Revisit ASX only after written authority or approved ASX Information Services path exists
9. Revisit PSE only after approved PSE data-product or written permission path exists
```

For cross-machine continuation, use `globalpulse_remote_handoff_guide.md` as the current remote handoff entrypoint before starting new implementation work.
