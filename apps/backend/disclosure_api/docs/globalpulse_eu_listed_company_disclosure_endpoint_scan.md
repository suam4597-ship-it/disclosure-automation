# GlobalPulse EU Listed-Company Disclosure Endpoint Scan

This document records the first EU live-source scan after the product direction was clarified: GlobalPulse should prioritize listed-company disclosures and issuer announcements, not central-bank or macro-policy feeds.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, source registration, or scheduled polling.

## Scan Goal

```text
primary target: listed-company disclosures and issuer announcements
preferred authority: official exchange, OAM, regulated-information repository, or issuer-announcement authority
not first target: ECB, central-bank feeds, macro-statistics feeds, parliament feeds, or broad policy news
current result: France OAM manual source + parser + staging live smoke complete; Spain CNMV manual RSS sources + parser compatibility fix + staging live smoke + public UI smoke complete; Netherlands AFM CSV manual source + parser + staging live smoke complete; Italy eMarket Storage bounded HTML manual source + parser + staging live smoke + public UI smoke complete; Luxembourg LuxSE OAM GraphQL manual source + parser + staging live smoke + public UI smoke complete; Euronext company press release RSS manual source + bounded parser + staging live smoke + public UI smoke complete; Belgium FSMA STORI API manual source + bounded parser + staging live smoke + public UI smoke complete; UK FCA NSM API manual source + bounded parser + staging live smoke complete; Switzerland SIX SER official notices RSS manual source + staging live smoke + public UI smoke complete; Nasdaq Nordic Company News JSONP manual source + staging live smoke + public UI smoke complete; Austria Wiener Boerse announcements bounded HTML manual source + staging live poll complete with public latest UI visibility pending; Germany Xetra Frankfurt Newsboard bounded HTML manual source + staging live smoke complete with public latest UI visibility pending; Greece ATHEX issuer announcements and corporate actions RSS manual sources staging live smoke complete with public latest UI visibility pending; Poland GPW ESPI/EBI bounded HTML manual source + staging live smoke complete with public latest UI visibility pending; remaining Europe candidates need endpoint/parser confirmation
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
machine-readable URL: https://live.euronext.com/rss/company-pr-release
observed HTTP: 200
observed content-type: page text/html; charset=UTF-8; RSS application/rss+xml; charset=utf-8
observed shape: official RSS 2.0 channel with title, link, description, pubDate, dc:creator, and guid fields; descriptions include nested HTML from the company-news surface
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_PUBLIC_UI_PASS_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
The page lists company press releases and includes company regulated news navigation across Euronext markets such as Amsterdam, Brussels, Lisbon, and Paris.
The topic taxonomy includes inside information, annual financial reports, half-yearly reports, major shareholding notifications, voting rights/capital, dividends, and other issuer-announcement categories.
The official RSS endpoint exposes the same issuer-announcement surface in a machine-readable form.
```

Current implementation status:

```text
Parser euronext_company_pr_rss_v1 exists.
Manual source eu_euronext_company_press_releases exists with active=false and candidate_status=manual_staging_only.
The parser reuses the official RSS item contract, prefers English release links when duplicated translations are present, and bounds nested HTML descriptions before canonicalization.
Fixture source_payloads/eu_euronext_company_press_releases.xml captures the official RSS shape without carrying raw page material.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=119260, records_seen=6, records_inserted=6, and metadata.fallback_to_fixture=false in the latest digest.
Public GlobalPulse Pages UI rendered Euronext Company Press Releases under the generic Europe section with Backend ok and no fatal browser console errors in the local headless browser smoke.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Candidate C2: Belgium FSMA STORI API

```text
owner: FSMA
authority class: official national regulator / central regulated-information storage mechanism
supporting URL: https://www.fsma.be/en/stori
machine-readable URL: https://webapi.fsma.be/api/v1/en/stori/result
observed HTTP: page 200; API POST 200
observed content-type: API application/json
observed shape: JSON result with resultCount and storiResultItems containing companyName, reportingTopicName, datePublication, dateReceived, mainDocuments, attachments, isinCodes, and document metadata
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_PUBLIC_UI_PASS_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
FSMA describes STORI as the Belgian official central storage mechanism for regulated information filed by issuers whose securities are admitted to trading on a regulated market, and for which Belgium is the home Member State, plus Euronext Growth issuers.
The public STORI page uses a Vue app backed by the webapi.fsma.be JSON API.
The endpoint returns issuer, document type, publication date, received date, document metadata, and ISIN information rather than central-bank or macro-policy material.
```

Current implementation status:

```text
Parser fsma_stori_api_v1 exists.
Manual source eu_belgium_fsma_stori exists with active=false and candidate_status=manual_staging_only.
The source uses a bounded POST body with sortColumn=DatePublication and pageSize=25.
Fixture source_payloads/eu_belgium_fsma_stori.json captures the bounded public JSON shape.
Fly staging live poll passed with fetch.mode=live, records_seen=25, records_inserted=25, and latest digest fallback_to_fixture=false.
Public GlobalPulse Pages UI rendered Belgium FSMA STORI Regulated Information under Central Europe.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Candidate C3: UK FCA National Storage Mechanism Search API

```text
owner: Financial Conduct Authority
authority class: official national storage mechanism / regulated-information repository
supporting URL: https://www.fca.org.uk/markets/ukla/regulatory-disclosures/national-storage-mechanism
machine-readable URL: https://api.data.fca.org.uk/search?index=fca-nsm-searchdata
observed HTTP: supporting page 200; API POST 200
observed content-type: API application/json
observed shape: JSON search result with hits.hits._source containing company, headline, type, publication_date, submitted_date, document_date, source, lei, disclosure_id, seq_id, and download_link
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_PUBLIC_UI_PASS_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
FCA describes the NSM as the official system for storing regulated information that issuers must disclose under UK Listing Rules, Disclosure Guidance and Transparency Rules, and UK MAR.
The public FCA data portal uses the api.data.fca.org.uk search endpoint for NSM search results.
The endpoint returns issuer/company names, regulatory headline categories, publication timestamps, LEI metadata, and links to stored announcement artefacts rather than central-bank or macro-policy material.
```

Current implementation status:

```text
Parser fca_nsm_search_api_v1 exists.
Manual source uk_fca_nsm_regulated_information exists with active=false and candidate_status=manual_staging_only.
The source uses a bounded POST body with sort=submitted_date, sortorder=desc, and size=25.
Fixture source_payloads/uk_fca_nsm_regulated_information.json captures the bounded public JSON shape.
Fly staging live poll passed with fetch.mode=live, records_seen=25, records_inserted=25, and latest digest fallback_to_fixture=false.
Public GlobalPulse Pages UI rendered UK FCA NSM Regulated Information under United Kingdom.
Scheduled polling remains disabled until the broader Europe source batch is intentionally promoted.
```

## Candidate C4: Switzerland SIX SER Official Notices RSS

```text
owner: SIX Exchange Regulation / SER
authority class: official exchange-regulation notices surface
supporting URL: https://www.six-group.com/en/market-data/news-tools/official-notices.html
machine-readable URL: https://www.ser-ag.com/itf-data/official-notices/rss-en.xml
observed HTTP: supporting page 200; RSS 200
observed content-type: RSS XML
observed shape: RSS 2.0 channel with title, link, description, guid, and pubDate fields; items point back to the SER official-notices page with notificationId anchors
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_PUBLIC_UI_PASS_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
SIX exposes an official-notices surface through SIX Exchange Regulation, and the page advertises a direct RSS endpoint rather than requiring HTML scraping.
The RSS items contain issuer or product-related notices such as issue-size changes, parameter adjustments, and delisting-related events from listed or exchange-traded instruments.
This is an official exchange-regulation notice source, not a central-bank or macro-policy feed.
```

