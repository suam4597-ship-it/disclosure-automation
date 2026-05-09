# GlobalPulse EU Listed-Company Disclosure Endpoint Scan

This document records the first EU live-source scan after the product direction was clarified: GlobalPulse should prioritize listed-company disclosures and issuer announcements, not central-bank or macro-policy feeds.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, source registration, or scheduled polling.

## Scan Goal

```text
primary target: listed-company disclosures and issuer announcements
preferred authority: official exchange, OAM, regulated-information repository, or issuer-announcement authority
not first target: ECB, central-bank feeds, macro-statistics feeds, parliament feeds, or broad policy news
current result: France OAM manual source + parser + staging live smoke complete; Spain CNMV manual RSS sources + parser compatibility fix + staging live smoke + public UI smoke complete; Netherlands AFM CSV manual source + parser + staging live smoke complete; Italy eMarket Storage bounded HTML manual source + parser + staging live smoke + public UI smoke complete; Luxembourg LuxSE OAM GraphQL manual source + parser + staging live smoke + public UI smoke complete; Euronext company press release RSS manual source + bounded parser + staging live smoke + public UI smoke complete; Belgium FSMA STORI API manual source + bounded parser + staging live smoke + public UI smoke complete; UK FCA NSM API manual source + bounded parser + staging live smoke complete; Switzerland SIX SER official notices RSS manual source + staging live smoke + public UI smoke complete; Nasdaq Nordic Company News JSONP manual source + staging live smoke + public UI smoke complete; Austria Wiener Boerse announcements bounded HTML manual source + staging live poll complete with public latest UI visibility pending; Austria OeKB OAM Issuer Info JSON manual source + staging live smoke complete with digest top-n visibility pending; Germany Xetra Frankfurt Newsboard bounded HTML manual source + staging live smoke complete with public latest UI visibility pending; Germany Company Register capital-market surface confirmed and token-preflight fetch contract recorded, but source registration remains blocked pending stable detail URL/date-order/parser/staging-network evidence; Greece ATHEX issuer announcements and corporate actions RSS manual sources staging live smoke complete with public latest UI visibility pending; Poland GPW ESPI/EBI bounded HTML manual source + staging live smoke complete with public latest UI visibility pending; Slovakia CERI bounded HTML manual source + staging live smoke complete with public latest UI visibility pending; Estonia OAM bounded HTML manual source + staging live smoke complete with public latest UI visibility pending; Lithuania OAM bounded HTML manual source + staging live smoke complete with public latest UI visibility pending; Latvia CSRI bounded HTML manual source + staging live smoke complete with digest top-n visibility pending; Portugal CMVM portal InfoPrivi JSON manual source + staging live smoke complete with digest top-n visibility pending; Prague/PSE issuer-news-only multi-ISIN manual source + parser + source-specific fan-out fetch adapter staging live smoke complete with date-specific digest visibility passing; Prague/PSE issuer report calendar multi-ISIN manual source + parser + source-specific fan-out fetch adapter added with local fixture/live aggregate parser smoke passing and staging live poll pending; remaining Europe candidates need endpoint/parser confirmation
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
OeKB issuerinfo is now tracked separately as an official OAM JSON candidate.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=313897, records_seen=22, records_inserted=22, and metadata.fallback_to_fixture=false.
Source health returned healthy with last_seen_published_at=2026-05-08T00:00:00Z.
Public latest UI visibility remains pending because the source inserted date-specific 2026-05-08 items while the public shell currently renders latest digest date 2026-05-09.
Scheduled polling remains disabled until the broader Europe source batch is intentionally promoted.
```

## Candidate C6b: Austria OeKB OAM Issuer Info JSON

```text
owner: OeKB / Oesterreichische Kontrollbank AG
authority class: official Austria OAM / central storage system for issuer information
supporting URL: https://www.oekb.at/en/capital-market-services/our-range-of-data-knowledge-creates-an-advantage/information-about-listed-issuers.html
machine-readable URL: https://my.oekb.at/issuer-info/rest/public/meldedaten/iic?startPosition=0&offset=25&locale=en
observed HTTP: 200
observed content-type: application/json
observed shape: JSON object with anzahlTreffer and dokumente[] issuer-document rows
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_DIGEST_TOP_N_VISIBILITY_PENDING_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
OeKB states that it operates OAM Issuer Info as the central platform for listed-issuer information, including regulated information under Sec. 123 Austrian Stock Exchange Act and optional issuer information.
The public OeKB page says OAM Issuer Info can be accessed without login and allows the public to search and download original documents free of charge.
The observed JSON endpoint returns issuer document rows with issuer name, LEI, title, notification type, language, upload timestamp, ISIN references, and downloadable files.
This endpoint is not a central-bank, macro, parliament, or policy-news feed.
```

