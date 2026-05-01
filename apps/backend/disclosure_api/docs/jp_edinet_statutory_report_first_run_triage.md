# JP EDINET statutory report first-run triage

Use this when the isolated JP EDINET statutory report runtime slice fails during first run.

## Frozen identifiers

```text
source_key: jp_edinet_statutory_report
adapter_key: jp_edinet_statutory_report_v1
stable_external_id: EDINET:S100XZXO
event_id: jp.edinet.E12460.20260430.extraordinary_report.statutory_report_update.S100XZXO
cursor_key: latest_submit_datetime_and_doc_id_seen
cursor_value: 2026-04-30T09:00:00+09:00|S100XZXO
```

## If adapter resolution fails

Check:

```text
DisclosureAutomation.Runtime.Adapter.resolve/1
```

Expected mapping:

```text
jp_edinet_statutory_report_v1 -> DisclosureAutomation.Runtime.JPEdinetStatutoryReportAdapter
```

## If source cannot load

Check:

```text
apps/backend/disclosure_api/priv/config_samples/source_registry.jp_edinet_statutory_report.sample.yaml
apps/backend/disclosure_api/lib/disclosure_automation/ops/jp_edinet_statutory_report_source.ex
```

Expected source key:

```text
jp_edinet_statutory_report
```

## If discovery returns zero rows

Check source filter:

```text
doc_id: S100XZXO
```

Check fixture:

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_edinet_statutory_report_document_list_20260430_S100XZXO.json
```

The fixture must contain exactly one EDINET document-list row.

## If hydration fails

Check primary text fixture:

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_edinet_statutory_report_primary_document_S100XZXO.txt
```

Expected fixture map:

```text
EDINET:S100XZXO -> source_payloads/jp_edinet_statutory_report_primary_document_S100XZXO.txt
```

## If event id differs

Expected:

```text
jp.edinet.E12460.20260430.extraordinary_report.statutory_report_update.S100XZXO
```

Check:

- EDINET code is `E12460`
- filing date compact is `20260430`
- canonical event type is `extraordinary_report`
- event family is `statutory_report_update`
- docID is `S100XZXO`

## If cursor differs

Expected:

```text
2026-04-30T09:00:00+09:00|S100XZXO
```

Check that cursor uses:

- local submit datetime with `+09:00`
- `docID`
- no title text

## If API key appears anywhere

This is a contract violation.

Expected committed request shape:

```text
Subscription-Key=<redacted>
```

Check:

```text
source registry sample
fixtures
adapter metadata
portable citations
raw documents
tests
docs
```

Do not fix by committing a key. Keep key only in local `EDINET_API_KEY` if live capture is ever needed.

## If duplicate rows appear

Run:

```text
apps/backend/disclosure_api/priv/ops/jp_edinet_statutory_report_dedupe_checks.sql
```

Expected:

- queries 1-6 return no rows
- query 7 returns row_count = 1 for both raw document external ids

## Scope guardrail

Do not fix first-run issues by adding:

- EDINET broad pagination
- multiple EDINET documents
- TDnet changes
- CNInfo changes
- news overlay
- cross-source merge
- API key material