Current implementation status:

```text
Manual source ch_six_ser_official_notices exists with active=false and candidate_status=manual_staging_only.
The source uses existing rss_v1 parser compatibility; no new parser or backend response-shape change is required.
Fixture source_payloads/ch_six_ser_official_notices.xml captures the bounded RSS shape.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=65762, records_seen=25, records_inserted=25, and metadata.fallback_to_fixture=false in the latest digest.
Public GlobalPulse Pages UI rendered Switzerland SIX SER Official Notices under Switzerland with Backend ok and no API/CORS/rendering blocker in the local headless browser smoke.
Scheduled polling remains disabled until the broader Europe source batch is intentionally promoted.
```

## Candidate C5: Nasdaq Nordic Company News JSONP API

```text
owner: Nasdaq Nordic
authority class: official exchange issuer-announcement surface
supporting URL: https://www.nasdaq.com/european-market-activity/news/company-news
machine-readable URL: https://api.news.eu.nasdaq.com/news/query.action
observed HTTP: supporting page 200; JSONP API 200
observed content-type: API application/javascript;charset=UTF-8
observed shape: JSONP handleResponse wrapper with results.item records containing disclosureId, company, headline, cnsCategory, market, published, releaseTime, messageUrl, language, and attachments
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_PUBLIC_UI_PASS_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
Nasdaq states that Nasdaq Nordic continuously publishes announcements from listed companies and that subscribers receive messages filed with Nasdaq by the respective companies.
The API returns issuer/company names, categories such as annual financial reports and major shareholder announcements, market names, publication timestamps, links to announcement views, and bounded attachment metadata.
This is an official exchange company-announcement source, not a central-bank or macro-policy feed.
```

Current implementation status:

```text
Parser nasdaq_nordic_cns_jsonp_v1 exists.
Manual source eu_nasdaq_nordic_company_news exists with active=false and candidate_status=manual_staging_only.
The source uses a bounded query with globalName=NordicAllMarkets, limit=25, dir=DESC, and callback=handleResponse.
Fixture source_payloads/eu_nasdaq_nordic_company_news.jsonp captures the bounded public JSONP shape.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=20382, records_seen=25, records_inserted=25, and metadata.fallback_to_fixture=false in the latest digest.
Public GlobalPulse Pages UI rendered Nasdaq Nordic Company News under Northern Europe with Backend ok and no API/CORS/rendering blocker in the local headless browser smoke.
Scheduled polling remains disabled until the broader Europe source batch is intentionally promoted.
```

## Candidate C6: Austria Wiener Boerse Announcements

```text
owner: Vienna Stock Exchange / Wiener Boerse
authority class: official exchange announcement surface
candidate URL: https://www.wienerborse.at/en/legal/announcements/
observed HTTP: page 200
observed content-type: text/html; charset=utf-8
observed shape: server-rendered HTML table with announcement date, kind, company, type of security, category, market, and announcement file link
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_PUBLIC_LATEST_UI_VISIBILITY_PENDING_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
The Vienna Stock Exchange announcements page describes corporate actions, dividends, new listings, and related trading announcements on the official exchange surface.
The page is not a central-bank or macro-policy feed.
The first integration is intentionally bounded to table rows and extracts only issuer/company, announcement kind, security type, market/category, date, and public announcement link.
```

Current implementation status:

```text
Parser wiener_borse_announcements_html_v1 exists.
Manual source eu_austria_wiener_borse_announcements exists with active=false and candidate_status=manual_staging_only.
Fixture source_payloads/eu_austria_wiener_borse_announcements.html captures a bounded two-row table shape.
Live-payload validation requires the official announcements table markers and rejects non-matching HTML.
OeKB issuerinfo remains an official Austria surface direction, but the current public shell returned SPA/F5 HTML for asset and endpoint probes in the executor, so no OeKB source is registered yet.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=313897, records_seen=22, records_inserted=22, and metadata.fallback_to_fixture=false.
Source health returned healthy with last_seen_published_at=2026-05-08T00:00:00Z.
Public latest UI visibility remains pending because the source inserted date-specific 2026-05-08 items while the public shell currently renders latest digest date 2026-05-09.
Scheduled polling remains disabled until the broader Europe source batch is intentionally promoted.
```

