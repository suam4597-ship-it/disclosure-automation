# JP EDINET statutory report contract-freeze close-out

This document freezes the first EDINET contract candidate after an official EDINET API document-list sample was captured.

This is docs-only. It does not add EDINET runtime code, fixtures, tests, ops runner, or dedupe SQL.

## Freeze status

```text
source contract: frozen
first sample: document-list row frozen
runtime implementation: blocked until primary document payload/text or response headers are captured
```

## Current locked baseline

Keep these locked:

```text
SEC 6-K
SEC 8-K
SEC SC TO-T
SEC SC 14D-9
SEC SC 13D/A
AFM substantial holdings
UK FCA NSM takeover/scheme
TW MOPS material information
CNInfo ownership-change
JP TDnet timely disclosure
JP TDnet broad timely disclosure
CNInfo broad announcement feed
```

## Chosen source

```text
source_key: jp_edinet_statutory_report
adapter_key: jp_edinet_statutory_report_v1
display_name: Japan EDINET Statutory Reports
region_code: jp
source_type: api
source_class: regulatory_filing_feed
source_tier: official_regulatory_storage
source platform: EDINET
operator/source owner: Financial Services Agency
```

## Captured API response metadata

```text
request_shape: https://api.edinet-fsa.go.jp/api/v2/documents.json?date=2026-04-30&type=2&Subscription-Key=<redacted>
metadata.parameter.date: 2026-04-30
metadata.parameter.type: 2
metadata.resultset.count: 384
metadata.processDateTime: 2026-05-01 00:03
metadata.status: 200
metadata.message: OK
parsed results count: 384
```

## Chosen sample

```text
seqNumber: 1
docID: S100XZXO
edinetCode: E12460
secCode: null
filerName: 野村アセットマネジメント株式会社
docTypeCode: 180
submitDateTime: 2026-04-30 09:00
docDescription: 臨時報告書（内国特定有価証券）
xbrlFlag: 1
pdfFlag: 1
csvFlag: 1
primary document request shape: https://api.edinet-fsa.go.jp/api/v2/documents/S100XZXO?type=1&Subscription-Key=<redacted>
```

## Chosen family

```text
event_family: statutory_report_update
canonical_event_type: extraordinary_report
```

Rationale:

- the source is EDINET, an official regulatory filing system
- `docDescription` is `臨時報告書（内国特定有価証券）`
- this sample is a statutory extraordinary report, not a periodic securities report

## Identity rule

```text
stable_external_id: EDINET:S100XZXO
raw_event_key_seed: EDINET:S100XZXO
duplicate_group_seed: EDINET:S100XZXO
```

Do not use filer name or title text in identity.

## Cursor rule

```text
cursor_key: latest_submit_datetime_and_doc_id_seen
cursor_value: 2026-04-30T09:00:00+09:00|S100XZXO
```

The cursor uses official submit datetime plus docID.

## Timestamp rule

```text
published_at_local: 2026-04-30T09:00:00+09:00
published_at_utc: 2026-04-30T00:00:00.000000Z
filing_date_local: 2026-04-30
```

## Raw document identity rules

### Document-list row

```text
raw_document_external_id: EDINET:S100XZXO:document-list-row
document_identity: EDINET:S100XZXO:document-list-row
document_role: discovery_metadata
mime_type: application/json
```

### Primary document

```text
raw_document_external_id: EDINET:S100XZXO:primary-document:type1
document_identity: EDINET:S100XZXO:primary-document:type1
document_role: primary_regulatory_disclosure
mime_type: TODO after type=1 response header or payload capture
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

## Runtime blocker

Do not start EDINET runtime until one of the following is supplied:

```text
primary document payload text fixture for docID S100XZXO
or type=1 response headers and a stable text extraction plan
```

The API key must not be committed, logged, or shared in chat.

## Runtime guardrails

The later runtime PR must not add:

```text
TDnet changes
JP TDnet broad changes
CN broad changes
EDINET broad pagination
multiple EDINET document families
news overlay
cross-source merge
```

## Close-out result

EDINET contract-freeze is complete for:

```text
jp_edinet_statutory_report
```

Runtime remains blocked pending primary document fixture capture.
