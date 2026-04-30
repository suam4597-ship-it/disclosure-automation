# JP TDnet timely disclosure isolated runtime workset plan

This document defines the exact next implementation PR after JP TDnet timely disclosure contract-freeze.

Do not implement broad JP ingestion. Implement only one isolated fixture item.

## Implementation branch recommendation

```text
chatgpt-jp-tdnet-runtime-v1
```

Base the branch on the merge commit of the JP TDnet contract-freeze close-out PR.

## Frozen contract to implement

```text
source_key: jp_tdnet_timely_disclosure
adapter_key: jp_tdnet_timely_disclosure_v1
region_code: jp
source_tier: official_exchange_storage
event_family: material_information_update
canonical_event_type: material_information_update
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
cursor_value: 2026-04-30T19:00:00+09:00|4527|140120260430515474
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
```

## Files to create in the runtime PR

### Source helper

```text
apps/backend/disclosure_api/lib/disclosure_automation/ops/jp_tdnet_timely_disclosure_source.ex
```

### Runtime adapter

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/jp_tdnet_timely_disclosure_adapter.ex
```

Also update adapter resolver only for:

```text
jp_tdnet_timely_disclosure_v1
```

### Source registry sample

```text
apps/backend/disclosure_api/priv/config_samples/source_registry.jp_tdnet_timely_disclosure.sample.yaml
```

### Fixtures

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_timely_disclosure_discovery_4527_20260430_1900_140120260430515474.json
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_timely_disclosure_pdf_4527_20260430_1900_140120260430515474.txt
```

Use a text fixture for v0 if the existing fixture loader/test path is simpler than binary PDF parsing. The fixture must represent the public PDF text for the chosen disclosure.

Do not add additional TDnet rows or PDFs.

### Ops runner

```text
apps/backend/disclosure_api/priv/ops/run_jp_tdnet_timely_disclosure_server.exs
```

### Dedupe SQL

```text
apps/backend/disclosure_api/priv/ops/jp_tdnet_timely_disclosure_dedupe_checks.sql
```

### Tests

```text
apps/backend/disclosure_api/test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
apps/backend/disclosure_api/test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

### Verification docs

```text
apps/backend/disclosure_api/docs/jp_tdnet_timely_disclosure_manual_smoke.md
apps/backend/disclosure_api/docs/jp_tdnet_timely_disclosure_minimal_verification.md
apps/backend/disclosure_api/docs/jp_tdnet_timely_disclosure_first_run_triage.md
```

## Discovery fixture shape

The v0 discovery fixture should contain exactly one row.

Suggested JSON shape:

```json
{
  "announcements": [
    {
      "source": "TDnet Company Announcements Disclosure Service",
      "rowListUrl": "https://www.release.tdnet.info/inbs/I_list_001_20260430.html",
      "rowDate": "2026-04-30",
      "disclosureTime": "19:00",
      "publishedAtLocal": "2026-04-30T19:00:00+09:00",
      "publishedAtUtc": "2026-04-30T10:00:00.000000Z",
      "tdnetRawRowCode": "45270",
      "normalizedSecurityCode": "4527",
      "rowDisplayName": "ロート薬",
      "issuerName": "ロート製薬株式会社",
      "title": "株主提案に関する書面受領のお知らせ",
      "exchange": "東",
      "xbrl": null,
      "updateHistory": null,
      "sourceCategory": null,
      "materialCategory": "unknown",
      "pdfDocumentToken": "140120260430515474",
      "attachmentUrl": "https://www.release.tdnet.info/inbs/140120260430515474.pdf"
    }
  ]
}
```

Do not invent a TDnet disclosure number, disclosure history number, public item code, or category.

## PDF/text fixture requirements

The PDF text fixture must contain enough text to assert:

```text
ロート製薬株式会社
コード番号 4527
東証プライム
株主提案に関する書面受領のお知らせ
2026年4月30日
AVI JAPAN OPPORTUNITY TRUST PLC
LONGCHAMP SICAV
```

The parser may use this text to confirm issuer, normalized security code, title, and document content summary, but must not infer `source_category` from title text in v0.

## Parser requirements

The adapter must:

1. load exactly one TDnet discovery fixture row
2. store `tdnet_raw_row_code` as `45270`
3. store `normalized_security_code` as `4527`
4. compute stable external id as `TDNET:4527:20260430:1900:140120260430515474`
5. compute cursor value as `2026-04-30T19:00:00+09:00|4527|140120260430515474`
6. hydrate the PDF/text fixture
7. produce exactly one raw event
8. normalize exactly one digest item
9. emit exactly the frozen `event_id`
10. keep `source_category` as `null`
11. keep `material_category` as `unknown`

## Expected normalized item

```text
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
event_family: material_information_update
canonical_event_type: material_information_update
published_at_local: 2026-04-30T19:00:00+09:00
published_at_utc: 2026-04-30T10:00:00.000000Z
filing_date_local: 2026-04-30
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
cursor_value: 2026-04-30T19:00:00+09:00|4527|140120260430515474
tdnet_raw_row_code: 45270
normalized_security_code: 4527
pdf_document_token: 140120260430515474
source_category: null
material_category: unknown
```

## Raw document expectations

Expected raw documents per item:

1. `TDNET:4527:20260430:1900:140120260430515474:discovery-row`
2. `TDNET:4527:20260430:1900:140120260430515474:pdf:140120260430515474`

No detail-page raw document is required for v0 unless the implementation explicitly needs it.

## Test expectations

Runtime idempotency test must assert:

- first poll sees one record
- second poll sees one record
- digest item count remains one
- repeated poll keeps the same event id
- source health becomes healthy
- cursor key is `latest_disclosure_datetime_security_code_and_pdf_token_seen`
- cursor value is `2026-04-30T19:00:00+09:00|4527|140120260430515474`
- raw row code and normalized security code are both preserved
- source category stays null/unknown rather than inferred from title text

HTTP smoke test must assert:

- admin poll endpoint returns one seen record
- latest digest returns the frozen event id
- normalized event family and canonical event type match the contract
- source metadata includes stable external id and cursor value
- source metadata includes TDnet raw row code and normalized security code

## Dedupe SQL expectations

Dedupe checks should assert no duplicate rows for:

- event id
- stable external id
- duplicate group key
- raw event external key
- raw document identity
- canonical digest story key

## Manual smoke pass condition

Manual smoke can pass only when:

- poll 1 and poll 2 both return `records_seen = 1`
- digest 1 and digest 2 both return `item_count = 1`
- both digests keep the frozen event id
- source health is healthy
- cursor key/value are present
- raw row code and normalized security code are both present
- dedupe SQL is clean

## Scope guardrail

The runtime PR must not add:

- broad JP all-disclosures ingestion
- TDnet live pagination beyond the one fixture path
- multiple TDnet categories
- EDINET implementation
- JPX Listed Company Search adapter
- news overlay
- cross-source merge
- broad CN expansion