## Candidate C7: Germany Xetra Frankfurt Newsboard

```text
owner: Deutsche Boerse / Xetra and Frankfurt cash market
authority class: official exchange newsboard for trading and issuer-related notices
candidate URL: https://www.xetra.com/xetra-en/newsroom/xetra-newsboard/
observed HTTP: page 200
observed content-type: text/html; charset=UTF-8
observed shape: server-rendered search-result cards with date, venue/tagline, title, and detail link
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_PUBLIC_LATEST_UI_VISIBILITY_PENDING_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
The Xetra / Frankfurt Newsboard is an official Deutsche Boerse cash-market announcement surface.
The first integration intentionally filters for listed-instrument and issuer-adjacent notices such as dividends, capital adjustments, ISIN changes, new instruments, deletions, suspensions, and resumptions.
Operational service notices such as "service is down" are explicitly filtered out and are not treated as company disclosure content.
The page is not a central-bank, macro-policy, or ECB feed.
```

Current implementation status:

```text
Parser xetra_newsboard_html_v1 exists.
Manual source de_xetra_frankfurt_newsboard exists with active=false and candidate_status=manual_staging_only.
Fixture source_payloads/de_xetra_frankfurt_newsboard.html captures bounded search-result card shape and includes an operational service notice fixture row that must be filtered out.
Live-payload validation requires the official newsboard markers and rejects non-matching HTML.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=234647, records_seen=25, records_inserted=25, and metadata.fallback_to_fixture=false.
Source health returned healthy with last_seen_published_at=2026-05-08T18:34:37.000000Z.
Date-specific digest GET /api/feed/digest/2026-05-08/breaking rendered Germany Xetra Frankfurt Newsboard under Central Europe.
Public latest UI visibility remains pending because the source inserted 2026-05-08 items while the public shell currently renders latest digest date 2026-05-09.
Scheduled polling remains disabled until the broader Europe source batch is intentionally promoted.
```

## Candidate C8: Greece Euronext Athens / ATHEX RSS Feeds

```text
owner: Euronext Athens / ATHEX
authority class: official exchange RSS surfaces for issuer announcements and corporate actions
candidate URL 1: https://athens.euronext.com/en/rss/issuer-announcements
candidate URL 2: https://athens.euronext.com/en/rss/corporate-actions
observed HTTP: both feeds 200
observed content-type: application/rss+xml; charset=utf-8
observed shape: RSS 2.0 feeds with item title, link, description, pubDate, guid, and category
status: MANUAL_SOURCES_REGISTERED_STAGING_LIVE_POLL_PASS_PUBLIC_LATEST_UI_VISIBILITY_PENDING_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
The Euronext Athens RSS page explicitly lists Issuer Announcements and Corporate Actions feeds.
The selected feeds are exchange/issuer disclosure surfaces rather than central-bank, ECB, macro, or broad policy feeds.
The first integration reuses the bounded rss_v1 parser and keeps the sources manual_staging_only until staging live smoke and batch-promotion review are complete.
```

Current implementation status:

```text
Manual sources gr_athex_issuer_announcements and gr_athex_corporate_actions exist with active=false and candidate_status=manual_staging_only.
Fixtures source_payloads/gr_athex_issuer_announcements.xml and source_payloads/gr_athex_corporate_actions.xml capture bounded two-item RSS shapes.
The generic rss_v1 pubDate parser now accepts ISO 8601 timestamps such as 2026-05-08T21:37:14Z, matching the ATHEX live RSS shape.
Fly staging live poll returned fetch.mode=live, HTTP 200, records_seen=20, records_inserted=20, and metadata.fallback_to_fixture=false for both feeds.
Source health returned healthy for both feeds.
Date-specific digest GET /api/feed/digest/2026-05-08/breaking rendered Greece ATHEX Issuer Announcements under Southern Europe.
Date-specific digest GET /api/feed/digest/2026-05-05/breaking rendered Greece ATHEX Corporate Actions under Southern Europe.
Public latest UI visibility remains pending because the sources inserted 2026-05-08 and 2026-05-05 items while the public shell currently renders latest digest date 2026-05-09.
Scheduled polling remains disabled until the broader Europe source batch is intentionally promoted.
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
observed CSV shape: semicolon-delimited quoted fields: Datum deponering, Uitgevende instelling, Boekjaar, Soort
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
The AFM register covers financial reports filed by listed companies with the Netherlands as home member state and securities admitted to a regulated market.
The public page and export links point toward machine-readable financial-reporting disclosures for listed-company reporting.
The CSV export is the safer first staging integration target because it is materially smaller than the XML export on the current Fly machine class while preserving the bounded fields needed for GlobalPulse.
The live CSV payload may contain Latin-1 encoded issuer/document text, so the parser normalizes invalid UTF-8 payloads from Latin-1 to UTF-8 before JSON/DB insertion.
```

Current implementation status:

```text
Parser afm_financial_reporting_csv_v1 exists.
Manual source eu_netherlands_afm_financial_reporting exists with active=false and candidate_status=manual_staging_only.
Local DNS remains inconclusive, but Fly staging network raw payload probe returned HTTP 200 and official CSV/XML export bytes.
The XML export was rejected as the initial staging path after manual live poll OOM-killed the small Fly machine; the source now points to the lighter official CSV export.
The CSV parser includes Latin-1 fallback decoding after staging live smoke found invalid byte 0xEB in document type text.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=870901, records_seen=25, records_inserted=25, canonical_items=25, and no fixture fallback.
Date-specific digest GET /api/feed/digest/2026-05-02/breaking returned metadata.fallback_to_fixture=false and a Netherlands AFM Financial Reporting item with valid UTF-8 text.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Candidate J: Italy Consob-Authorized Storage Systems

```text
owner: Consob / authorized storage systems
authority class: official national regulator authorization list
candidate authority URL: https://www.consob.it/web/area-pubblica/meccanismi-di-stoccaggio-delle-informazioni-regolamentate
candidate systems: 1Info, eMarket Storage
observed HTTP: 1Info shell 200 HTML; eMarket Storage shell 200 HTML; Consob authority page 200 HTML
observed shape: public authority list plus storage-system surfaces; eMarket Storage public HTML includes current issuer disclosure cards, issuer names, timestamps, titles, and PDF links
status: EMARKET_STORAGE_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_PUBLIC_UI_PASS_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
Consob lists authorized centralized storage mechanisms for regulated information.
Borsa Italiana also points issuer announcements and documents toward these authorized systems rather than treating the exchange guidance page as the disclosure source.
```

Current implementation status:

```text
Parser emarket_storage_html_v1 exists.
Manual source eu_italy_emarket_storage_regulated_communications exists with active=false and candidate_status=manual_staging_only.
The parser is bounded to the first 25 eMarket Storage views-row cards and extracts only data_protocollo, PDF URL, timestamp, issuer name, and title.
The parser rejects non-eMarket HTML payloads through source-specific live-payload validation.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=81163, records_seen=24, records_inserted=24, canonical_items=24, and no fixture fallback.
Latest digest GET /api/feed/digest/latest?edition=breaking returned Italy eMarket Storage Regulated Communications under Southern Europe.
Public GitHub Pages headless Chrome DOM smoke rendered Backend ok, Southern Europe, Italy eMarket Storage Regulated Communications, and MONDO TV FRANCE.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
Continue scanning 1Info for a cleaner API/RSS/XML/JSON endpoint, but do not block the eMarket Storage manual candidate on 1Info.
Do not register the Consob list, Borsa guidance page, or arbitrary PDF search results as a source.
```

## Candidate K: Luxembourg LuxSE OAM / FIRST

```text
owner: Luxembourg Stock Exchange
authority class: official OAM / issuer filing and dissemination surface
candidate URL: https://www.luxse.com/issuer-services-overview/oam
supporting URL: https://www.luxse.com/issuer-services-overview/first
observed HTTP: 200
observed shape: HTML OAM/FIRST issuer-services surface and OAM search page backed by a public LuxSE GraphQL OAM submission search endpoint
GraphQL endpoint: https://graphqlaz.luxse.com/v1/graphql
GraphQL query: oamSubmissionsSearch(pageSize: 25, pageNumber: 1)
status: OFFICIAL_OAM_GRAPHQL_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
```

Why this fits the product:

```text
LuxSE describes OAM storage, regulated-information submission, and issuer communication under Transparency Directive obligations.
The public OAM search surface is backed by a JSON GraphQL query that returns issuer regulated-information submissions.
The candidate is therefore suitable for bounded manual staging smoke, not automatic scheduled polling yet.
```

Implementation status:

```text
Parser luxse_oam_graphql_v1 exists.
Manual source eu_luxembourg_luxse_oam exists with active=false and candidate_status=manual_staging_only.
The source uses a GET-encoded GraphQL query with an Apollo preflight header because the endpoint blocks bare GET queries as CSRF protection.
The source sets a bounded live_timeout_ms of 30000 because the LuxSE GraphQL response can exceed the default 8000 ms fetch timeout.
Parser output is bounded to submissionId, issuerName, submissionTypeLabel, actionsList, publicationDate, reference period, and the public OAM search URL.
Fixture source_payloads/eu_luxembourg_luxse_oam.json captures the bounded public JSON shape.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=7099, records_seen=25, records_inserted=25, and no fixture fallback.
Latest digest GET /api/feed/digest/latest?edition=breaking returned Luxembourg LuxSE OAM Regulated Information under Central Europe.
Public GitHub Pages headless Chrome DOM smoke rendered Backend ok, Central Europe, Luxembourg LuxSE OAM Regulated Information, and APERAM.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
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

