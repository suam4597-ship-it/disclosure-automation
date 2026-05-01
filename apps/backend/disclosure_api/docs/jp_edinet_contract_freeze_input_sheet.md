# JP EDINET contract-freeze input sheet

This sheet records the single EDINET document-list sample used to freeze the first EDINET runtime candidate contract.

This sheet is docs-only. Filling it does not start runtime implementation.

## Scope

```text
source candidate: EDINET
source_key candidate: jp_edinet_statutory_report
adapter_key candidate: jp_edinet_statutory_report_v1
source_tier candidate: official_regulatory_storage
first family candidate: statutory_report_update
```

## Promotion precondition

- [x] TDnet timely disclosure is already locked as the first JP exchange-disclosure lane
- [x] EDINET is being evaluated as a separate official-regulatory lane, not mixed with TDnet
- [x] EDINET API document-list response was captured without sharing the API key

## EDINET source evidence

Record the source/API evidence used for this sample:

```text
official/API catalog URL: EDINET API / FSA official API surface
EDINET API guide URL: EDINET API v2 documents endpoint
API version, if visible: v2
discovery endpoint/request shape: https://api.edinet-fsa.go.jp/api/v2/documents.json?date=2026-04-30&type=2&Subscription-Key=<redacted>
primary document endpoint/request shape: https://api.edinet-fsa.go.jp/api/v2/documents/S100XZXO?type=1&Subscription-Key=<redacted>
```

## API response metadata

```text
metadata.parameter.date: 2026-04-30
metadata.parameter.type: 2
metadata.resultset.count: 384
metadata.processDateTime: 2026-05-01 00:03
parsed results count: 384
metadata.status: 200
metadata.message: OK
```

## Sample metadata

Captured one EDINET document-list row.

```text
sample filer / issuer: 野村アセットマネジメント株式会社
sample EDINET code: E12460
sample securities code: null / not available
sample docID: S100XZXO
sample seqNumber: 1
sample document type / docTypeCode: 180
sample document title or description: 臨時報告書（内国特定有価証券）
sample submission date local: 2026-04-30
sample submission datetime local: 2026-04-30T09:00:00+09:00
sample submission datetime UTC: 2026-04-30T00:00:00.000000Z
sample xbrlFlag: 1
sample pdfFlag: 1
sample csvFlag: 1
sample document format: type=1 primary document request shape; primary payload/text not yet captured
sample primary document request shape: https://api.edinet-fsa.go.jp/api/v2/documents/S100XZXO?type=1&Subscription-Key=<redacted>
```

## Stable identity decision

Chosen identity:

```text
stable_external_id: EDINET:S100XZXO
raw_event_key_seed: EDINET:S100XZXO
duplicate_group_seed: EDINET:S100XZXO
```

This identity uses official `docID` and does not require filer name or document title.

## Cursor decision

Chosen cursor:

```text
cursor_key: latest_submit_datetime_and_doc_id_seen
cursor_value: 2026-04-30T09:00:00+09:00|S100XZXO
```

The cursor uses official submission datetime plus docID and does not use title text.

## Family decision

Chosen family:

```text
event_family: statutory_report_update
canonical_event_type: extraordinary_report
```

Rationale:

- document description is `臨時報告書（内国特定有価証券）`
- this is a statutory EDINET filing, but not a periodic securities report sample
- use `extraordinary_report` rather than `periodic_report` for this v0 sample

## Raw document set

Preferred v0 set:

```text
raw_document_1_external_id: EDINET:S100XZXO:document-list-row
raw_document_1_role: discovery_metadata
raw_document_1_mime_type: application/json

raw_document_2_external_id: EDINET:S100XZXO:primary-document:type1
raw_document_2_role: primary_regulatory_disclosure
raw_document_2_mime_type: application/zip or captured EDINET type=1 response MIME type
```

Chosen raw documents for contract-freeze:

```text
raw_document_1_external_id: EDINET:S100XZXO:document-list-row
raw_document_1_role: discovery_metadata
raw_document_1_mime_type: application/json

raw_document_2_external_id: EDINET:S100XZXO:primary-document:type1
raw_document_2_role: primary_regulatory_disclosure
raw_document_2_mime_type: TODO after type=1 payload/header capture
```

## Expected normalized values

```text
source_key: jp_edinet_statutory_report
adapter_key: jp_edinet_statutory_report_v1
region_code: jp
source_tier: official_regulatory_storage
stable_external_id: EDINET:S100XZXO
cursor_key: latest_submit_datetime_and_doc_id_seen
cursor_value: 2026-04-30T09:00:00+09:00|S100XZXO
event_id: jp.edinet.E12460.20260430.extraordinary_report.statutory_report_update.S100XZXO
event_family: statutory_report_update
canonical_event_type: extraordinary_report
published_at_local: 2026-04-30T09:00:00+09:00
published_at_utc: 2026-04-30T00:00:00.000000Z
filing_date_local: 2026-04-30
```

## Freeze pass criteria

- [x] EDINET official API document-list row captured
- [x] `docID` captured
- [x] cursor does not use title text
- [x] one family selected
- [x] timestamp convention is explicit
- [x] future runtime PR can stay one source, one family, one fixture item
- [ ] primary document payload/text or response header fixture still required before runtime implementation

## Freeze decision

```text
freeze contract; runtime blocked until primary document payload/text or response headers are captured
```
