# GlobalPulse APAC Live Source Verification Contract

This document defines the safe verification path for adding APAC live sources after APAC fixture-backed coverage was confirmed in PR #348 and recorded in PR #349.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, integrations, or scheduled live polling.

## Baseline

```text
fixture baseline PR: #348 Add GlobalPulse APAC regional fixtures
fixture smoke record: #349 Record APAC regional public UI smoke
public Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
staging backend URL: https://globalpulse-backend-staging.fly.dev
current live status: NOT_READY_FOR_SCHEDULED_LIVE_POLLING
```

Current APAC live-source status:

```text
India NSE official RSS: staging-live verified, bounded, duplicate-handling hardened, conservative staging schedule configured
India NSE first automated scheduled run: passed on GitHub Actions run 25650796284; 7-day staging observation window pending
ASEAN official endpoint: scan started, SGX browser JSON access path confirmed but blocked by policy/runtime review; Bursa browser JSON access path confirmed but blocked by Cloudflare/runtime fetch; SET official JSON access path and repeated Fly staging smoke passed while inactive; HNX Vietnam official RSS inactive candidate added and repeated manual staging smoke passed; HSX Vietnam official listed-company RSS inactive candidate added and repeated manual staging smoke passed; Taiwan MOPS official JSON inactive candidate added and repeated manual staging smoke passed; IDX official JSON access path confirmed but blocked by challenge-cookie dependency
ANZ official endpoint: ASX official JSON access path confirmed, but access-policy decision blocks source registration until written authority or approved ASX Information Services path exists
Taiwan official endpoint: MOPS daily material-information JSON endpoint confirmed; bounded inactive date-aware POST adapter/parser source candidate added; repeated manual staging smoke passed while inactive
JP live source: blocked by issue #339 source-authority decision
```

Current APAC fixture-backed source buckets:

```text
apac_policy_news -> apac -> Asia-Pacific
asean_market_news -> asean -> ASEAN
india_market_disclosures -> india -> India
anz_market_news -> anz -> Australia/NZ
```

The fixture-backed APAC UI smoke confirmed:

```text
ASEAN_MARKET_NEWS_UI_PASS
INDIA_MARKET_DISCLOSURE_UI_PASS
ANZ_MARKET_NEWS_UI_PASS
APAC_GENERIC_POLICY_SECTION_PRESENT_EXPECTED
GLOBALPULSE_APAC_REGIONAL_FIXTURE_READY
```

Fixture-backed smoke does not establish live-source readiness.

## Live Source Split

APAC live source verification must stay split into small tracks:

```text
1. India official live candidate verification
2. ASEAN official live candidate verification
3. ANZ official live candidate verification
```

Do not enable broad APAC scheduled live polling before each track has an accepted source, staging live-poll smoke, and public UI smoke.

Current next-source decision:

```text
decision record: globalpulse_apac_next_live_source_decision.md
ASX access-policy record: globalpulse_asx_markitdigital_access_policy_decision.md
next technical candidate: bounded inactive SET Thailand JSON parser/source candidate
ASX status: technical JSON path confirmed, policy-blocked
ASEAN fallback order: SET parser/source candidate, then IDX runtime probe
KR live-source track: deferred until dedicated backend/source authority path exists
JP live polling: blocked until issue #339 is resolved
```

## Candidate Sources

### Candidate A: India NSE RSS announcements

```text
source authority: official
owner: National Stock Exchange of India
candidate category: India listed-company announcements
machine-readable shape: RSS 2.0 XML
candidate feed: https://nsearchives.nseindia.com/content/RSS/Online_announcements.xml
status: STAGING_LIVE_VERIFIED_CONSERVATIVE_STAGING_SCHEDULE_CONFIGURED
```

Observed quick smoke on 2026-05-08:

```text
GET https://www.nseindia.com/static/rss-feed
result: 200 HTML index page exposing official NSE RSS XML feed links

GET https://nsearchives.nseindia.com/content/RSS/Online_announcements.xml
result: 200
content_type: application/xml
root: rss
rss_version: 2.0
channel_title: NSE News - Latest Announcements
items_observed: 1350
first_item_title: Grindwell Norton Limited
first_item_link_host: nsearchives.nseindia.com
```

Rationale:

```text
NSE provides an official RSS feed index, and the online announcements XML endpoint returns direct RSS 2.0 XML from the NSE archive domain.
This is the strongest first APAC live candidate because it is official, machine-readable, high-signal, and region-specific.
```

Acceptance caveat:

```text
Do not replace india_market_disclosures with the NSE feed yet.
Do not promote NSE to production scheduled polling yet.
The source is available only as a disabled/manual staging candidate in the registry.
The conservative staging workflow schedule is configured on both phase0-foundation and main.
Record first scheduled-run success only after a GitHub Actions cron run proves source=india_nse_announcements, fetch.mode=live, metadata.fallback_to_fixture=false, and the digest remains diverse.
```

Safety hardening completed after initial candidate selection:

```text
parser output bound: completed
source-level max_items_per_poll=25: completed
Fly staging live poll smoke: completed
digest diversity guard: completed
duplicate reference bounding: completed
staging cadence policy: completed
phase0 workflow schedule configuration: completed
default-branch schedule activation: completed
first automated scheduled run: completed on run 25650796284
7-day staging observation window: pending
```

### Candidate B: India SEBI/BSE/NSE secondary feeds

```text
source authority: official if exact endpoint is SEBI, BSE, or NSE owned
candidate category: India regulator and exchange announcements
machine-readable shape: pending exact endpoint verification
status: SECONDARY_INDIA_CANDIDATES_PENDING_EXACT_FEED_SELECTION
```

Observed quick smoke on 2026-05-08:

```text
GET https://www.sebi.gov.in/rss.html
result: executor timeout
decision: do not accept or reject from this timeout alone
```

Acceptance caveat:

```text
Select one exact RSS, Atom, XML, JSON, or known API endpoint before adding a source registry entry.
Do not use HTML search/listing pages as rss_v1 sources.
Do not treat a timeout in the executor as a product decision; retry with browser or alternate network before rejecting.
```

### Candidate C: ASEAN exchange announcements

```text
source authority: official exchange or regulator required
candidate category: ASEAN market news and listed-company announcements
candidate owners to verify: SGX, Bursa Malaysia, SET, IDX, or another official exchange/regulator
machine-readable shape: pending exact endpoint verification
status: ASEAN_LIVE_SOURCE_PENDING_EXACT_ENDPOINT
```

Observed ASEAN exact-endpoint scan:

```text
scan record: globalpulse_asean_live_endpoint_verification_scan.md
SGX company announcements: official browser JSON access path confirmed; source registration blocked by SGX policy/permission review and backend runtime fetch compatibility
Bursa Malaysia company announcements: official browser JSON access path confirmed; source registration blocked by Cloudflare/runtime fetch compatibility
SET Thailand company news: official JSON access path confirmed; source registration blocked pending bounded adapter and Fly/Elixir runtime probe
SET Thailand Fly/Elixir runtime probe: passed through DisclosureAutomation.Http.fetch/2 from globalpulse-backend-staging
SET Thailand manual staging smoke: passed twice with fetch.mode=live and metadata.fallback_to_fixture=false; still inactive and unscheduled
Vietnam HNX issuer disclosures: official RSS path confirmed; inactive rss_v1 source candidate added with fixture fallback disabled; repeated manual staging smoke passed with digest visibility
Vietnam HSX listed-company news: official RSS path confirmed; inactive rss_v1 source candidate added with fixture fallback disabled; repeated manual staging smoke passed with digest visibility
IDX announcements: official JSON access path confirmed; Fly/Elixir runtime probe recorded direct API/page bootstrap Cloudflare 403 and cookie-mediated API 200 JSON; source registration blocked by challenge-cookie dependency, bounded adapter, and query-shape policy
decision: no active or scheduled ASEAN source yet; inactive ASEAN candidates remain manual-staging-only
```

Acceptance caveat:

```text
Do not add a third-party aggregator unless explicitly accepted.
Do not use an HTML exchange homepage or search page as rss_v1 input.
Verify exact endpoint, terms/rate limits, parser compatibility, and rollback before source registration.
```

### Candidate D: ANZ listed-company disclosure feeds

