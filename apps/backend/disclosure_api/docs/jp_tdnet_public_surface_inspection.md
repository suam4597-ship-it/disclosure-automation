# JP TDnet public surface inspection

This document records the public-source inspection for the JP TDnet / JPX first-source candidate.

This is a docs-only preflight. It does not freeze a runtime contract yet and does not add runtime code, sample YAML, fixtures, tests, ops runner, or dedupe SQL.

## Inspection status

- source candidate: `TDnet / JPX Company Announcements Disclosure Service`
- preferred first source key candidate: `jp_tdnet_timely_disclosure`
- preferred adapter key candidate: `jp_tdnet_timely_disclosure_v1`
- source tier candidate: `official_exchange_storage`
- first family candidate: `timely disclosure / material information update`
- contract freeze status: `not frozen`
- reason not frozen: one deterministic public sample still needs row-level capture of identity, cursor, PDF/detail URL, and publication datetime fields

## Guardrails

Do not start JP runtime implementation from this document alone.

Do not add:

- JP runtime adapter
- JP sample YAML
- JP fixtures
- JP tests
- JP ops runner
- JP dedupe SQL
- news overlay
- cross-source merge
- broad JP all-disclosures ingestion
- broad CN expansion

## Current locked baseline

Keep these locked while inspecting JP:

- SEC 6-K
- SEC 8-K
- SEC SC TO-T
- SEC SC 14D-9
- SEC SC 13D/A
- AFM substantial holdings
- UK FCA NSM takeover/scheme
- TW MOPS material information
- CNInfo ownership-change

## Official surfaces inspected

### JPX TDnet overview

Official source page:

```text
https://www.jpx.co.jp/english/equities/listing/disclosure/tdnet/
```

Key findings:

- JPX describes TDnet as the Timely Disclosure Network for fair, prompt, and wide-ranging timely disclosure.
- JPX says listed companies are obliged by the Securities Listing Regulations to use TDnet when enacting timely disclosure of corporate information.
- JPX describes the Company Announcements Disclosure Service as a TSE web service for public inspection of corporate information disclosed via TDnet.
- JPX says information disclosed via TDnet is made available for public inspection on the Company Announcements Disclosure Service simultaneously with media disclosure.
- JPX says documents disclosed via TDnet are available for 31 days on the JPX website, and Listed Company Search allows browsing of timely disclosure information from the past ten years.
- JPX says the Company Announcements Disclosure Service displays timely disclosure information, disclosure date/time, listed exchange(s), company code, company name, and disclosure title.

Implication:

TDnet / JPX is official-exchange enough for the first JP source candidate.

### JPX Company Announcements Service, English page

Official source page:

```text
https://www.jpx.co.jp/english/listing/disclosure/
```

Key findings:

- TSE provides an English Company Announcements Service to make English-language timely disclosure information easier for overseas investors to access.
- English coverage may not fully cover Japanese timely disclosure information.
- The page directs Japanese timely-disclosure inspection to the Company Announcements Disclosure Service.
- Timely disclosure information is available for 31 days.
- For older timely disclosure and other English materials, the page points users to Listed Company Search and TDnet Database Service.
- The page documents display rules for updated, summary, delayed, corrected, and deleted documents.

Implication:

The English service is useful as a secondary observation surface, but the Japanese Company Announcements Disclosure Service is the preferred public discovery target for first JP v0.

### Company Announcements Disclosure Service, Japanese public service

Official public discovery URL:

```text
https://www.release.tdnet.info/inbs/I_main_00.html
```

Observed page-level fields from public access:

- service title: `適時開示情報閲覧サービス / Company Announcements Disclosure Service`
- public date selector with recent disclosure dates
- search entry point: `適時開示情報検索へ`
- last updated timestamp shown on the page

Open item:

The public landing page confirms an official public discovery surface, but the contract cannot be frozen until one row-level sample is captured with:

- disclosure date and time
- exchange/listed market field, if visible
- company code
- company name
- title
- detail link or PDF link
- stable PDF URL token, disclosure number, disclosure history number, or equivalent artefact id

### JPX Listed Company Search

Official source page:

```text
https://www.jpx.co.jp/english/listing/co-search/
```

Key findings:

- JPX describes Listed Company Search as providing information on TSE listed companies, including timely disclosure and filing information.
- The page says Listed Company Search is updated around 1:00 a.m. every day.
- The page directs users to Company Announcements Service for the latest timely disclosure information.

Implication:

Listed Company Search is a strong historical-sample fallback because JPX says timely disclosure information from the past ten years is available there, but it is not the freshest public discovery surface.

### Paid TDnet API / Database / Snowflake surfaces

Official source pages:

```text
https://www.jpx.co.jp/english/markets/paid-info-listing/tdnet/02.html
https://www.jpx.co.jp/english/markets/paid-info-listing/tdnet/03.html
https://www.jpx.co.jp/english/markets/paid-info-listing/tdnet/04.html
```

Useful identity/cursor evidence from official paid-service docs:

- TDnet API index information includes security code, stock abbreviation, date of disclosure, time of disclosure, handling attributes, disclosure number, disclosure history number, title, public item code, and file existence flag.
- TDnet Database Service index information includes disclosure date, disclosure time, issue code, new securities code, title, exchange code, material category, disclosed file category, and disclosed file size.
- TDnet on Snowflake index information includes security code, stock abbreviation, date of disclosure, time of disclosure, title, and public item code.

Implication:

Paid surfaces confirm that strong TDnet identity/cursor fields exist in the broader TDnet data model. However, first open-source runtime v0 must not depend on paid access unless the project explicitly chooses a paid-source adapter later.

## EDINET backup surface

Official/API catalog pages:

```text
https://api-catalog.e-gov.go.jp/info/en/apicatalog/view/33
https://disclosure2dl.edinet-fsa.go.jp/guide/static/disclosure/WZEK0110.html
```

Key findings:

- e-Gov API catalog identifies EDINET API as provided by the Financial Services Agency.
- The catalog describes EDINET as the electronic disclosure system for disclosure documents such as securities reports under the Financial Instruments and Exchange Act.
- The catalog lists response formats as JSON, ZIP, and PDF and API provision form as REST.
- EDINET operation guide pages expose EDINET API related documents.

Implication:

EDINET remains the backup official-regulatory source candidate for periodic/statutory reports. It is less suitable than TDnet for the first as-it-happens timely-disclosure lane.

## Public sample capture requirements

Before contract freeze, capture exactly one deterministic public sample from one of these paths:

1. Company Announcements Disclosure Service latest rows, if row-level fields and PDF token are visible.
2. Listed Company Search historical row, if it exposes enough metadata and a stable document artefact.
3. EDINET document list only if TDnet public surfaces cannot satisfy identity/cursor requirements.

The sample capture must record:

- issuer / company name
- security code
- disclosure title
- disclosure source category or material category, if visible
- publication datetime local, with JST offset
- publication datetime UTC
- detail URL, if any
- attachment/PDF URL, if any
- stable disclosure number, history number, document id, or PDF token
- document format / MIME type

## Preliminary conclusion

TDnet / JPX remains the preferred JP first-source candidate because it is official-exchange storage for timely disclosure and the JPX public documentation describes strong row-level fields.

Do not freeze runtime yet. The next step is a deterministic sample capture pass against `https://www.release.tdnet.info/inbs/I_main_00.html` and/or Listed Company Search.