Implementation status:

```text
Manual source at_oekb_oam_issuer_info exists with active=false and candidate_status=manual_staging_only.
The source uses parser_key=oekb_oam_issuer_info_json_v1 against the official OeKB OAM Issuer Info public JSON shape.
Fixture source_payloads/at_oekb_oam_issuer_info.json captures the bounded dokumente[] row shape.
The live endpoint supports explicit startPosition=0, offset=25, and locale=en query parameters.
Local parser smoke passed with fixture_records=2, live HTTP 200, live_records=25, and the first live record populated issuer/title/url/published_at/category.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=19260, records_seen=25, records_inserted=25, canonical_items=25, and fixture fallback=false.
Source health returned healthy with last_seen_published_at=2026-05-08T16:10:28.230000Z.
Digest top-n visibility remains pending because the latest digest pointed to 2026-05-09 India items and the date-specific 2026-05-08 top-N window was filled by later existing items.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
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
owner: Unternehmensregister / Company Register
authority class: official German company-register capital-market information surface
candidate direction: Unternehmensregister capital-market information search
supporting URL: https://www.unternehmensregister.de/en/search/capital-market-info
token endpoint: https://www.unternehmensregister.de/api/search-token
observed HTTP: search page 200 HTML; search-token 200; tokenized result page 200 HTML
observed shape: Next.js/React flight HTML with searchResults.elasticSearchDtos and publicationDto rows after search-token preflight
status: OFFICIAL_CAPITAL_MARKET_SURFACE_CONFIRMED_TOKEN_PREFLIGHT_FETCH_CONTRACT_RECORDED_SOURCE_REGISTRATION_BLOCKED
```

Why this may fit the product:

```text
The official capital-market page is scoped to issuer messages to the Company Register, including insider information, managers' transactions, country of origin, voting-rights notifications, securities acquisition and transfer, prospectus notices, and other capital-market information.
The tokenized result page exposes publicationDto rows with publication type/category/part, company name, source date, title, source name, encrypted payload, and PDF availability.
The tokenless search URL returns a shell without searchResults, and the tokenized URL depends on an ephemeral searchToken.
The official search help describes search results as sorted by relevance, so the unfiltered result order must not be treated as newest-first.
```

Blocking item:

```text
The token-preflight contract is recorded in globalpulse_germany_company_register_token_preflight_contract.md.
Source registration remains blocked until staging-network reachability, date filters, result ordering, detail/download URL stability, parser shape, terms/rate limits, and response stability are confirmed.
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

## Candidate P: Romania Bucharest Stock Exchange Current Reports

```text
owner: Bucharest Stock Exchange
authority class: official exchange issuer current-report surface
candidate URL: https://bvb.ro/FinancialInstruments/SelectedData/CurrentReports
observed HTTP: 200
observed content-type: text/html; charset=utf-8
observed shape: ASP.NET HTML table with symbol, issuer/company, description, publication timestamp, document type, PDF links, and /FinancialInstruments/SelectedData/NewsItem/... detail links
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_DIGEST_TOP_N_VISIBILITY_PENDING_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
The BVB Current Reports page is an official Bucharest Stock Exchange issuer-report surface and lists listed-company announcements/current reports, not central-bank, macro, or policy material.
The public page exposes bounded issuer, ticker, ISIN, description, timestamp, document type, and BVB NewsItem/detail-link metadata directly in HTML.
The first integration intentionally uses a bounded HTML parser instead of rss_v1 because the official surface is HTML.
```

Implementation status:

```text
Parser bvb_current_reports_html_v1 exists.
Manual source ro_bvb_current_reports exists with active=false and candidate_status=manual_staging_only.
Parser output is bounded to BVB NewsItem/PDF URL, issuer, description, ticker, ISIN, document type, and publication timestamp.
Fixture source_payloads/ro_bvb_current_reports.html captures the bounded public HTML table shape.
Fly staging live poll passed with fetch.mode=live, fetch.status_code=200, records_seen=25, and records_inserted=24.
The 2026-05-08/breaking digest top-n result did not yet include Romania BVB because existing higher-ranked/diverse items filled the current public digest window.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Candidate Q: Slovenia OAM / INFO STORAGE Regulated Information