```text
source authority: official exchange or issuer-announcement authority required
candidate category: Australia/NZ listed-company announcements and issuer disclosures
candidate owners to verify: ASX, NZX, or another official issuer-announcement owner
machine-readable shape: pending exact endpoint verification
status: ANZ_LIVE_ENDPOINT_SCAN_STARTED
```

Observed quick smoke on 2026-05-08:

```text
GET https://announcements.nzx.com/
result: 200 HTML announcement surface
decision: authority surface is relevant, but not accepted as rss_v1 input without a machine-readable endpoint
```

Acceptance caveat:

```text
If the goal is listed-company disclosure coverage, prefer ASX/NZX announcement endpoints.
Do not use central-bank or broad policy feeds as the first ANZ company-disclosure source.
If market-moving policy coverage is added later, keep RBA/ASIC-style feeds labeled separately from company disclosures.
Do not claim ANZ live success from an HTML announcement page.
```

Observed ANZ exact-endpoint scan:

```text
scan record: globalpulse_anz_live_endpoint_verification_scan.md
ASX recent/historical/today's announcements: official HTML surfaces found; no accepted RSS/Atom/JSON endpoint verified
ASX MarkitDigital announcements JSON: official page access path confirmed; direct Node/PowerShell fetch returned 200 JSON
ASX access-policy decision: public-site access is not enough authority for GlobalPulse backend polling; source registration blocked until written authority or approved ASX Information Services path exists
NZX public announcements: official contingency HTML surface confirmed; no RSS/Atom/JSON endpoint observed
NZX data products: official access-policy surface found; not accepted as unauthenticated live source
decision: no ANZ source registration yet
```

## APAC v1 Recommendation

```text
APAC_V1_CANDIDATE: NSE Online Announcements RSS
candidate URL: https://nsearchives.nseindia.com/content/RSS/Online_announcements.xml
source_key proposal: india_nse_announcements
parser_key: rss_v1
coverage_tags: apac, india, disclosure, exchange, listed_companies
initial mode: manual/staging verification only
scheduled polling: disabled until staging smoke passes
```

## Acceptance Gates

Before any APAC live source can be scheduled or claimed as live-data ready, it must pass:

```text
authority: official or explicitly accepted third-party
machine_readable: RSS, Atom, XML, JSON, or known API shape
http: stable 2xx response
parser: rss_v1 compatible or bounded parser PR exists
fallback: metadata.fallback_to_fixture=false
source: fetch.mode=live
UI: at least one APAC item renders in GlobalPulse Pages
rollback: disabling APAC source does not break SEC live polling
scope: no public poll UI, audit UI, or public Source Health UI required
response_shape: public digest JSON response shape unchanged
operations: rate limits, user-agent expectations, credentials, and terms are documented
```

## Explicit Rejections

```text
REJECT: live-polling https://example.com/globalpulse/apac-policy-news
REJECT: live-polling HTML root/search/listing pages with rss_v1
REJECT: claiming APAC live success while falling back to fixture data
REJECT: adding third-party APAC aggregators without explicit policy acceptance
REJECT: enabling scheduled live APAC polling before staging smoke
REJECT: changing public digest response shape just to support APAC
REJECT: exposing raw provider/auth/session/request diagnostics in public responses
REJECT: enabling JP live polling before issue #339 source-authority decision is resolved
```

## Next Allowed PRs

```text
1. Record India NSE 7-day scheduled staging observation summary after enough successful cron runs accumulate.
2. Record SGX policy/permission decision or runtime compatibility probe if SGX access is allowed to continue.
3. Add a bounded SGX adapter only if policy/permission, runtime fetch, and response-shape gates pass.
4. Add a bounded inactive SET adapter/source candidate.
5. Add SET manual Fly staging live poll smoke only after parser/source candidate deployment.
6. Repeat SET Thailand manual staging smoke in another observation window.
7. Continue APAC official-source scanning within official exchange/OAM surfaces.
8. Keep observing India NSE scheduled staging runs until the 7-day window matures.
9. Keep IDX blocked unless a clean backend runtime or approved data-access path is documented.
10. Revisit ASX only after written authority or approved ASX Information Services path exists.
11. Add a bounded inactive ASX adapter/source candidate only if authority, response shape, runtime fetch, and staging-smoke gates pass.
12. Keep JP blocked until issue #339 source authority is resolved.
13. Keep KR deferred until the dedicated KR backend/source authority path exists.
```

