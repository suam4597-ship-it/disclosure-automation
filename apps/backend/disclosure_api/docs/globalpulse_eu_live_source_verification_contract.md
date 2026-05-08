# GlobalPulse EU Live Source Verification Contract

This document defines the safe verification path for adding an EU live source after the first successful SEC live RSS polling smoke.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
current regional sequence: JP -> EU -> CN/TW -> APAC -> KR
JP status: blocked pending source authority decision
EU status: next active verification track
current sample source_key: eu_market_news
current sample base_url: https://example.com/globalpulse/eu-market-news
current fixture: source_payloads/eu_market_news.xml
current live status: NOT_READY_FOR_SCHEDULED_LIVE_POLLING
```

The current `eu_market_news` placeholder URL must not be live-polled.

## Candidate Sources

### Candidate A: ECB RSS feeds

```text
source authority: official
owner: European Central Bank
candidate category: euro-area central bank / macro / market-moving policy news
machine-readable shape: RSS
candidate feed to verify first: https://www.ecb.europa.eu/rss/press.html
status: PREFERRED_FIRST_EU_CANDIDATE_PENDING_STAGING_VERIFICATION
```

Rationale:

```text
ECB official RSS documentation states that RSS feeds are available for press releases, speeches, interviews, press conference transcripts, statistical press releases, publications, working papers, and recent open market operations/ad hoc communication.
```

Acceptance caveat:

```text
Do not add or schedule the ECB candidate until a staging smoke proves stable 2xx, rss_v1 parse compatibility, fetch.mode=live, and metadata.fallback_to_fixture=false.
```

### Candidate B: Eurostat RSS feeds

```text
source authority: official
owner: Eurostat / European Commission
candidate category: economic statistics and releases
machine-readable shape: RSS
status: GOOD_SECONDARY_EU_CANDIDATE_PENDING_EXACT_FEED_SELECTION
```

Rationale:

```text
Eurostat documents RSS as XML and lists common feeds including news releases and Eurostat news across economy and finance, industry, trade and services, international trade, environment and energy, science and technology, and other categories.
```

Acceptance caveat:

```text
Select one exact feed URL before adding a source registry entry.
Do not add a broad or alert-builder URL unless it returns stable RSS/XML directly.
```

### Candidate C: European Parliament XML feeds

```text
source authority: official
owner: European Parliament
candidate category: EU policy and legislative news
machine-readable shape: XML feeds
status: SECONDARY_POLICY_CANDIDATE_NOT_FIRST_MARKET_NEWS_SOURCE
```

Rationale:

```text
European Parliament publishes RSS/XML feeds for news, all press releases, committee press releases, and topic feeds including economic and monetary affairs and internal market and industry.
```

Acceptance caveat:

```text
Use only if the product needs EU institutional/policy coverage.
Do not treat this as a market-news source without category labeling.
```

### Candidate D: ESMA news page

```text
source authority: official
owner: European Securities and Markets Authority
candidate category: EU securities regulation and supervision
observed shape: public news HTML page
status: AUTHORITY_GOOD_BUT_MACHINE_READABLE_ENDPOINT_NOT_VERIFIED
```

Rationale:

```text
ESMA is directly relevant for EU financial markets regulation, but the currently observed public news page is an HTML listing and is not yet accepted as rss_v1 input.
```

Acceptance caveat:

```text
Find a verified RSS, Atom, JSON, or known API endpoint before adding ESMA as a live source.
Do not poll an HTML news page with rss_v1.
```

## EU v1 Recommendation

```text
EU_V1_CANDIDATE: ECB RSS press feed
candidate URL: https://www.ecb.europa.eu/rss/press.html
source_key proposal: eu_ecb_press
parser_key: rss_v1
coverage_tags: eu, macro, central_bank, policy, markets, news
initial mode: manual/staging verification only
scheduled polling: disabled until staging smoke passes
```

## Acceptance Gates

Before any EU live source can be scheduled or claimed as live-data ready, it must pass:

```text
authority: official or explicitly accepted third-party
machine_readable: RSS, Atom, XML, JSON, or known API shape
http: stable 2xx response
parser: rss_v1 compatible or bounded parser PR exists
fallback: metadata.fallback_to_fixture=false
source: fetch.mode=live
UI: at least one EU item renders in GlobalPulse Pages
rollback: disabling EU source does not break SEC live polling
scope: no public poll UI, audit UI, or public Source Health UI required
response_shape: public digest JSON response shape unchanged
```

## Explicit Rejections

```text
REJECT: live-polling https://example.com/globalpulse/eu-market-news
REJECT: treating an HTML page as rss_v1 live source
REJECT: claiming EU live success while falling back to fixture data
REJECT: adding broad source scraping without a stable machine-readable endpoint
REJECT: changing public digest response shape just to support EU
REJECT: exposing raw provider/auth/session/request diagnostics in public responses
```

## Next Allowed PRs

```text
1. Add disabled/manual ECB candidate source after exact feed URL is verified.
2. Run staging live poll smoke for ECB with fetch.mode=live.
3. Record EU ECB live polling smoke if successful.
4. Evaluate Eurostat exact feed if ECB is too policy-heavy or needs economic-statistics supplement.
5. Evaluate European Parliament topic feeds only as policy coverage, not generic market news.
```

## Current Conclusion

```text
EU_LIVE_SOURCE_TRACK_STARTED
EU_CURRENT_PLACEHOLDER_REJECTED_FOR_LIVE_POLLING
ECB_RSS_SELECTED_AS_FIRST_EU_CANDIDATE_PENDING_STAGING_VERIFICATION
EU_SCHEDULED_LIVE_POLLING_BLOCKED_UNTIL_STAGING_SMOKE_PASS
JP_REMAINING_AUTHORITY_DECISION_TRACKED_IN_ISSUE_339
```

## Stop Conditions

Stop and re-scope if EU live source work requires:

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
```
