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

## Candidate Sources

### Candidate A: India NSE RSS announcements

```text
source authority: official
owner: National Stock Exchange of India
candidate category: India listed-company announcements
machine-readable shape: RSS 2.0 XML
candidate feed: https://nsearchives.nseindia.com/content/RSS/Online_announcements.xml
status: PREFERRED_FIRST_APAC_CANDIDATE_PENDING_STAGING_VERIFICATION
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
Do not schedule the NSE candidate yet.
Add it only as a disabled/manual or staging-only candidate after a focused parser smoke confirms current rss_v1 compatibility.
Record live success only after Fly staging proves fetch.mode=live and metadata.fallback_to_fixture=false.
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

Acceptance caveat:

```text
Do not add a third-party aggregator unless explicitly accepted.
Do not use an HTML exchange homepage or search page as rss_v1 input.
Verify exact endpoint, terms/rate limits, parser compatibility, and rollback before source registration.
```

### Candidate D: ANZ exchange and policy feeds

```text
source authority: official exchange, regulator, or central bank required
candidate category: Australia/NZ announcements, market news, or policy news
candidate owners to verify: ASX, NZX, ASIC, RBA, or another official owner
machine-readable shape: pending exact endpoint verification
status: ANZ_LIVE_SOURCE_PENDING_EXACT_ENDPOINT
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
If the goal is market-moving policy coverage, keep RBA/ASIC feeds labeled separately from company disclosures.
Do not claim ANZ live success from an HTML announcement page.
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
1. Add focused NSE RSS parser characterization against a captured bounded sample.
2. Add a disabled/manual India NSE candidate source after rss_v1 compatibility is confirmed.
3. Run Fly staging live poll smoke for the NSE candidate with use_live_fetch=true.
4. Record India NSE live polling smoke if fetch.mode=live and metadata.fallback_to_fixture=false.
5. Start ASEAN exact endpoint verification separately.
6. Start ANZ exact endpoint verification separately.
```

## Current Conclusion

```text
APAC_FIXTURE_UI_TRACK_CLOSED
APAC_LIVE_SOURCE_TRACK_STARTED
INDIA_NSE_RSS_SELECTED_AS_FIRST_APAC_CANDIDATE_PENDING_STAGING_VERIFICATION
ASEAN_LIVE_SOURCE_PENDING_EXACT_ENDPOINT
ANZ_LIVE_SOURCE_PENDING_EXACT_ENDPOINT
APAC_SCHEDULED_LIVE_POLLING_BLOCKED_UNTIL_STAGING_SMOKE_PASS
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
