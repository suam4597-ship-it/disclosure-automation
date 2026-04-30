# JP EDINET fallback preflight

This document defines the fallback path if TDnet / JPX cannot produce a deterministic public sample for JP contract-freeze.

This is docs-only. It does not implement EDINET and does not add sample YAML, fixtures, tests, ops runner, or dedupe SQL.

## Current status

- TDnet / JPX remains the preferred JP first-source candidate.
- TDnet contract-freeze is still blocked on one official row-level sample.
- EDINET is the backup official-regulatory candidate.
- EDINET must become a separate contract if promoted.

## Locked baseline

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

## Promotion rule

Promote EDINET only if both TDnet-family capture paths fail:

1. Company Announcements Disclosure Service current row
2. JPX Listed Company Search historical timely disclosure row

Do not promote EDINET merely because it is easier to access by API. The original JP first-source goal is timely disclosure, and TDnet remains the better semantic fit for that lane.

## Candidate EDINET source contract

```text
source_key candidate: jp_edinet_statutory_report
adapter_key candidate: jp_edinet_statutory_report_v1
display_name candidate: Japan EDINET Statutory Reports
region_code: jp
source_type candidate: api
source_class: regulatory_filing_feed
source_tier candidate: official_regulatory_storage
operator/source owner: Financial Services Agency
source platform: EDINET
```

## Candidate first family

Preferred EDINET fallback family:

```text
event_family candidate: statutory_report_update
canonical_event_type candidate: periodic_report
```

Alternative if existing taxonomy requires a different name:

```text
event_family candidate: periodic_report_update
canonical_event_type candidate: periodic_report
```

Do not map EDINET v0 to TDnet-style `material_information_update` unless the captured EDINET sample actually represents that family.

## Candidate parser strategy

```text
parser_strategy: EDINET document-list API row + primary document metadata/parser
```

Candidate modes:

```text
discovery_mode: edinet_documents_api_fixture
hydrate_mode: edinet_pdf_or_zip_or_json_document
```

## Candidate identity ranking

Use the first available stable field:

1. `docID`
2. `EDINETCode + submitDateTime + docTypeCode`
3. stable API document URL token

Preferred rule:

```text
stable_external_id: EDINET:<docID>
raw_event_key_seed: EDINET:<docID>
duplicate_group_seed: EDINET:<docID>
```

Do not use filer name or title text as identity.

## Candidate cursor ranking

Preferred cursor:

```text
cursor_key: latest_submit_datetime_and_doc_id_seen
cursor_value: <YYYY-MM-DDTHH:MM:SS+09:00>|<docID>
```

Fallback if only date is available:

```text
cursor_key: latest_submit_date_and_doc_id_seen
cursor_value: <YYYY-MM-DD>|<docID>
```

Date-only cursor is acceptable only for one isolated fixture item and only if `docID` is stable.

## Candidate raw-document identities

### Discovery row

```text
raw_document_external_id: EDINET:<docID>:document-list-row
document_identity: EDINET:<docID>:document-list-row
document_role: discovery_metadata
mime_type: application/json
```

### Primary regulatory document

```text
raw_document_external_id: EDINET:<docID>:primary-document:<document_format>
document_identity: EDINET:<docID>:primary-document:<document_format>
document_role: primary_regulatory_disclosure
mime_type: application/pdf or application/zip or application/json
```

Use the actual captured response format.

## Minimum raw-document set

Preferred v0 minimum:

1. one EDINET document-list JSON row
2. one primary document payload or text representation

Do not implement multiple EDINET document types in the same v0 contract.

## Required EDINET sample fields

A freeze-ready EDINET sample must record:

```text
sample filer / issuer
sample EDINET code
sample securities code if available
sample docID
sample document type / docTypeCode
sample document title or description
sample submission date local
sample submission datetime local if available
sample submission datetime UTC
sample API discovery URL or request shape
sample primary document URL or request shape
sample document format
stable_external_id
cursor_key
cursor_value
event_family
canonical_event_type
event_id
raw document external ids
```

## EDINET freeze pass criteria

EDINET passes only if all are true:

- [ ] TDnet Gate 1 failed or was explicitly deferred
- [ ] EDINET official-regulatory source status is recorded
- [ ] one EDINET sample is captured from API/document metadata
- [ ] `docID` or equivalent stable ID is captured
- [ ] cursor can be built without title text
- [ ] one first family is chosen
- [ ] raw-document set is limited to one discovery row plus one primary document
- [ ] local/UTC timestamp rule is explicit
- [ ] later runtime PR can stay one source, one family, one fixture item

## EDINET freeze fail criteria

EDINET should not be frozen if any are true:

- [ ] sample requires broad EDINET ingestion
- [ ] no stable `docID` or equivalent is captured
- [ ] document type cannot be mapped to one family
- [ ] timestamp semantics are ambiguous
- [ ] fixture would need many unrelated documents

## Runtime boundary if EDINET is promoted

A future EDINET runtime PR may create only:

```text
jp_edinet_statutory_report
jp_edinet_statutory_report_v1
one fixture item
one document-list fixture
one primary document fixture
one runtime adapter
one source registry sample
one ops runner
one dedupe SQL file
one runtime idempotency test
one HTTP smoke test
```

Do not include:

- TDnet adapter work
- JPX Listed Company Search adapter work
- broad EDINET pagination
- multiple EDINET document families
- news overlay
- cross-source merge
- broad JP all-disclosures ingestion
- broad CN expansion

## Current recommendation

Keep EDINET as backup only.

Next action should still be one final TDnet/JPX manual or Listed Company Search sample capture. If that fails, this EDINET preflight is ready to become the next source-specific contract-freeze package.
