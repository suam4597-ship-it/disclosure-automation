# JP TDnet candidate contract v0

This document defines the candidate JP TDnet contract that should be frozen only after one deterministic public sample is captured.

This is not a final frozen contract.

## Freeze status

- source contract: `candidate only`
- first family: `candidate only`
- first deterministic sample: `not captured`
- runtime implementation: `not started`
- next decision: sample capture, then contract-freeze close-out or fallback decision

## Candidate source

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

## Candidate source authority rationale

TDnet is an official TSE/JPX timely-disclosure workflow. JPX describes TDnet as the Timely Disclosure Network and says listed companies are obliged by Securities Listing Regulations to use TDnet when enacting timely disclosure of corporate information.

JPX also describes the Company Announcements Disclosure Service as a TSE-created public web service for information disclosed via TDnet.

## Candidate adapter

```text
adapter_key: jp_tdnet_timely_disclosure_v1
parser_strategy: TDnet announcement row + primary disclosure document parser
discovery_mode: tdnet_company_announcements_public_row_fixture
hydrate_mode: tdnet_pdf_or_detail_attachment
```

Do not implement this adapter until the candidate values below are replaced by frozen values.

## Candidate first family

Preferred candidate:

```text
event_family: material_information_update
canonical_event_type: material_information_update
```

Fallback candidate if taxonomy or sample semantics require a narrower mapping:

```text
event_family: major_asset_transaction_update
canonical_event_type: major_investment_or_asset_sale
```

The fallback should be used only if the captured TDnet row is clearly an M&A, restructuring, major investment, or major asset transaction disclosure and maps better to an existing canonical event type.

## Candidate cursor

Preferred cursor key:

```text
latest_disclosure_datetime_and_disclosure_number_seen
```

Preferred cursor value shape:

```text
<YYYY-MM-DDTHH:MM:SS+09:00>|<disclosure_number>
```

Acceptable alternatives, in order:

```text
latest_disclosure_datetime_and_disclosure_number_history_seen
<YYYY-MM-DDTHH:MM:SS+09:00>|<disclosure_number>|<disclosure_history_number>

latest_disclosure_datetime_and_public_item_code_seen
<YYYY-MM-DDTHH:MM:SS+09:00>|<public_item_code>

latest_disclosure_datetime_and_pdf_token_seen
<YYYY-MM-DDTHH:MM:SS+09:00>|<pdf_url_token>
```

Do not freeze a title-only cursor.

## Candidate stable external identity

Preferred identity rule:

```text
TDNET:<disclosure_number>
```

Preferred sample value shape:

```text
TDNET:<captured_disclosure_number>
```

Acceptable alternatives, in order:

```text
TDNET:<disclosure_number>:<disclosure_history_number>
TDNET:<public_item_code>:<file_token>
TDNET:<pdf_url_token>
TDNET:<security_code>:<YYYYMMDDHHMMSS_JST>:<sequence_or_token>
```

Do not freeze title-only identity.

## Candidate raw event key and duplicate group seed

Preferred rule:

```text
raw_event_key_seed: <stable_external_id>
duplicate_group_seed: <stable_external_id>
```

If the captured public surface exposes only a PDF token, use:

```text
raw_event_key_seed: TDNET:<pdf_url_token>
duplicate_group_seed: TDNET:<pdf_url_token>
```

## Candidate raw document identities

### Discovery row

```text
raw_document_external_id: <stable_external_id>:discovery-row
document_identity: <stable_external_id>:discovery-row
document_role: discovery_metadata
mime_type: application/json
```

### Detail page, only if required

```text
raw_document_external_id: <stable_external_id>:detail-page
document_identity: <stable_external_id>:detail-page
document_role: source_detail_page
mime_type: text/html
```

### Primary disclosure document

```text
raw_document_external_id: <stable_external_id>:pdf:<document_token>
document_identity: <stable_external_id>:pdf:<document_token>
document_role: primary_regulatory_disclosure
mime_type: application/pdf
```

If the primary disclosure is not PDF, replace `pdf` and MIME type with the actual captured document type.

## Candidate minimum raw-document set

Preferred v0 minimum:

1. one discovery JSON row representing the TDnet public row fields
2. one primary disclosure document fixture, usually PDF text extracted from the official attachment

Add a detail-page raw document only if the PDF/document URL or stable token cannot be represented from the discovery row alone.

## Candidate normalized event id

Preferred event id shape:

```text
jp.tdnet.<security_code>.<YYYYMMDD>.<canonical_event_type>.<event_family>.<stable_token>
```

Where:

- `<security_code>` is the captured company/security code
- `<YYYYMMDD>` is publication date in JST
- `<stable_token>` is disclosure number, history number, public item code, PDF token, or equivalent stable artefact id

## Candidate timestamp rule

TDnet publication datetime is interpreted as Japan Standard Time.

```text
published_at_local: <captured_disclosure_datetime>+09:00
published_at_utc: <published_at_local converted to UTC>
filing_date_local: <YYYY-MM-DD in JST>
```

If only date is visible, do not freeze TDnet v0 unless another stable sequence/id makes ordering deterministic enough for one isolated fixture item.

## Candidate source-appropriate canonical item source names

```text
official storage name: JPX / Tokyo Stock Exchange TDnet
official source name: TDnet Company Announcements Disclosure Service
discovery source name: TDnet public announcement row
primary disclosure document source name: TDnet disclosed document attachment
```

## Values that must be replaced before freeze

```text
sample issuer: TODO
sample security code: TODO
sample title: TODO
sample category/material type: TODO
sample publication datetime local: TODO
sample publication datetime UTC: TODO
sample detail URL: TODO
sample attachment URL: TODO
sample stable_external_id: TODO
sample cursor value: TODO
sample event_id: TODO
sample raw_document_external_id values: TODO
```

## Freeze blocker

This candidate contract must not be promoted to frozen until the public sample capture input sheet is filled and the close-out document records concrete values for all TODO fields above.
