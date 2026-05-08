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

## Source Selection Principle

GlobalPulse's primary EU live-source goal is listed-company disclosure coverage:

```text
primary product target: listed company disclosures and issuer announcements
preferred authority: official exchange, official regulated-information service, or official OAM-style disclosure repository
preferred content: issuer announcements, regulated information, corporate disclosures, company notices
not the first target: central bank, macro-statistics, parliament, or broad policy news feeds
```

Central-bank, macro, securities-regulator, and EU-institution feeds can remain useful later as separately labeled policy or markets context. They must not be treated as the first EU company-disclosure source.

## Candidate Sources

### Candidate A: EU listed-company disclosure endpoints

```text
source authority: official exchange, official regulated-information service, or official OAM-style disclosure repository
candidate category: listed company disclosures / issuer announcements / regulated information
candidate owners to verify: Euronext, Deutsche Boerse, Borsa Italiana, Nasdaq Nordic, or national regulated-information repositories
machine-readable shape: pending exact endpoint verification
status: PREFERRED_FIRST_EU_CANDIDATE_CLASS_PENDING_ENDPOINT_SCAN
```

Rationale:

```text
The product needs public-company disclosure and announcement coverage first. EU v1 should therefore start from official issuer-announcement or regulated-information surfaces, not central-bank or macro-policy feeds.
```

Acceptance caveat:

```text
Do not add or schedule an EU source until one exact RSS, Atom, XML, JSON, or known API endpoint is verified with stable 2xx, parser compatibility, fetch.mode=live, and metadata.fallback_to_fixture=false.
Do not treat an HTML search page or issuer-listing page as rss_v1 input.
```

### Candidate B: Euronext / regulated-information surfaces

```text
source authority: official exchange or regulated-information surface
candidate category: issuer announcements / regulated information
machine-readable shape: pending exact endpoint verification
status: GOOD_FIRST_SCAN_TARGET_PENDING_MACHINE_ENDPOINT
```

Rationale:

```text
Euronext-listed issuer announcements and regulated-information surfaces are closer to the desired company-disclosure product than institutional policy feeds.
```

Acceptance caveat:

```text
Verify exact endpoint, terms/rate limits, pagination, parser compatibility, and rollback before source registration.
Do not register a broad HTML page unless a bounded parser PR is explicitly accepted.
```

### Candidate C: National exchange or OAM disclosure repositories

```text
source authority: official exchange, OAM-style repository, or regulated-information mechanism
candidate category: listed-company announcements / issuer filings
candidate owners to verify: national exchange or disclosure repository surfaces
machine-readable shape: pending exact endpoint verification
status: GOOD_FIRST_SCAN_TARGET_PENDING_ENDPOINT_SELECTION
```

Rationale:

```text
National official disclosure repositories may provide issuer-level regulated information with better company-disclosure fidelity than pan-EU policy feeds.
```

Acceptance caveat:

```text
Keep EU member-state disclosure feeds region-labeled and source-labeled.
Do not broaden into general market or macro news unless it is a separately labeled secondary source.
```

### Candidate D: ECB RSS feeds

```text
source authority: official
owner: European Central Bank
candidate category: euro-area central bank / macro / market-moving policy news
machine-readable shape: RSS
candidate feed observed for later policy-news evaluation: https://www.ecb.europa.eu/rss/press.html
status: DEPRIORITIZED_POLICY_NEWS_NOT_FIRST_COMPANY_DISCLOSURE_SOURCE
```

Rationale:

```text
ECB feeds can be useful as macro or central-bank context, but they are not listed-company disclosures or issuer announcements.
```

Acceptance caveat:

```text
Do not add ECB as EU v1 if the product goal is public-company disclosure coverage.
If added later, label it as policy/macro context and keep it separate from issuer announcements.
```

### Candidate E: Eurostat RSS feeds

```text
source authority: official
owner: Eurostat / European Commission
candidate category: economic statistics and releases
machine-readable shape: RSS
status: DEPRIORITIZED_MACRO_STATISTICS_NOT_FIRST_COMPANY_DISCLOSURE_SOURCE
```

Rationale:

```text
Eurostat feeds can support macro context, but they do not satisfy the listed-company disclosure target.
```

Acceptance caveat:

```text
Use only as a separately labeled macro/statistics source after company-disclosure coverage is established.
```

### Candidate F: European Parliament and ESMA policy surfaces

```text
source authority: official
owner: European Parliament / European Securities and Markets Authority
candidate category: EU policy, legislative, or securities-regulation news
observed shape: XML/RSS possible for Parliament; ESMA public news HTML observed
status: SECONDARY_POLICY_CANDIDATE_NOT_FIRST_COMPANY_DISCLOSURE_SOURCE
```

Rationale:

```text
These sources may be relevant for regulatory context, but they are not the initial listed-company disclosure target.
```

Acceptance caveat:

```text
Use only if the product intentionally adds EU policy or regulator-news coverage.
Do not poll an HTML news page with rss_v1.
```

## EU v1 Recommendation

```text
EU_V1_TARGET: listed-company regulated information
candidate class: official exchange, official regulated-information service, or official OAM-style disclosure repository
candidate examples to scan: Euronext issuer announcements, Deutsche Boerse issuer announcements, Borsa Italiana issuer news, Nasdaq Nordic company announcements, national regulated-information repositories
source_key proposal: pending exact accepted endpoint
parser_key: pending exact endpoint shape
coverage_tags: eu, company_disclosure, issuer_announcement, regulated_information
initial mode: manual/staging verification only
scheduled polling: disabled until staging smoke passes
deprioritized: ECB/Eurostat/European Parliament/ESMA policy or macro feeds are not first EU company-disclosure candidates
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
REJECT: using ECB, Eurostat, Parliament, or broad policy feeds as the first EU listed-company disclosure source
REJECT: changing public digest response shape just to support EU
REJECT: exposing raw provider/auth/session/request diagnostics in public responses
```

## Next Allowed PRs

```text
1. Use globalpulse_eu_listed_company_disclosure_endpoint_scan.md as the current EU company-disclosure source scan record.
2. Add a bounded parser/adapter contract for the France Info-Financiere OAM JSON API.
3. Add a disabled/manual EU issuer-announcement source only after the parser contract, rate limits, and access terms are accepted.
4. Run staging live poll smoke with fetch.mode=live and metadata.fallback_to_fixture=false.
5. Record EU listed-company disclosure live polling smoke if successful.
6. Continue Euronext/Borsa/OAM endpoint scans only as follow-up candidates.
7. Evaluate ECB, Eurostat, European Parliament, or ESMA only later as separately labeled policy/macro/regulatory context.
```

## Current Conclusion

```text
EU_LIVE_SOURCE_TRACK_STARTED
EU_CURRENT_PLACEHOLDER_REJECTED_FOR_LIVE_POLLING
EU_LISTED_COMPANY_DISCLOSURE_TRACK_REQUIRED
ECB_RSS_RECLASSIFIED_AS_POLICY_NEWS_NOT_DISCLOSURE_SOURCE
FRANCE_INFO_FINANCIERE_OAM_API_FOUND_AS_FIRST_EU_COMPANY_DISCLOSURE_CANDIDATE
EU_COMPANY_DISCLOSURE_SOURCE_REGISTRATION_BLOCKED_PENDING_JSON_PARSER_OR_ADAPTER_CONTRACT
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
