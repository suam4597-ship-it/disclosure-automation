# JP TDnet manual sample capture runbook

Use this runbook when automated fetch cannot capture a deterministic TDnet row directly.

This runbook is docs-only. Do not add runtime code, sample YAML, fixtures, tests, ops runner, or dedupe SQL while following it.

## Objective

Capture exactly one official TDnet / JPX public sample that can satisfy JP contract-freeze gates.

The capture must produce enough concrete values to fill:

```text
apps/backend/disclosure_api/docs/jp_tdnet_contract_freeze_input_sheet.md
```

## Current decision state

```text
source candidate: TDnet / JPX Company Announcements Disclosure Service
source_key candidate: jp_tdnet_timely_disclosure
adapter_key candidate: jp_tdnet_timely_disclosure_v1
freeze status: not frozen
runtime status: not started
```

## Guardrails

Do not capture broad TDnet batches.

Do not mix multiple JP families.

Do not freeze a sample whose identity or cursor requires:

```text
title-only matching
fuzzy title matching
company code + title only
publication datetime + title only
```

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

## Capture path A: current Company Announcements Disclosure Service

Open:

```text
https://www.release.tdnet.info/inbs/I_main_00.html
```

Then:

1. Choose the latest available disclosure date from the public service.
2. Open the disclosure list for that date.
3. Choose one high-signal row with a linked official document.
4. Prefer a row with clear category/family semantics, such as:
   - material/timely disclosure update
   - M&A / restructuring / major asset transaction
   - tender-offer / takeover update
   - ownership/shareholding update
5. Save the row metadata.
6. Open the linked PDF/document.
7. Save the PDF/document URL and visible token.
8. Save the PDF text or enough excerpted metadata to build a future fixture.

## Capture path B: JPX Listed Company Search historical row

Use this path if the current 31-day TDnet service cannot provide a deterministic sample.

Open JPX Listed Company Search from JPX official pages and locate a historical timely disclosure row.

Capture the same fields as path A.

Use this path only if it gives better reproducibility than the latest 31-day page.

## Capture path C: EDINET fallback

Use EDINET only if TDnet paths A and B fail identity/cursor requirements.

EDINET is an official-regulatory fallback and should be treated as a separate source/family decision, not as TDnet.

Do not mix EDINET with TDnet in the same frozen contract.

## Required row fields

Record exactly:

```text
issuer/company name: TODO
security code: TODO
exchange/market: TODO
disclosure title: TODO
source category/material category: TODO
disclosure date local: TODO
disclosure time local: TODO
publication datetime local: TODO
publication datetime UTC: TODO
discovery URL: TODO
detail URL: TODO
PDF/document URL: TODO
PDF/document token: TODO
document MIME type: TODO
```

## Required identity fields

Look for these fields in this order:

```text
disclosure number
disclosure history number
public item code
PDF/document token
security code + publication datetime + sequence/token
```

Fill:

```text
visible stable id field name: TODO
visible stable id field value: TODO
stable_external_id candidate: TODO
```

## Required cursor fields

Choose one:

```text
latest_disclosure_datetime_and_disclosure_number_seen
latest_disclosure_datetime_and_disclosure_number_history_seen
latest_disclosure_datetime_and_public_item_code_seen
latest_disclosure_datetime_and_pdf_token_seen
```

Fill:

```text
cursor_key candidate: TODO
cursor_value candidate: TODO
```

## Timestamp conversion

TDnet publication datetime should be interpreted as Japan Standard Time.

Use:

```text
published_at_local: <YYYY-MM-DDTHH:MM:SS+09:00>
published_at_utc: <published_at_local converted to UTC>
filing_date_local: <YYYY-MM-DD>
```

Example conversion shape only:

```text
published_at_local: 2026-04-30T15:30:00+09:00
published_at_utc: 2026-04-30T06:30:00.000000Z
filing_date_local: 2026-04-30
```

## Raw document capture

Preferred minimum set:

```text
1. discovery row metadata fixture
2. primary disclosure document fixture
```

Add a detail page only if required.

Fill:

```text
raw_document_1_external_id: TODO
raw_document_1_role: discovery_metadata
raw_document_1_mime_type: application/json

raw_document_2_external_id: TODO
raw_document_2_role: primary_regulatory_disclosure
raw_document_2_mime_type: TODO

raw_document_3_external_id: TODO or not required
raw_document_3_role: TODO or not required
raw_document_3_mime_type: TODO or not required
```

## Family mapping checklist

Choose exactly one family for the captured sample.

Preferred if broad timely disclosure:

```text
event_family: material_information_update
canonical_event_type: material_information_update
```

Use only if taxonomy accepts the broad mapping.

Use narrower fallback if the sample clearly supports it:

```text
event_family: major_asset_transaction_update
canonical_event_type: major_investment_or_asset_sale
```

Other high-signal mappings may be chosen only if the captured row makes the family cleaner than broad material information.

## Freeze pass criteria

The sample passes only if all are true:

- [ ] official TDnet or JPX row captured
- [ ] issuer/company name captured
- [ ] security code captured
- [ ] title captured from official row or document
- [ ] publication datetime captured with time precision
- [ ] UTC conversion is deterministic
- [ ] PDF/document URL captured
- [ ] stable identity field or token captured
- [ ] cursor can be built without title text
- [ ] one family is clearly selected
- [ ] raw-document set is limited to two or three documents
- [ ] future runtime PR can stay one source, one family, one fixture item

## Freeze fail criteria

The sample fails if any are true:

- [ ] no official row can be captured
- [ ] only title text distinguishes the item
- [ ] publication time is missing and no stable sequence/token exists
- [ ] PDF/document URL is unstable or unavailable
- [ ] category/family is too broad for one fixture item
- [ ] sample requires broad TDnet pagination to reproduce

## After capture

If the sample passes:

1. fill `jp_tdnet_contract_freeze_input_sheet.md`
2. create a true contract-freeze close-out document
3. name the exact stable external id, cursor, event id, family, canonical type, and raw-document identities
4. only then start a later runtime PR

If the sample fails:

1. document the no-go reason
2. try Listed Company Search once
3. if still blocked, evaluate EDINET as a separate fallback contract
