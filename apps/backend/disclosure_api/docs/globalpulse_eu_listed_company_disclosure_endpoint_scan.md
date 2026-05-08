# GlobalPulse EU Listed-Company Disclosure Endpoint Scan

This document records the first EU live-source scan after the product direction was clarified: GlobalPulse should prioritize listed-company disclosures and issuer announcements, not central-bank or macro-policy feeds.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, source registration, or scheduled polling.

## Scan Goal

```text
primary target: listed-company disclosures and issuer announcements
preferred authority: official exchange, OAM, regulated-information repository, or issuer-announcement authority
not first target: ECB, central-bank feeds, macro-statistics feeds, parliament feeds, or broad policy news
current result: official EU company-disclosure candidates found, but no source registration yet
```

## Candidate A: France Info-Financiere OAM API

```text
owner: DILA / French official public-data surface with AMF as partner
authority class: official OAM / regulated-information repository
candidate URL: https://www.info-financiere.gouv.fr/api/explore/v2.1/catalog/datasets/flux-amf-new-prod/records?limit=1
observed HTTP: 200
observed content-type: application/json; charset=utf-8
observed shape: JSON records
observed record count: 500k+ total_count in executor smoke
status: STRONGEST_FIRST_EU_COMPANY_DISCLOSURE_CANDIDATE_PENDING_PARSER_CONTRACT
```

Why this fits the product:

```text
The API is explicitly for accessing centrally stored regulated information from listed companies, transmitted by the AMF and framed by the EU Transparency Directive OAM model.
It is open access and documents an API call limit.
It exposes archived documents and document metadata rather than central-bank or macro-policy news.
```

Blocking item:

```text
Current ingestion parser support is rss_v1 only.
This candidate should not be registered until a bounded JSON/Opendatasoft-style parser contract exists, or an adapter maps the API response into the existing canonical item shape.
```

## Candidate B: ESMA OAM Directory

```text
owner: ESMA
authority class: official EU authority directory
candidate URL: https://www.esma.europa.eu/et/node/200055
observed HTTP: public ESMA register page
observed shape: HTML directory listing national OAMs
status: AUTHORITY_MAP_ACCEPTED_NOT_A_POLL_SOURCE
```

Why this fits the product:

```text
ESMA lists national OAM databases that contain regulated information disclosed by issuers with shares admitted to trading on regulated markets.
This should be used as the source-discovery map for EU member-state disclosure repositories.
```

Blocking item:

```text
The ESMA directory itself is not the disclosure feed.
Each national OAM endpoint still needs separate machine-readable endpoint verification, parser fit, rate-limit review, and staging smoke.
```

## Candidate C: Euronext Live Company Press Releases

```text
owner: Euronext
authority class: official exchange / issuer-announcement surface
candidate URL: https://live.euronext.com/en/products/equities/company-news
observed HTTP: 200
observed content-type: text/html; charset=UTF-8
observed shape: HTML listing with issuer, release title, timestamp, market, industry, and topic fields
status: RELEVANT_PUBLIC_SURFACE_PENDING_MACHINE_ENDPOINT_OR_BOUNDED_HTML_PARSER
```

Why this fits the product:

```text
The page lists company press releases and includes company regulated news navigation across Euronext markets such as Amsterdam, Brussels, Lisbon, and Paris.
The topic taxonomy includes inside information, annual financial reports, half-yearly reports, major shareholding notifications, voting rights/capital, dividends, and other issuer-announcement categories.
```

Blocking item:

```text
The observed surface is HTML.
Do not poll it with rss_v1.
Either find an accepted RSS/Atom/JSON/API endpoint or add a bounded parser contract before source registration.
```

## Candidate D: Borsa Italiana / Italian SDIR and Storage Systems

```text
owner: Borsa Italiana / Consob-authorized SDIR and storage systems
authority class: official exchange guidance pointing to authorized issuer-disclosure storage
candidate guidance URL: https://www.borsaitaliana.it/azioni/documenti/documenti/documenti-comunicati-sdir-info.en.htm
observed HTTP: 200
observed shape: HTML guidance page
linked storage systems: 1INFO, EMARKET STORAGE
status: RELEVANT_AUTHORITY_SURFACE_PENDING_STORAGE_ENDPOINT_SCAN
```