```text
owner: Ljubljana Stock Exchange
authority class: official OAM / regulated-information storage surface
candidate URL: https://www.oam.si/rss
supporting URL: https://www.oam.si/default_en.aspx?doc=HELP
observed HTTP: 200
observed content-type: application/rss+xml; charset=utf-8
observed shape: RSS 2.0 feed with doc_id links, issuer/category text, announcement title, description, and pubDate
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_DIGEST_TOP_N_VISIBILITY_PENDING_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
INFO STORAGE is described by its help page as the central storage of regulated information operated by the Ljubljana Stock Exchange.
It stores regulated information published by listed companies, including inside information, periodic reports, substantial holdings, general meetings, financial calendars, corporate actions, and other statutory reporting obligations.
The official help page documents RSS updates at http://www.oam.si/rss, so this source can use rss_v1 instead of treating an HTML search page as RSS.
```

Implementation status:

```text
Manual source si_oam_regulated_information exists with active=false and candidate_status=manual_staging_only.
The source uses parser_key=rss_v1 against the official application/rss+xml feed.
Fixture source_payloads/si_oam_regulated_information.xml captures the bounded public RSS shape.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=4656, records_seen=11, records_inserted=11, canonical_items=11, and no fixture fallback.
Latest and 2026-05-08 date-specific digest top-n responses did not yet include Slovenia OAM because existing higher-ranked/diverse items filled the current public digest windows.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Candidate R: Croatia ZSE EHO Issuer News and Financial Reports

```text
owner: Zagreb Stock Exchange
authority class: official exchange issuer-announcement and financial-report feed surface
supporting URL: https://eho.zse.hr/en/feed
issuer news RSS URL: https://eho.zse.hr/en/feed/rss?variant=issuerNews
financial reports RSS URL: https://eho.zse.hr/en/feed/rss?vrsta=financ
observed HTTP: 200
observed content-type: text/xml;charset=utf-8
observed shape: RSS 2.0 feeds with issuer/company title, detail/document link, description, pubDate, local publication time, and XZAG venue marker
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_PARTIAL_DIGEST_VISIBILITY_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
EHO is described as a Zagreb Stock Exchange service for publishing inside, regulated, and other information by issuers listed on the regulated market managed by the Zagreb Stock Exchange.
The EHO data feed page documents XML, JSON, and RSS feeds, including issuer news and financial reports.
The first integration uses official RSS feed URLs and the existing rss_v1 parser rather than scraping the EHO HTML application.
```

Implementation status:

```text
Manual source hr_zse_eho_issuer_news exists with active=false and candidate_status=manual_staging_only.
Manual source hr_zse_eho_financial_reports exists with active=false and candidate_status=manual_staging_only.
Fixture source_payloads/hr_zse_eho_issuer_news.xml captures the bounded issuer-news RSS shape.
Fixture source_payloads/hr_zse_eho_financial_reports.xml captures the bounded financial-report RSS shape.
Fly staging live poll for hr_zse_eho_issuer_news returned fetch.mode=live, HTTP 200, fetch.bytes=7717, records_seen=20, records_inserted=20, canonical_items=20, and no fixture fallback.
Fly staging live poll for hr_zse_eho_financial_reports returned fetch.mode=live, HTTP 200, fetch.bytes=8007, records_seen=20, records_inserted=20, canonical_items=20, and no fixture fallback.
Date-specific digest GET /api/feed/digest/2026-05-04/breaking rendered Croatia ZSE EHO Financial Reports under Southern Europe.
Issuer-news digest top-n visibility remains pending because the 2026-05-08 digest top-n window is filled by other higher-ranked/diverse items.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Candidate S: Slovakia CERI Regulated Information