## Candidate M: Norway Oslo Bors NewsWeb Main Market

```text
owner: Oslo Bors / Euronext
authority class: official exchange issuer announcement surface
candidate URL: https://newsweb.oslobors.no/
runtime config URL: https://newsweb.oslobors.no/urls.json
API base observed from runtime config: https://api3.oslo.oslobors.no
candidate API URL: https://api3.oslo.oslobors.no/v1/newsreader/list?market=XOSL&category=&issuer=&fromDate=&toDate=&messageTitle=
observed HTTP: POST 200
observed content-type: application/json
observed shape: JSON with data.messages records containing messageId, title, category, markets, issuerName, issuerSign, publishedTime, and clientAnnouncementId
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_PUBLIC_LATEST_UI_VISIBILITY_PENDING_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
NewsWeb is the official Oslo Bors issuer announcement surface and the public SPA loads its API base from a bounded urls.json runtime config.
The newsreader API returns issuer/company announcements for the Oslo Bors main market rather than central-bank, macro, or policy material.
The first integration is intentionally limited to market=XOSL so the candidate stays scoped to the main listed-company market before considering Euronext Expand, Nordic ABM, or Euronext Growth Oslo.
```

Implementation status:

```text
Parser oslo_newsweb_json_v1 exists.
Manual source no_oslo_bors_newsweb_main_market exists with active=false and candidate_status=manual_staging_only.
The source uses POST with an empty JSON body because the NewsWeb API returns an empty message list for the same URL over GET.
Fixture source_payloads/no_oslo_bors_newsweb_main_market.json captures the bounded public JSON shape.
Local live probe returned HTTP 200 application/json and a populated data.messages list for market=XOSL.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=374782, records_seen=25, records_inserted=25, canonical_items=25, and metadata.fallback_to_fixture=false.
Date-specific digest GET /api/feed/digest/2026-05-08/breaking rendered Norway Oslo Bors NewsWeb Main Market Announcements under Northern Europe.
Public latest UI visibility remains pending because the source inserted 2026-05-08 items while the public shell currently renders latest digest date 2026-05-09.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Candidate N: Poland GPW ESPI/EBI Company Reports

```text
owner: Warsaw Stock Exchange / GPW
authority class: official exchange issuer disclosure and company-report surface
candidate URL: https://www.gpw.pl/espi-ebi-reports
observed HTTP: 200
observed content-type: text/html
observed shape: HTML ESPI/EBI company-report list with bounded report metadata, issuer link text, report title, geru_id detail links, status, system, report number, and publication timestamp
supporting AJAX form: action=GPWEspiReportUnion, start=ajaxSearch, page=espi-ebi-reports, categoryRaports[]=EBI/ESPI
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_PUBLIC_LATEST_UI_VISIBILITY_PENDING_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
The GPW ESPI/EBI page is the official exchange surface for listed-company reports rather than central-bank, macro, or policy material.
The public page renders current ESPI/EBI issuer report entries and stable espi-ebi-report?geru_id=... detail links.
The first integration intentionally uses a bounded HTML parser instead of rss_v1, because the official surface is HTML rather than RSS/XML.
```

Implementation status:

```text
Parser gpw_espi_ebi_html_v1 exists.
Manual source pl_gpw_espi_ebi_reports exists with active=false and candidate_status=manual_staging_only.
Parser output is bounded to geru_id, issuer/company text, report title, source report URL, status, ESPI/EBI system, report number, and publication timestamp.
Fixture source_payloads/pl_gpw_espi_ebi_reports.html captures the bounded public HTML shape.
Local live probe returned 20 records from the official GPW HTML page and first external_id=488361.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=107916, records_seen=20, records_inserted=20, canonical_items=20, and metadata.fallback_to_fixture=false.
Date-specific digest GET /api/feed/digest/2026-05-08/breaking rendered Poland GPW ESPI/EBI Company Reports under Central Europe.
Public latest UI visibility remains pending because the source inserted 2026-05-08 items while the public shell currently renders latest digest date 2026-05-09.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Candidate O: Hungary Budapest Stock Exchange Issuers News

