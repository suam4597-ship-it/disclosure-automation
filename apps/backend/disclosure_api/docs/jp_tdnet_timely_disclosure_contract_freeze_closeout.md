# JP TDnet timely disclosure contract-freeze close-out

This document freezes the first JP TDnet implementation contract after the JP discovery, TDnet preflight, capture no-go, source-decision, and user-provided official row-level sample capture.

This is still a docs-only close-out. It does not add runtime code, sample YAML, fixtures, tests, ops runner, or dedupe SQL.

## Freeze status

- source contract: frozen
- first family: frozen
- first deterministic sample: frozen
- runtime implementation: not started
- next PR: isolated runtime implementation

## Current locked baseline

Keep these locked:

- SEC 6-K
- SEC 8-K
- SEC SC TO-T
- SEC SC 14D-9
- SEC SC 13D/A
- AFM substantial holdings
- UK FCA NSM takeover/scheme
- TW MOPS material information
- CNInfo ownership-change

## Chosen source

```text
source_key: jp_tdnet_timely_disclosure
display_name: Japan TDnet Timely Disclosure
region_code: jp
source_type: public_web
source_class: regulatory_filing_feed
source_tier: official_exchange_storage
operator/source owner: Tokyo Stock Exchange / Japan Exchange Group
source platform: TDnet / Company Announcements Disclosure Service
```

## Source authority rationale

JPX describes TDnet as the Timely Disclosure Network used for fair, prompt, and wide-ranging timely disclosure.

JPX says listed companies are obliged by the Securities Listing Regulations to use TDnet when enacting timely disclosure of corporate information.

JPX describes the Company Announcements Disclosure Service as a TSE-created public service that displays timely disclosure information with disclosure date/time, exchange, company code, company name, and title.

## Chosen first family

```text
event_family: material_information_update
canonical_event_type: material_information_update
```

## Why this family won

This sample comes from the TDnet current-list timely disclosure surface.

The official TDnet row does not expose a category/material-type column for this item, so the v0 contract deliberately avoids inferred title/category classification.

A future enrichment layer may derive governance or shareholder-meeting semantics from the PDF title/content, but the isolated first runtime slice should lock the official source mechanics first:

- one TDnet public current-list row
- one PDF attachment
- one stable PDF document token
- one publication datetime
- one broad timely-disclosure event family

## Chosen sample

```text
source_type: TDnet Company Announcements Disclosure Service current row
row_list_url: https://www.release.tdnet.info/inbs/I_list_001_20260430.html
row_date: 2026-04-30
row_display_name: ロート薬
pdf_full_company_name: ロート製薬株式会社
tdnet_raw_row_code: 45270
normalized_security_code: 4527
official_title: 株主提案に関する書面受領のお知らせ
publication_date_time_local: 2026-04-30 19:00 JST
published_at_local: 2026-04-30T19:00:00+09:00
published_at_utc: 2026-04-30T10:00:00.000000Z
attachment_url: https://www.release.tdnet.info/inbs/140120260430515474.pdf
pdf_document_token: 140120260430515474
exchange: 東 / TSE
xbrl: blank / none
update_history: blank / none
source_category: null / unknown
document_date_shown_in_pdf: 2026-04-30
```

## Source fact summary

The PDF confirms:

- full company name: `ロート製薬株式会社`
- securities code: `4527`
- exchange: `東証プライム`
- title: `株主提案に関する書面受領のお知らせ`
- document date: `2026-04-30`
- the company received written shareholder proposals from AVI JAPAN OPPORTUNITY TRUST PLC and LONGCHAMP SICAV for the planned 90th ordinary general meeting of shareholders
- the board opinion will be disclosed after review and deliberation

## Runtime contract

```text
adapter_key: jp_tdnet_timely_disclosure_v1
parser_strategy: TDnet current-list row + TDnet PDF attachment parser
discovery_mode: tdnet_current_list_row_fixture
hydrate_mode: tdnet_pdf_attachment
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
cursor_value: 2026-04-30T19:00:00+09:00|4527|140120260430515474
```

## Raw row code handling

TDnet current-list code and normalized security code must be stored separately.

```text
tdnet_raw_row_code: 45270
normalized_security_code: 4527
```

For this sample, the normalized security code is confirmed by the PDF as `4527`. The TDnet row code `45270` must not be overwritten or lost.

## Category handling

The official TDnet current-list row does not expose a category/material-type field for this sample.

Freeze:

```text
source_category: null
material_category: unknown
```

Do not infer a category from title text in v0.

## Identity rules

```text
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
raw_event_key_seed: TDNET:4527:20260430:1900:140120260430515474
duplicate_group_seed: TDNET:4527:20260430:1900:140120260430515474
canonical_event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
```

Why the identity is frozen this way:

- public disclosure number was not captured
- disclosure history number was blank / not captured
- public item code was not captured
- stable PDF document token was captured from the official row attachment
- official row publication datetime and normalized security code are captured
- identity does not rely on title text

## Raw document identity rules

### Discovery row

```text
raw_document_external_id: TDNET:4527:20260430:1900:140120260430515474:discovery-row
document_identity: TDNET:4527:20260430:1900:140120260430515474:discovery-row
document_role: discovery_metadata
mime_type: application/json
```

### PDF attachment

```text
raw_document_external_id: TDNET:4527:20260430:1900:140120260430515474:pdf:140120260430515474
document_identity: TDNET:4527:20260430:1900:140120260430515474:pdf:140120260430515474
document_role: primary_regulatory_disclosure
mime_type: application/pdf
```

## Minimum raw-document set

Use two raw documents for the v0 isolated lock:

1. one synthetic discovery JSON row derived from the official TDnet row metadata
2. one PDF/text fixture representing the official TDnet PDF attachment

Do not require a separate detail page for v0.

## Source-appropriate canonical item source names

```text
official storage name: JPX / Tokyo Stock Exchange TDnet
official source name: TDnet Company Announcements Disclosure Service
discovery source name: TDnet current-list row
primary disclosure document source name: TDnet PDF attachment
```

## Expected normalized values

```text
source_key: jp_tdnet_timely_disclosure
adapter_key: jp_tdnet_timely_disclosure_v1
region_code: jp
source_tier: official_exchange_storage
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
cursor_value: 2026-04-30T19:00:00+09:00|4527|140120260430515474
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
event_family: material_information_update
canonical_event_type: material_information_update
published_at_local: 2026-04-30T19:00:00+09:00
published_at_utc: 2026-04-30T10:00:00.000000Z
filing_date_local: 2026-04-30
tdnet_raw_row_code: 45270
normalized_security_code: 4527
pdf_document_token: 140120260430515474
source_category: null
material_category: unknown
```

## Later implementation PR guardrail

The next PR may create runtime code only for this one frozen source and one fixture item.

Do not add:

- broad JP all-disclosures ingestion
- JP multiple-family implementation
- EDINET implementation in the same PR
- JPX Listed Company Search adapter
- news overlay
- cross-source merge
- broad CN expansion

## Close-out result

JP TDnet contract-freeze is complete for:

```text
jp_tdnet_timely_disclosure
```

Next step:

```text
JP TDnet timely disclosure isolated runtime implementation PR
```
