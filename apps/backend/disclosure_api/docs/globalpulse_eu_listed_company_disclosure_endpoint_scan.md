# GlobalPulse EU Listed-Company Disclosure Endpoint Scan

This document records the first EU live-source scan after the product direction was clarified: GlobalPulse should prioritize listed-company disclosures and issuer announcements, not central-bank or macro-policy feeds.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, source registration, or scheduled polling.

## Scan Goal

```text
primary target: listed-company disclosures and issuer announcements
preferred authority: official exchange, OAM, regulated-information repository, or issuer-announcement authority
not first target: ECB, central-bank feeds, macro-statistics feeds, parliament feeds, or broad policy news
current result: France OAM manual source + parser + staging live smoke complete; Spain CNMV manual RSS sources + parser compatibility fix + staging live smoke + public UI smoke complete; remaining EU candidates need endpoint/parser confirmation
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
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
The API is explicitly for accessing centrally stored regulated information from listed companies, transmitted by the AMF and framed by the EU Transparency Directive OAM model.
It is open access and documents an API call limit.
It exposes archived documents and document metadata rather than central-bank or macro-policy news.
```

Current implementation status:

```text
Parser info_financiere_oam_v1 exists.
Manual source eu_france_info_financiere_oam exists with active=false and candidate_status=manual_staging_only.
Fly staging live poll returned fetch.mode=live, HTTP 200, records_seen=25, records_inserted=25, and metadata.fallback_to_fixture=false.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
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

## Candidate G: Spain CNMV Inside Information RSS

```text
owner: CNMV
authority class: official national securities regulator / issuer inside-information feed
candidate URL: https://www.cnmv.es/portal/informacion-privilegiada/RSS.asmx/GetNoticiasCNMV
supporting CNMV RSS page: https://www.cnmv.es/portal/gpage?id=RSS&lang=en
observed HTTP: 200
observed content-type: text/xml; charset=utf-8
observed shape: RSS 2.0 XML
status: READY_FOR_MANUAL_SOURCE_CANDIDATE_RSS_V1
post-Spain update status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_PUBLIC_UI_PASS_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
CNMV exposes an official RSS channel for insider information.
The feed is machine-readable XML and aligns with listed-company inside-information disclosures rather than central-bank or broad macro news.
The observed XML shape is compatible with the existing rss_v1 parser.
```

Guardrail:

```text
Register as active=false/manual_staging_only first.
Run staging live smoke and verify fetch.mode=live plus metadata.fallback_to_fixture=false before any scheduled polling decision.
```

Current implementation status:

```text
Manual source eu_spain_cnmv_inside_information exists with active=false and candidate_status=manual_staging_only.
The UTF-8/mixed-case RSS parser compatibility fix is merged.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=3639, records_seen=5, records_inserted=5, canonical_items=5, and metadata.fallback_to_fixture=false.
Public GlobalPulse Pages UI rendered the source under Southern Europe with Backend ok and no browser console fetch/CORS errors in the local browser smoke.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Candidate H: Spain CNMV Other Relevant Information RSS

```text
owner: CNMV
authority class: official national securities regulator / issuer other-relevant-information feed
candidate URL: https://www.cnmv.es/portal/Otra-Informacion-Relevante/RSS.asmx/GetNoticiasCNMV
supporting CNMV RSS page: https://www.cnmv.es/portal/gpage?id=RSS&lang=en
observed HTTP: 200
observed content-type: text/xml; charset=utf-8
observed shape: RSS 2.0 XML
status: READY_FOR_MANUAL_SOURCE_CANDIDATE_RSS_V1
post-Spain update status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_PUBLIC_UI_PASS_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
CNMV exposes an official RSS channel for other relevant information.
This complements the inside-information feed while staying within official issuer-disclosure material.
The observed XML shape is compatible with the existing rss_v1 parser.
```

Guardrail:

```text
Register as active=false/manual_staging_only first.
Do not merge this into scheduled polling until staging live smoke verifies bounded records and no fixture fallback.
```

Current implementation status:

```text
Manual source eu_spain_cnmv_other_relevant_information exists with active=false and candidate_status=manual_staging_only.
The UTF-8/mixed-case RSS parser compatibility fix is merged.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=22777, records_seen=25, records_inserted=25, canonical_items=25, and metadata.fallback_to_fixture=false.
Public GlobalPulse Pages UI rendered Spain CNMV Other Relevant Information under Southern Europe with Backend ok and no browser console fetch/CORS errors in the local browser smoke.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Candidate I: Netherlands AFM Financial Reporting Register

```text
owner: AFM
authority class: official national regulator / financial-reporting register
candidate URL: https://www.afm.nl/en/sector/registers/meldingenregisters/financiele-verslaggeving
candidate CSV export URL: https://www.afm.nl/export.aspx?format=csv&type=e8825b05-4004-4301-b736-651e8c61053d
candidate XML export URL: https://www.afm.nl/export.aspx?format=xml&type=e8825b05-4004-4301-b736-651e8c61053d
observed search/browser result: official register page and CSV export surface with filing-date and issuing-institution fields
local executor direct export probe: DNS resolution failed for www.afm.nl in local shell
Fly staging network export probe: HTTP 200 for CSV and XML export URLs
observed XML shape: <register><vermelding><id>...</id><datum>...</datum><uitgevende-instelling>...</uitgevende-instelling>...</vermelding></register>
status: MANUAL_SOURCE_CANDIDATE_REGISTERED_PARSER_ADDED_STAGING_LIVE_SMOKE_PENDING
```

Why this fits the product:

```text
The AFM register covers financial reports filed by listed companies with the Netherlands as home member state and securities admitted to a regulated market.
The public page and export links point toward machine-readable financial-reporting disclosures for listed-company reporting.
The XML export is a better first integration target than CSV because it preserves named fields and avoids delimiter/encoding ambiguity.
```

Current implementation status:

```text
Parser afm_financial_reporting_xml_v1 exists.
Manual source eu_netherlands_afm_financial_reporting exists with active=false and candidate_status=manual_staging_only.
Local DNS remains inconclusive, but Fly staging network raw payload probe returned HTTP 200 and official XML export bytes.
Staging live poll is still pending and must verify fetch.mode=live plus metadata.fallback_to_fixture=false before any scheduled polling decision.
```

## Candidate J: Italy Consob-Authorized Storage Systems

```text
owner: Consob / authorized storage systems
authority class: official national regulator authorization list
candidate authority URL: https://www.consob.it/web/area-pubblica/meccanismi-di-stoccaggio-delle-informazioni-regolamentate
candidate systems: 1Info, eMarket Storage
observed HTTP: 1Info shell 200 HTML; eMarket Storage shell 200 HTML; Consob authority page 200 HTML
observed shape: public authority list plus storage-system surfaces; eMarket Storage public HTML includes current issuer disclosure cards and PDF links
status: AUTHORIZED_HTML_DISCLOSURE_SURFACES_FOUND_BOUNDED_HTML_OR_API_PARSER_PENDING
```

Why this fits the product:

```text
Consob lists authorized centralized storage mechanisms for regulated information.
Borsa Italiana also points issuer announcements and documents toward these authorized systems rather than treating the exchange guidance page as the disclosure source.
```

Blocking item:

```text
Find exact RSS, Atom, XML, JSON, API, or bounded-download endpoints for 1Info and eMarket Storage, or explicitly approve a bounded HTML parser contract for the authorized storage listing.
Do not register the Consob list, Borsa guidance page, or arbitrary PDF search results as a source.
```

## Candidate K: Luxembourg LuxSE OAM / FIRST

```text
owner: Luxembourg Stock Exchange
authority class: official OAM / issuer filing and dissemination surface
candidate URL: https://www.luxse.com/issuer-services-overview/oam
supporting URL: https://www.luxse.com/issuer-services-overview/first
observed HTTP: 200
observed shape: HTML OAM/FIRST issuer-services surface and OAM search page; no accepted public API/feed endpoint confirmed in the quick scan
status: OFFICIAL_OAM_SEARCH_SURFACE_FOUND_API_ENDPOINT_PENDING
```

Why this fits the product:

```text
LuxSE describes OAM storage, regulated-information submission, and issuer communication under Transparency Directive obligations.
This is relevant authority evidence, but the observed public surface is not yet a pollable machine-readable disclosure endpoint.
```

Blocking item:

```text
Find an accepted public API, RSS/Atom feed, XML export, JSON endpoint, or bounded-download endpoint before source registration.
```

## Candidate L: Germany Unternehmensregister / Official Register Surface

```text
owner: German official register ecosystem
authority class: official register / disclosure surface candidate
candidate direction: Unternehmensregister / official publication and filing surface
observed HTTP: Unternehmensregister public shell 200 HTML
observed shape: public web/register surface, not yet a stable unauthenticated feed
status: OFFICIAL_SURFACE_DIRECTION_FOUND_MACHINE_ENDPOINT_PENDING
```

Why this may fit the product:

```text
Germany remains important for listed-company filings and announcements, but the next step must be exact endpoint verification rather than registering a human search surface.
```

Blocking item:

```text
Identify the exact official machine-readable endpoint or add a bounded parser only after confirming terms, rate limits, and response stability.
Do not use third-party register APIs as official GlobalPulse disclosure sources without explicit acceptance.
```

## Recommended EU v1 Path

```text
1. Keep France Info-Financiere OAM as the first proven EU listed-company disclosure live candidate.
2. Keep Spain CNMV inside-information and other-relevant-information RSS as proven manual_staging_only live candidates.
3. Do not batch-promote scheduled EU polling yet; France + Spain prove the path but do not define the full EU rollout by themselves.
4. Run Netherlands AFM staging live smoke next because the official XML export is now registered as active=false/manual_staging_only.
5. Choose Italy 1Info/eMarket after AFM if an API/RSS/XML/JSON endpoint is found, or if a bounded HTML parser contract is explicitly accepted.
6. Continue endpoint/parser discovery for Luxembourg LuxSE OAM, Germany official register surfaces, and Euronext issuer press-release surfaces.
7. Only batch-promote scheduled EU polling after the target list, rollback path, source-specific parser risk, and staging live smoke evidence are documented together.
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
DO_NOT: batch-promote scheduled EU polling just because one country source passes live smoke
```

## Current Conclusion

```text
EU_LISTED_COMPANY_DISCLOSURE_SCAN_UPDATED
FRANCE_INFO_FINANCIERE_OAM_API_MANUAL_SOURCE_REGISTERED
FRANCE_INFO_FINANCIERE_OAM_STAGING_LIVE_POLL_PASS
SPAIN_CNMV_INSIDE_INFORMATION_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
SPAIN_CNMV_OTHER_RELEVANT_INFORMATION_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
SPAIN_CNMV_PUBLIC_UI_PASS
NETHERLANDS_AFM_XML_EXPORT_MANUAL_SOURCE_CANDIDATE_REGISTERED
NETHERLANDS_AFM_STAGING_LIVE_SMOKE_PENDING
ITALY_CONSOB_AUTHORIZED_STORAGE_HTML_SURFACES_FOUND_PARSER_PENDING
LUXEMBOURG_LUXSE_OAM_SEARCH_SURFACE_FOUND_API_ENDPOINT_PENDING
GERMANY_OFFICIAL_REGISTER_SURFACE_DIRECTION_FOUND_MACHINE_ENDPOINT_PENDING
EURONEXT_COMPANY_PRESS_RELEASES_PUBLIC_HTML_SURFACE_FOUND
BORSA_ITALIANA_POINTS_TO_CONSOB_AUTHORIZED_STORAGE_SYSTEMS
ESMA_OAM_DIRECTORY_ACCEPTED_AS_AUTHORITY_MAP_NOT_POLL_SOURCE
EU_NEXT_IMPLEMENTATION_STEP_AFM_STAGING_LIVE_SMOKE
EU_SCHEDULED_LIVE_POLLING_BLOCKED
```