```text
owner: Budapest Stock Exchange
authority class: official exchange issuer-news surface
candidate URL: https://www.bse.hu/issuers_news
observed HTTP: 200
observed content-type: text/html;charset=UTF-8
observed shape: HTML issuer-news list with issuer name, publication timestamp, title, /site/newkib/... detail links, and embedded bounded JSON result data
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_PUBLIC_LATEST_UI_VISIBILITY_PENDING_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
The BSE Issuers News page is the official Budapest Stock Exchange issuer-news surface and lists issuer/company announcements, not central-bank, macro, or policy material.
The public page renders bounded issuer, title, timestamp, and detail-link metadata directly in HTML, with the same rows also embedded in the page's newkib list data.
The first integration intentionally uses a bounded HTML parser instead of rss_v1 because the official surface is HTML.
```

Implementation status:

```text
Parser bse_issuers_news_html_v1 exists.
Manual source hu_bse_issuers_news exists with active=false and candidate_status=manual_staging_only.
Parser output is bounded to newkib detail slug/id, issuer text, title, source URL, category=Issuer news, and publication timestamp.
Fixture source_payloads/hu_bse_issuers_news.html captures the bounded public HTML shape.
Fly staging live poll passed with fetch.mode=live, fetch.status_code=200, records_seen=10, and records_inserted=10.
Date-specific digest 2026-05-08/breaking includes the first Hungary item under eu_central.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Recommended EU v1 Path

```text
1. Keep France Info-Financiere OAM as the first proven EU listed-company disclosure live candidate.
2. Keep Spain CNMV inside-information and other-relevant-information RSS as proven manual_staging_only live candidates.
3. Keep Netherlands AFM financial reporting CSV as a proven manual_staging_only live candidate.
4. Do not batch-promote scheduled EU polling yet; France + Spain + Netherlands prove the path but do not define the full EU rollout by themselves.
5. Keep Italy eMarket Storage regulated communications as a proven manual_staging_only live candidate.
6. Keep Luxembourg LuxSE OAM as a proven manual_staging_only GraphQL live candidate.
7. Keep Austria Wiener Boerse announcements as a proven manual_staging_only exchange-announcement candidate with public latest UI visibility pending.
8. Keep Germany Xetra Frankfurt Newsboard as a proven manual_staging_only exchange-announcement candidate with public latest UI visibility pending.
9. Keep Greece ATHEX issuer announcements and corporate actions as proven manual_staging_only RSS candidates with public latest UI visibility pending.
10. Keep Norway Oslo Bors NewsWeb main market as a proven manual_staging_only API candidate with public latest UI visibility pending.
11. Keep Poland GPW ESPI/EBI company reports as a proven manual_staging_only HTML parser candidate with public latest UI visibility pending.
12. Keep Hungary Budapest Stock Exchange Issuers News as a proven manual_staging_only HTML parser candidate with public latest UI visibility pending.
13. Continue endpoint/parser discovery for Germany official register surfaces, OeKB issuerinfo, Portugal, Prague, Bucharest BVB IRIS, and other official issuer-announcement surfaces.
14. Only batch-promote scheduled EU polling after the target list, rollback path, source-specific parser risk, and staging live smoke evidence are documented together.
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
NETHERLANDS_AFM_CSV_EXPORT_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
ITALY_EMARKET_STORAGE_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
ITALY_EMARKET_STORAGE_PUBLIC_UI_PASS
LUXEMBOURG_LUXSE_OAM_GRAPHQL_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
LUXEMBOURG_LUXSE_OAM_PUBLIC_UI_PASS
AUSTRIA_WIENER_BORSE_ANNOUNCEMENTS_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
AUSTRIA_WIENER_BORSE_PUBLIC_LATEST_UI_VISIBILITY_PENDING
AUSTRIA_OEKB_ISSUERINFO_OFFICIAL_SURFACE_FOUND_MACHINE_ENDPOINT_PENDING
NORWAY_OSLO_BORS_NEWSWEB_MAIN_MARKET_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
NORWAY_OSLO_BORS_NEWSWEB_PUBLIC_LATEST_UI_VISIBILITY_PENDING
POLAND_GPW_ESPI_EBI_COMPANY_REPORTS_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
POLAND_GPW_ESPI_EBI_COMPANY_REPORTS_PUBLIC_LATEST_UI_VISIBILITY_PENDING
HUNGARY_BSE_ISSUERS_NEWS_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
HUNGARY_BSE_ISSUERS_NEWS_PUBLIC_LATEST_UI_VISIBILITY_PENDING
GERMANY_OFFICIAL_REGISTER_SURFACE_DIRECTION_FOUND_MACHINE_ENDPOINT_PENDING
EURONEXT_COMPANY_PRESS_RELEASES_PUBLIC_HTML_SURFACE_FOUND
BORSA_ITALIANA_POINTS_TO_CONSOB_AUTHORIZED_STORAGE_SYSTEMS
ESMA_OAM_DIRECTORY_ACCEPTED_AS_AUTHORITY_MAP_NOT_POLL_SOURCE
EU_NEXT_IMPLEMENTATION_STEP_PORTUGAL_OR_PRAGUE_ENDPOINT_DISCOVERY
EU_SCHEDULED_LIVE_POLLING_BLOCKED
```
