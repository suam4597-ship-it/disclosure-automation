# JP EDINET candidate contract v0

This document defines a candidate EDINET fallback contract that may be promoted only if TDnet / JPX cannot produce a freeze-ready public sample.

This is docs-only. It is not a runtime implementation and it does not add sample YAML, fixtures, tests, ops runner, or dedupe SQL.

## Freeze status

- source contract: `candidate only`
- first family: `candidate only`
- deterministic sample: `not captured`
- runtime implementation: `not started`
- promotion rule: only after TDnet manual or JPX Listed Company Search capture fails or is explicitly deferred

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

## Candidate source

```text
source_key: jp_edinet_statutory_report
display_name: Japan EDINET Statutory Reports
region_code: jp
source_type: api
source_class: regulatory_filing_feed
source_tier: official_regulatory_storage
operator/source owner: Financial Services Agency
source platform: EDINET
```

## Candidate source authority rationale

EDINET is the Financial Services Agency operated electronic disclosure system for statutory disclosure documents such as securities reports under the Financial Instruments and Exchange Act.

The Japanese government API catalog identifies EDINET API as an API provided by the Financial Services Agency and describes JSON, ZIP, and PDF response formats using a REST API style.

## Candidate first family

Preferred candidate:

```text
event_family: statutory_report_update
canonical_event_type: periodic_report
```

Alternative candidate if the existing canonical taxonomy requires this naming:

```text
event_family: periodic_report_update
canonical_event_type: periodic_report
```

Do not use TDnet-style `material_information_update` for EDINET unless the captured EDINET sample explicitly supports it.

## Candidate adapter

```text
adapter_key: jp_edinet_statutory_report_v1
parser_strategy: EDINET document-list API row + primary document parser
discovery_mode: edinet_documents_api_fixture
hydrate_mode: edinet_pdf_or_zip_or_json_document
```

## Candidate stable external identity

Preferred rule:

```text
stable_external_id: EDINET:<docID>
raw_event_key_seed: EDINET:<docID>
duplicate_group_seed: EDINET:<docID>
```

Fallback rule if `docID` is unavailable but equivalent official metadata is captured:

```text
stable_external_id: EDINET:<EDINETCode>:<submitDateTime>:<docTypeCode>
```

Do not use filer name, issuer name, or document title as identity.

## Candidate cursor

Preferred cursor:

```text
cursor_key: latest_submit_datetime_and_doc_id_seen
cursor_value: <YYYY-MM-DDTHH:MM:SS+09:00>|<docID>
```

Fallback cursor if the API list exposes date but not precise datetime:

```text
cursor_key: latest_submit_date_and_doc_id_seen
cursor_value: <YYYY-MM-DD>|<docID>
```

Date-only cursor is acceptable for v0 only if `docID` is stable and the first implementation remains one isolated fixture item.

## Candidate raw document identities

### Document-list row

```text
raw_document_external_id: EDINET:<docID>:document-list-row
document_identity: EDINET:<docID>:document-list-row
document_role: discovery_metadata
mime_type: application/json
```

### Primary document

```text
raw_document_external_id: EDINET:<docID>:primary-document:<document_format>
document_identity: EDINET:<docID>:primary-document:<document_format>
document_role: primary_regulatory_disclosure
mime_type: <captured_mime_type>
```

## Candidate minimum raw-document set

Preferred v0 minimum:

1. one EDINET document-list JSON row
2. one primary disclosure document or text representation

Do not require multiple document attachments for the first lock.

## Candidate normalized event id

Preferred shape:

```text
jp.edinet.<edinet_code_or_security_code>.<YYYYMMDD>.<canonical_event_type>.<event_family>.<docID>
```

Use submission date in Japan local time for `<YYYYMMDD>`.

## Candidate timestamp rule

Interpret EDINET submission timestamps as Japan local time unless API evidence says otherwise.

Preferred values:

```text
published_at_local: <submit_datetime>+09:00
published_at_utc: <published_at_local converted to UTC>
filing_date_local: <YYYY-MM-DD in JST>
```

If only submission date is exposed, record that date-only time is a v0 fixture convention, not a live ordering guarantee.

## Candidate source-appropriate canonical item source names

```text
official storage name: EDINET / Financial Services Agency
official source name: EDINET disclosure document API
discovery source name: EDINET document-list API row
primary disclosure document source name: EDINET primary disclosure document
```

## Values still required before freeze

```text
sample filer / issuer: TODO
sample EDINET code: TODO
sample securities code: TODO or not available
sample docID: TODO
sample document type / docTypeCode: TODO
sample document title or description: TODO
sample submission date local: TODO
sample submission datetime local: TODO or date-only convention
sample submission datetime UTC: TODO
sample API discovery request shape: TODO
sample primary document request shape: TODO
sample document format: TODO
stable_external_id: TODO
cursor_key: TODO
cursor_value: TODO
event_family: TODO
canonical_event_type: TODO
event_id: TODO
raw_document_external_id values: TODO
```

## Freeze blocker

This candidate contract must not be promoted until one EDINET API sample is captured and the input sheet records concrete values for all required fields.

If TDnet manual capture succeeds first, do not promote EDINET.