Why this fits the product:

```text
Borsa Italiana states that company announcements from listed issuers through Consob-authorized SDIRs and documents from issuers on regulated markets are found on authorized storage systems and issuers' websites rather than on the Borsa Italiana website.
This makes the linked storage systems better Italy candidates than a generic exchange news page.
```

Blocking item:

```text
Scan 1INFO and EMARKET STORAGE for exact RSS, Atom, XML, JSON, API, or bounded-download endpoints.
Do not register the Borsa guidance page itself as a source.
```

## Candidate E: AMF Regulated-Information Dissemination Path

```text
owner: AMF
authority class: official national regulator guidance
candidate URL: https://www.amf-france.org/en/professionals/listed-companies-issuers/my-relations-amf/disseminating-regulated-information
observed HTTP: public guidance page
observed shape: HTML guidance
status: AUTHORITY_CONFIRMATION_FOR_FRANCE_PATH_NOT_A_POLL_SOURCE
```

Why this fits the product:

```text
The AMF guidance describes dissemination obligations for companies whose securities are admitted to trading on a regulated market and points to central archiving after regulated information is sent through the approved process.
This supports choosing the France Info-Financiere OAM API as the first EU company-disclosure candidate.
```

## Candidate F: Euronext Cash Market Notices

```text
owner: Euronext
authority class: official exchange notices / corporate actions surface
candidate URL: https://www.euronext.com/en/products-services/cash-market-notices
observed shape: product/service surface
machine-readable access: SFTP data product described by Euronext, not accepted as unauthenticated public feed
status: SECONDARY_EXCHANGE_NOTICE_CANDIDATE_NOT_FIRST_DISCLOSURE_SOURCE
```

Why this is not first:

```text
Cash market notices are relevant to listings, suspensions, corporate actions, dividends, and other exchange notices, but this is not the same as broad issuer-disclosure ingestion.
Machine-readable access appears tied to a data product/SFTP workflow, so it should not be assumed usable for unauthenticated staging polling.
```

## Recommended EU v1 Path

```text
1. Choose France Info-Financiere OAM API as the first EU listed-company disclosure live candidate.
2. Add a parser/adapter contract for the JSON API shape before source registration.
3. Keep source registration disabled/manual until parser contract, rate-limit handling, and bounded canonical mapping are accepted.
4. Run staging live smoke with fetch.mode=live and metadata.fallback_to_fixture=false.
5. Verify GlobalPulse public Pages renders at least one EU company-disclosure item.
6. Only then consider scheduled polling.
```

## Explicit Non-Goals

```text
DO_NOT: use ECB as the first EU company-disclosure source
DO_NOT: use Eurostat as the first EU company-disclosure source
DO_NOT: use European Parliament policy feeds as company disclosures
DO_NOT: use the ESMA OAM directory itself as a poll source
DO_NOT: poll HTML pages with rss_v1
DO_NOT: claim live success from fixture fallback
DO_NOT: register a source before exact endpoint, terms/rate limits, parser compatibility, and rollback are verified
DO_NOT: change public digest JSON response shape
```

## Current Conclusion

```text
EU_LISTED_COMPANY_DISCLOSURE_SCAN_STARTED
FRANCE_INFO_FINANCIERE_OAM_API_FOUND
FRANCE_INFO_FINANCIERE_OAM_API_HTTP_200_JSON
FRANCE_INFO_FINANCIERE_RECOMMENDED_AS_FIRST_EU_COMPANY_DISCLOSURE_CANDIDATE
EURONEXT_COMPANY_PRESS_RELEASES_PUBLIC_HTML_SURFACE_FOUND
BORSA_ITALIANA_POINTS_TO_CONSOB_AUTHORIZED_STORAGE_SYSTEMS
ESMA_OAM_DIRECTORY_ACCEPTED_AS_AUTHORITY_MAP_NOT_POLL_SOURCE
EU_SOURCE_REGISTRATION_BLOCKED_PENDING_JSON_PARSER_OR_ADAPTER_CONTRACT
EU_SCHEDULED_LIVE_POLLING_BLOCKED
```
