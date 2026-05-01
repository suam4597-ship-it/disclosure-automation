# JP EDINET statutory report isolated runtime workset plan

This document defines the exact next implementation PR after JP EDINET statutory report contract-freeze.

Do not implement broad EDINET ingestion. Implement only one isolated EDINET fixture item after the primary document payload/text or response header fixture is captured.

## Implementation branch recommendation

```text
chatgpt-jp-edinet-runtime-v1
```

Base the branch on the merge commit of the EDINET contract-freeze close-out PR.

## Frozen contract to implement

```text
source_key: jp_edinet_statutory_report
adapter_key: jp_edinet_statutory_report_v1
region_code: jp
source_tier: official_regulatory_storage
event_family: statutory_report_update
canonical_event_type: extraordinary_report
stable_external_id: EDINET:S100XZXO
cursor_key: latest_submit_datetime_and_doc_id_seen
cursor_value: 2026-04-30T09:00:00+09:00|S100XZXO
event_id: jp.edinet.E12460.20260430.extraordinary_report.statutory_report_update.S100XZXO
```

## Runtime blocker

Runtime cannot start until one primary document representation is available:

```text
EDINET type=1 primary document payload text fixture
or type=1 response headers plus stable extraction plan
```

Do not commit or log the EDINET API key.

## Files to create in the runtime PR

### Source helper

```text
apps/backend/disclosure_api/lib/disclosure_automation/ops/jp_edinet_statutory_report_source.ex
```

### Runtime adapter

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/jp_edinet_statutory_report_adapter.ex
```

Also update adapter resolver only for:

```text
jp_edinet_statutory_report_v1
```

### Source registry sample

```text
apps/backend/disclosure_api/priv/config_samples/source_registry.jp_edinet_statutory_report.sample.yaml
```

Use `source_type: api`.

### Fixtures

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_edinet_statutory_report_document_list_20260430_S100XZXO.json
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_edinet_statutory_report_primary_document_S100XZXO.txt
```

If the primary document is a ZIP response, use a text representation fixture for v0 and record the extraction source in fixture metadata.

### Ops runner

```text
apps/backend/disclosure_api/priv/ops/run_jp_edinet_statutory_report_server.exs
```

### Dedupe SQL

```text
apps/backend/disclosure_api/priv/ops/jp_edinet_statutory_report_dedupe_checks.sql
```

### Tests

```text
apps/backend/disclosure_api/test/jp_edinet_statutory_report_runtime_idempotency_test.exs
apps/backend/disclosure_api/test/jp_edinet_statutory_report_http_smoke_test.exs
```

### Verification docs

```text
apps/backend/disclosure_api/docs/jp_edinet_statutory_report_manual_smoke.md
apps/backend/disclosure_api/docs/jp_edinet_statutory_report_minimal_verification.md
apps/backend/disclosure_api/docs/jp_edinet_statutory_report_first_run_triage.md
```

## Discovery fixture shape

The v0 discovery fixture should contain exactly one row.

Suggested JSON shape:

```json
{
  "metadata": {
    "parameter": {"date": "2026-04-30", "type": "2"},
    "resultset": {"count": 384},
    "processDateTime": "2026-05-01 00:03"
  },
  "results": [
    {
      "seqNumber": 1,
      "docID": "S100XZXO",
      "edinetCode": "E12460",
      "secCode": null,
      "filerName": "野村アセットマネジメント株式会社",
      "docTypeCode": "180",
      "submitDateTime": "2026-04-30 09:00",
      "docDescription": "臨時報告書（内国特定有価証券）",
      "xbrlFlag": "1",
      "pdfFlag": "1",
      "csvFlag": "1",
      "primaryDocumentRequestShape": "https://api.edinet-fsa.go.jp/api/v2/documents/S100XZXO?type=1&Subscription-Key=<redacted>"
    }
  ]
}
```

## Parser requirements

The adapter must:

1. load exactly one EDINET document-list fixture row
2. compute stable external id as `EDINET:S100XZXO`
3. compute cursor value as `2026-04-30T09:00:00+09:00|S100XZXO`
4. hydrate the primary document text fixture
5. produce exactly one raw event
6. normalize exactly one digest item
7. emit exactly the frozen `event_id`
8. keep the API key redacted in all metadata and citations

## Expected normalized item

```text
event_id: jp.edinet.E12460.20260430.extraordinary_report.statutory_report_update.S100XZXO
event_family: statutory_report_update
canonical_event_type: extraordinary_report
published_at_local: 2026-04-30T09:00:00+09:00
published_at_utc: 2026-04-30T00:00:00.000000Z
filing_date_local: 2026-04-30
stable_external_id: EDINET:S100XZXO
cursor_key: latest_submit_datetime_and_doc_id_seen
cursor_value: 2026-04-30T09:00:00+09:00|S100XZXO
edinet_code: E12460
doc_id: S100XZXO
doc_type_code: 180
```

## Raw document expectations

Expected raw documents per item:

1. `EDINET:S100XZXO:document-list-row`
2. `EDINET:S100XZXO:primary-document:type1`

## Test expectations

Runtime idempotency test must assert:

- first poll sees one record
- second poll sees one record
- digest item count remains one
- repeated poll keeps the same event id
- source health becomes healthy
- cursor key is `latest_submit_datetime_and_doc_id_seen`
- cursor value is `2026-04-30T09:00:00+09:00|S100XZXO`
- API key is not present in stored metadata or citations

HTTP smoke test must assert:

- admin poll endpoint returns one seen record
- latest digest returns the frozen event id
- normalized event family and canonical event type match the contract
- source metadata includes stable external id and cursor value

## Dedupe SQL expectations

Dedupe checks should assert no duplicate rows for:

- event id
- stable external id
- duplicate group key
- raw event external key
- raw document identity
- canonical digest story key

## Scope guardrail

The runtime PR must not add:

```text
TDnet changes
JP TDnet broad changes
CN broad changes
EDINET broad pagination
multiple EDINET document families
news overlay
cross-source merge
API key material
```