## Current Conclusion

```text
APAC_FIXTURE_UI_TRACK_CLOSED
APAC_LIVE_SOURCE_TRACK_STARTED
INDIA_NSE_STAGING_LIVE_CANDIDATE_VERIFIED
INDIA_NSE_CONSERVATIVE_STAGING_SCHEDULE_CONFIGURED
INDIA_NSE_FIRST_AUTOMATED_STAGING_SCHEDULE_RUN_PASS
INDIA_NSE_7_DAY_STAGING_OBSERVATION_WINDOW_PENDING
ASEAN_LIVE_ENDPOINT_SCAN_STARTED
SGX_BROWSER_JSON_ACCESS_PATH_CONFIRMED
SGX_SOURCE_REGISTRATION_BLOCKED_BY_POLICY_REVIEW
BURSA_MALAYSIA_BROWSER_JSON_ACCESS_PATH_CONFIRMED
BURSA_MALAYSIA_SOURCE_REGISTRATION_BLOCKED_BY_RUNTIME_FETCH
SET_THAILAND_JSON_ACCESS_PATH_CONFIRMED
SET_THAILAND_FLY_ELIXIR_RUNTIME_PROBE_PASS
SET_THAILAND_BOUNDED_INACTIVE_SOURCE_CANDIDATE_ADDED
SET_THAILAND_MANUAL_STAGING_SMOKE_PASS
SET_THAILAND_REPEATED_MANUAL_STAGING_POLL_PASS
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
IDX_INDONESIA_JSON_ACCESS_PATH_CONFIRMED
IDX_INDONESIA_FLY_ELIXIR_RUNTIME_PROBE_RECORDED
IDX_INDONESIA_SOURCE_REGISTRATION_STILL_BLOCKED_BY_CHALLENGE_COOKIE_DEPENDENCY
IDX_CHALLENGE_COOKIE_ACCESS_DECISION_RECORDED
PSE_EDGE_ACCESS_PATH_REVIEW_RECORDED
PSE_EDGE_SOURCE_REGISTRATION_BLOCKED_PENDING_APPROVED_DATA_ACCESS_PATH
ASEAN_MACHINE_READABLE_ENDPOINTS_CONFIRMED_BUT_NOT_ACCEPTED_FOR_SOURCE_REGISTRATION
ANZ_LIVE_ENDPOINT_SCAN_STARTED
ASX_JSON_ACCESS_PATH_CONFIRMED
ASX_ACCESS_POLICY_DECISION_RECORDED
ASX_SOURCE_REGISTRATION_BLOCKED_UNTIL_WRITTEN_AUTHORITY_OR_APPROVED_INFORMATION_SERVICE_PATH
NZX_MACHINE_READABLE_ENDPOINT_NOT_ACCEPTED_YET
TAIWAN_MOPS_DAILY_MATERIAL_INFO_JSON_CONFIRMED
TAIWAN_MOPS_DAILY_MATERIAL_INFO_SOURCE_REGISTERED_INACTIVE
TAIWAN_MOPS_MANUAL_STAGING_LIVE_POLL_PASS
TAIWAN_MOPS_REPEATED_MANUAL_STAGING_LIVE_POLL_PASS
TAIWAN_MOPS_DAILY_MATERIAL_INFO_DIGEST_VISIBLE_LIVE
APAC_NEXT_LIVE_SOURCE_DECISION_RECORDED
KR_LIVE_SOURCE_TRACK_DEFERRED_UNTIL_DEDICATED_BACKEND_EXISTS
PRODUCTION_APAC_SCHEDULED_LIVE_POLLING_NOT_ENABLED
JP_REMAINING_AUTHORITY_DECISION_TRACKED_IN_ISSUE_339
```

## Stop Conditions

Stop and re-scope if APAC live source work requires:

```text
adding login UI
adding identity provider callback routes
adding poll UI
adding audit UI
adding public Source Health UI
changing public digest response shape
trusting request-param actor_permissions as production authority
returning raw provider/auth/session/request material
using fixture fallback while claiming live success
using an unofficial source without explicit policy acceptance
turning on JP scheduled live polling before source authority is decided
```