```text
owner: Central Register of Regulated Information / Národná banka Slovenska
authority class: official Slovakia central storage of regulated issuer information
supporting URL: https://ceri.nbs.sk/index
candidate URL: https://ceri.nbs.sk/search
observed HTTP: 200
observed content-type: text/html; charset=utf-8
observed shape: HTML table of latest regulated information with issuer, document title, document type, received timestamp, and static document file id
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
CERI is described as the central register/database of regulated information submitted by issuers of securities admitted to trading on a regulated market.
The search surface lists current issuer regulated information such as annual financial reports, managers' transactions, bondholder notices, general meeting results, and other issuer announcements.
The first integration uses a bounded HTML parser against the official CERI latest-information table and derives document links using the site's public static data link convention.
This is issuer disclosure content, not central-bank policy, macro, or supervisory news content.
```

Implementation status:

```text
Manual source sk_ceri_regulated_information exists with active=false and candidate_status=manual_staging_only.
The source uses parser_key=ceri_regulated_information_html_v1 against the official CERI search table.
Fixture source_payloads/sk_ceri_regulated_information.html captures the bounded public HTML shape.
Local live parser smoke returned HTTP 200 text/html and parsed the latest regulated-information rows directly from the live response.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=10092, records_seen=10, records_inserted=10, canonical_items=10, and no fixture fallback.
Date-specific digest responses rendered Slovakia CERI under Central Europe for 2026-05-07, 2026-05-06, 2026-05-05, and 2026-05-04.
Latest public digest visibility remains pending because the 2026-05-09 digest currently contains newer India NSE items.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Candidate T: Estonia OAM Market Announcements

```text
owner: Finantsinspektsioon / Central storage of regulated information
authority class: official Estonia central storage market-announcement register
supporting URL: https://www.fi.ee/en/investment/registers/central-storage-regulated-information
candidate URL: https://oam.fi.ee/en/borsiteated?limit=50&n=1&order=Date&page=0&sort=desc
observed HTTP: 200
observed content-type: text/html; charset=UTF-8
observed shape: HTML table of market announcements with date, issuer, category, title, attachments marker, and view link
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
The Finantsinspektsioon central-storage page links directly to oam.fi.ee as the central storage of regulated information.
It states that issuers can file, store, and disclose regulated information, and that market announcements are published in the register of market announcements.
The market-announcements page exposes an issuer announcement table with listed-company names, categories such as general meetings, dividends, quarterly financial reports, annual financial reports, and corporate actions.
The first integration uses a bounded HTML parser against the official date-sorted market-announcements table rather than treating an HTML page as RSS.
```

Implementation status:

```text
Manual source ee_oam_market_announcements exists with active=false and candidate_status=manual_staging_only.
The source uses parser_key=ee_oam_market_announcements_html_v1 against the official OAM market-announcements table.
Fixture source_payloads/ee_oam_market_announcements.html captures the bounded public HTML shape.
Local live parser smoke returned HTTP 200 text/html and parsed the latest market-announcement rows directly from the live response.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=58985, records_seen=25, records_inserted=25, canonical_items=25, and no fixture fallback.
Date-specific digest responses rendered Estonia OAM under Northern Europe for 2026-05-06, 2026-05-05, and 2026-05-04.
Latest public digest visibility remains pending because the 2026-05-09 digest currently contains newer India NSE items.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Candidate U: Lithuania OAM Regulated Information

```text
owner: Lithuanian OAM / Nasdaq Vilnius regulated-information storage
authority class: official Lithuania OAM / regulated-information repository
candidate URL: https://www.oam.lt/?language=en
observed HTTP: 200
observed content-type: text/html;charset=UTF-8
observed shape: NEF HTML table of regulated-information rows with published timestamp, company, headline, message category, and /view/{id}?lang=en detail link
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
The OAM page states that it is the Officially Appointed Mechanism and official storage for regulated information required under the Lithuanian Law on Securities.
The same page states that users can access regulated information and announcements submitted by Nasdaq Vilnius listed issuers.
The public table exposes issuer/company, headline, message category, publication timestamp, and stable /view/ detail links.
The first integration uses a bounded HTML parser against the official table rather than treating the HTML page as RSS.
```

Implementation status:

```text
Manual source lt_oam_regulated_information exists with active=false and candidate_status=manual_staging_only.
The source uses parser_key=lt_oam_regulated_information_html_v1 against the official OAM regulated-information table.
Fixture source_payloads/lt_oam_regulated_information.html captures the bounded public HTML row shape.
Local fixture parser smoke returned 2 bounded records.
Local live parser smoke returned HTTP 200 text/html, bytes=88404, and parsed 25 regulated-information rows directly from the live response.
First live record: EPSO-G, UAB - Regarding the resignation of the member of the Board of AB Amber Grid Karolis Švaikauskas.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=88403, records_seen=25, records_inserted=25, canonical_items=25, and no fixture fallback.
Date-specific digest responses rendered Lithuania OAM under Northern Europe for 2026-05-07, 2026-05-06, 2026-05-05, and 2026-05-04.
Latest public digest visibility remains pending because the 2026-05-09 digest currently contains newer India NSE items.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Candidate V: Latvia CSRI / ORICGS Regulated Information

```text
owner: Latvia CSRI / ORICGS, referenced by Latvijas Banka issuer disclosure guidance
authority class: official Latvia central storage of regulated information
supporting URL: https://www.bank.lv/darbibas-jomas/uzraudziba/finansu-instrumentu-tirgus/emitents/publiski-atklajama-informacija
candidate URL: https://csri.investinfo.lv/en/?view=csridocuments
legacy URL redirect: https://www.oricgs.lv/ -> https://csri.investinfo.lv/lv/
observed HTTP: 200
observed content-type: text/html; charset=utf-8
observed shape: Joomla HTML table of latest documents with Date Time, Issuer, Version, Language, Title, and csridocumentsdetails id links
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_DIGEST_TOP_N_VISIBILITY_PENDING_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
Latvijas Banka issuer disclosure guidance references ORICGS as the official centralized storage system for public regulated information.
The legacy ORICGS domain redirects to csri.investinfo.lv, which exposes a latest-documents table of issuer regulated-information rows.
The public table includes issuer/company names, document titles, publication timestamps, language/version metadata, and stable detail ids.
The first integration uses a bounded HTML parser against the official latest-documents table rather than treating the HTML page as RSS.
```

Implementation status:

```text
Manual source lv_csri_regulated_information exists with active=false and candidate_status=manual_staging_only.
The source uses parser_key=lv_csri_regulated_information_html_v1 against the official CSRI latest-documents table.
Fixture source_payloads/lv_csri_regulated_information.html captures the bounded public HTML row shape.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=71883, records_seen=20, records_inserted=20, canonical_items=20, and no fixture fallback.
Current digest top-n windows did not include Latvia CSRI rows because existing higher-ranked/diverse items filled the visible digest windows.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Candidate W: Portugal CMVM Portal InfoPrivi JSON

```text
owner: CMVM Portugal
authority class: official national securities regulator / issuer information disclosure portal
supporting URL: https://www.cmvm.pt/PInstitucional/PortalInstitucional?Input_language=en-US
machine-readable URL: https://www.cmvm.pt/PInstitucional/screenservices/PInstitucional/MainFlow/PortalInstitucional/DataActionFetchSectionsInfo
observed HTTP: 200
observed content-type: application/json; charset=utf-8
observed shape: OutSystems JSON data.InfoPrivi.List latest issuer-disclosure rows with Id, Table, Date, Time, Desc, Tipo, and language flag
status: MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_DIGEST_TOP_N_VISIBILITY_PENDING_SCHEDULED_POLLING_DISABLED
```

Why this fits the product:

```text
The CMVM public institutional portal renders an "Inside information and other information" section sourced from the official CMVM disclosure system.
The bounded JSON action returns issuer-company disclosure rows such as management transactions, board-member changes, and material information.
This endpoint is not a central-bank, macro, parliament, or policy-news feed.
The source uses an exact POST JSON endpoint and a JSON parser, not the CMVM HTML root as rss_v1.
```

Implementation status:

```text
Manual source pt_cmvm_portal_info_privi exists with active=false and candidate_status=manual_staging_only.
The source uses parser_key=cmvm_portal_info_privi_json_v1 against the official CMVM portal InfoPrivi latest-disclosure JSON shape.
Fixture source_payloads/pt_cmvm_portal_info_privi.json captures the bounded InfoPrivi.List row shape.
Local parser smoke returned fixture_records=3, live HTTP 200, live_records=3, and first live record with issuer/title/url/published_at/category populated.
Fly staging live poll returned fetch.mode=live, HTTP 200, fetch.bytes=2393, records_seen=3, records_inserted=3, canonical_items=3, and no fixture fallback.
Latest and 2026-05-08 date-specific digest top-n responses did not yet include Portugal CMVM because existing higher-ranked/diverse items filled the current public digest windows.
The endpoint returns a homepage/latest window, not the full CMVM archive; direct document viewer links are generated by a separate encrypted portal action, so canonical record URLs point to the official portal with stable record fragments.
Scheduled polling remains disabled until the broader EU source batch is intentionally promoted.
```

## Candidate X: Prague Stock Exchange Issuer News and Reports

```text
owner: Prague Stock Exchange
authority class: official exchange issuer/news and issuer-report surface
supporting URL: https://www.pse.cz/en/detail/NL0010391108?tab=detail-news
global PSE news URL: https://www.pse.cz/api/news?lang=en&type=pse&page=1&homepage=0&searchKey=&dateFrom=&dateTo=
issuer news URL pattern: https://www.pse.cz/api/news?lang=en&type=&page=1&homepage=0&searchKey=&dateFrom=&dateTo=&isin=NL0010391108
issuer reports URL pattern: https://www.pse.cz/api/file-reports?isin=NL0010391108&order=year-desc&lang=en
issuer report calendar URL pattern: https://www.pse.cz/api/corporation-calendar?isin=NL0010391108&order=date-DESC&lang=en
observed HTTP: 200 for global PSE news, issuer-specific news, issuer-specific file reports, and issuer-specific report calendar
observed shape: JSON data arrays for news; JSON result.data grouped by year for file reports; JSON result.data rows for report calendar
status: ISSUER_NEWS_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS_REPORT_CALENDAR_MANUAL_SOURCE_REGISTERED_LOCAL_SMOKE_PASS_STAGING_PENDING_SCHEDULED_POLLING_DISABLED
```

Why static single-URL registration remains blocked:

```text
The global PSE news endpoint returned 10 records, but rows are broad exchange/index/trading notices and have isin=null, so it is not a clean all-issuer regulated-information poll source.
The issuer news endpoint is bounded and official, but requires an isin parameter; NL0010391108 returned 6 Photon Energy records with id, title, publishedAt, isin, slug, and content.
The issuer file-reports endpoint is bounded and official, but requires an isin parameter; NL0010391108 returned year-grouped PDF records with uuid, label, ref, size, path, and extension, but no publication-date field.
The issuer corporation-calendar endpoint is bounded and official, requires an isin parameter, and returns date/name/ref rows for attached report documents.
The file-reports endpoint without isin returned 404, and with an empty isin returned 500, so it cannot be treated as an all-issuer reports source.
The four official share-market pages returned 63 unique ISIN detail links across Prime, Standard, Start, and Free Market pages.
Issuer-news responses may include PSE rows with isin=null or rows covering multiple comma-separated ISINs, so the parser must strictly retain only rows whose isin list contains the query ISIN.
Direct file-report responses may return year-keyed rows or an empty array, and direct file-report rows still do not have a precise publication timestamp contract.
```

Implementation status:

```text
Do not register a static single-URL PSE source.
Do not register the PSE HTML root or the broad global PSE news endpoint as rss_v1.
The multi-ISIN fan-out contract is recorded in globalpulse_prague_pse_multi_isin_source_design.md.
Manual source cz_pse_issuer_news_multi_isin exists with active=false and candidate_status=manual_staging_only.
Parser pse_multi_isin_issuer_news_json_v1 parses source-specific fan-out JSON generated from official issuer-universe pages and issuer-specific news JSON.
The first implementation slice registered issuer-news-only; the second manual candidate registers report-calendar rows that have attached report refs and date fields.
Manual source cz_pse_issuer_report_calendar_multi_isin exists with active=false and candidate_status=manual_staging_only.
Parser pse_multi_isin_issuer_report_calendar_json_v1 parses source-specific fan-out JSON generated from official issuer-universe pages and issuer-specific corporation-calendar JSON.
Direct file-reports rows remain non-canonical because they lack a publication-date field; only corporation-calendar rows with attached report refs are accepted.
Local parser smoke passed with fixture_records=2 after filtering an isin=null row out of the fixture.
Live aggregate parser smoke passed with universe_count=63, selected_count=10, response_count=10, response_records=10, strict_records=7, and live_records=7.
Fly staging deploy passed with image registry.fly.io/globalpulse-backend-staging:deployment-01KR6DWYNP085R8QQHKN9Q5M2X and release_command success.
Staging source health passed with active=false, candidate_status=manual_staging_only, disable_live_fixture_fallback=true, parser_key=pse_multi_isin_issuer_news_json_v1, and health_status=healthy after manual poll.
Staging live poll passed with fetch.mode=live, fetch.strategy=pse_multi_isin_news_v1, fetch.status_code=200, universe_count=63, selected_issuer_count=10, issuer_request_count=10, records_seen=15, records_inserted=15, canonical_items=15, and fixture fallback=false.
Date-specific digest visibility passed: GET /api/feed/digest/2022-02-25/breaking rendered a PSE CEZ item under eu_central, and GET /api/feed/digest/2021-06-01/breaking rendered two PSE items under eu_central.
Latest digest visibility remains top-n/date-limited because the current latest digest date is 2026-05-09 while PSE live rows are historical 2020-2022 records.
Report-calendar fixture parser smoke passed with fixture_records=4 and the first record Annual Financial Report at 2026-04-28T00:00:00Z.
Report-calendar live aggregate parser smoke passed with universe_count=63, selected_count=10, response_count=10, response_records=65, strict_records=20, and first record Annual Financial Report at 2026-04-27T00:00:00Z.
Report-calendar Fly staging deploy and staging live poll smoke remain pending until this candidate PR is validated and merged.
Alternatively, continue Czech official OAM discovery if a stable machine-readable all-issuer regulated-information endpoint is found.
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
8. Keep Austria OeKB OAM Issuer Info as a proven manual_staging_only official OAM JSON candidate with digest top-n visibility pending.
9. Keep Germany Xetra Frankfurt Newsboard as a proven manual_staging_only exchange-announcement candidate with public latest UI visibility pending.
10. Keep Greece ATHEX issuer announcements and corporate actions as proven manual_staging_only RSS candidates with public latest UI visibility pending.
11. Keep Norway Oslo Bors NewsWeb main market as a proven manual_staging_only API candidate with public latest UI visibility pending.
12. Keep Poland GPW ESPI/EBI company reports as a proven manual_staging_only HTML parser candidate with public latest UI visibility pending.
13. Keep Hungary Budapest Stock Exchange Issuers News as a proven manual_staging_only HTML parser candidate with public latest UI visibility pending.
14. Keep Romania BVB Current Reports as a proven manual_staging_only HTML parser candidate with digest top-n/public latest UI visibility pending.
15. Keep Slovenia OAM / INFO STORAGE as a proven manual_staging_only official RSS candidate with digest top-n/public latest UI visibility pending.
16. Keep Croatia ZSE EHO issuer news and financial reports as proven manual_staging_only official RSS candidates, with financial-report digest visibility passing and issuer-news top-n visibility pending.
17. Keep Slovakia CERI regulated information as a proven manual_staging_only official OAM-style HTML parser candidate with date-specific digest visibility passing and public latest UI visibility pending.
18. Keep Estonia OAM market announcements as a proven manual_staging_only official OAM-style HTML parser candidate with date-specific digest visibility passing and public latest UI visibility pending.
19. Keep Lithuania OAM regulated information as a proven manual_staging_only official OAM-style HTML parser candidate with date-specific digest visibility passing and public latest UI visibility pending.
20. Keep Latvia CSRI / ORICGS regulated information as a proven manual_staging_only official OAM-style HTML parser candidate with digest top-n/public latest UI visibility pending.
21. Keep Portugal CMVM portal InfoPrivi as a proven manual_staging_only bounded latest-disclosure API candidate with digest top-n/public latest UI visibility pending.
22. Keep Prague/PSE issuer news as a proven manual_staging_only source-specific fan-out candidate with date-specific digest visibility passing; keep Prague/PSE issuer report calendar as a manual_staging_only source-specific fan-out candidate pending staging smoke evidence.
23. Keep Germany Company Register capital-market information blocked from source registration until the recorded token-preflight contract proves stable date filtering, ordering, detail URL, parser shape, and staging-network reachability.
24. Only batch-promote scheduled EU polling after the target list, rollback path, source-specific parser risk, and staging live smoke evidence are documented together.
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
AUSTRIA_OEKB_OAM_ISSUERINFO_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
AUSTRIA_OEKB_OAM_ISSUERINFO_DIGEST_TOP_N_VISIBILITY_PENDING
NORWAY_OSLO_BORS_NEWSWEB_MAIN_MARKET_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
NORWAY_OSLO_BORS_NEWSWEB_PUBLIC_LATEST_UI_VISIBILITY_PENDING
POLAND_GPW_ESPI_EBI_COMPANY_REPORTS_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
POLAND_GPW_ESPI_EBI_COMPANY_REPORTS_PUBLIC_LATEST_UI_VISIBILITY_PENDING
HUNGARY_BSE_ISSUERS_NEWS_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
HUNGARY_BSE_ISSUERS_NEWS_PUBLIC_LATEST_UI_VISIBILITY_PENDING
ROMANIA_BVB_CURRENT_REPORTS_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
ROMANIA_BVB_CURRENT_REPORTS_DIGEST_TOP_N_VISIBILITY_PENDING
SLOVENIA_OAM_REGULATED_INFORMATION_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
SLOVENIA_OAM_REGULATED_INFORMATION_DIGEST_TOP_N_VISIBILITY_PENDING
CROATIA_ZSE_EHO_ISSUER_NEWS_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
CROATIA_ZSE_EHO_ISSUER_NEWS_DIGEST_TOP_N_VISIBILITY_PENDING
CROATIA_ZSE_EHO_FINANCIAL_REPORTS_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
CROATIA_ZSE_EHO_FINANCIAL_REPORTS_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
SLOVAKIA_CERI_REGULATED_INFORMATION_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
SLOVAKIA_CERI_REGULATED_INFORMATION_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
SLOVAKIA_CERI_REGULATED_INFORMATION_PUBLIC_LATEST_UI_VISIBILITY_PENDING
ESTONIA_OAM_MARKET_ANNOUNCEMENTS_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
ESTONIA_OAM_MARKET_ANNOUNCEMENTS_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
ESTONIA_OAM_MARKET_ANNOUNCEMENTS_PUBLIC_LATEST_UI_VISIBILITY_PENDING
LITHUANIA_OAM_REGULATED_INFORMATION_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
LITHUANIA_OAM_REGULATED_INFORMATION_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
LITHUANIA_OAM_REGULATED_INFORMATION_PUBLIC_LATEST_UI_VISIBILITY_PENDING
LATVIA_CSRI_REGULATED_INFORMATION_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
LATVIA_CSRI_REGULATED_INFORMATION_DIGEST_TOP_N_VISIBILITY_PENDING
PORTUGAL_CMVM_PORTAL_INFOPRIVI_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
PORTUGAL_CMVM_PORTAL_INFOPRIVI_DIGEST_TOP_N_VISIBILITY_PENDING
PRAGUE_PSE_ISSUER_NEWS_MULTI_ISIN_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
PRAGUE_PSE_ISSUER_NEWS_MULTI_ISIN_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
PRAGUE_PSE_ISSUER_REPORT_CALENDAR_MULTI_ISIN_MANUAL_SOURCE_REGISTERED_LOCAL_SMOKE_PASS
GERMANY_COMPANY_REGISTER_CAPITAL_MARKET_TOKENIZED_SEARCH_CONFIRMED_STATIC_SOURCE_BLOCKED
GERMANY_COMPANY_REGISTER_TOKEN_PREFLIGHT_FETCH_CONTRACT_RECORDED_SOURCE_REGISTRATION_BLOCKED
EURONEXT_COMPANY_PRESS_RELEASES_PUBLIC_HTML_SURFACE_FOUND
BORSA_ITALIANA_POINTS_TO_CONSOB_AUTHORIZED_STORAGE_SYSTEMS
ESMA_OAM_DIRECTORY_ACCEPTED_AS_AUTHORITY_MAP_NOT_POLL_SOURCE
EU_NEXT_IMPLEMENTATION_STEP_PSE_REPORT_CALENDAR_STAGING_DEPLOY_AND_LIVE_SMOKE
EU_SCHEDULED_LIVE_POLLING_BLOCKED
```
