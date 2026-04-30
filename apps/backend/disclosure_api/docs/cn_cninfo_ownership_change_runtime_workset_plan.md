# CNInfo ownership-change isolated runtime workset plan

This document defines the exact next implementation PR after CNInfo ownership-change contract-freeze.

Do not implement broad CN ingestion. Implement only one isolated fixture item.

## Implementation branch recommendation

```text
chatgpt-cn-cninfo-ownership-change-runtime-v1
```

Base the branch on the merge commit of the contract-freeze close-out PR.

## Frozen contract to implement

```text
source_key: cn_cninfo_ownership_change
adapter_key: cn_cninfo_ownership_change_v1
region_code: cn
source_tier: official_exchange_storage
event_family: ownership_change_update
canonical_event_type: major_shareholding_or_insider_trade
stable_external_id: CNINFO:1225049497
cursor_key: latest_announcement_date_and_announcement_id_seen
cursor_value: 2026-03-30|1225049497
event_id: cn.cninfo.000404.20260330.major_shareholding_or_insider_trade.ownership_change_update.1225049497
```

## Files to create in the runtime PR

### Source helper

```text
apps/backend/disclosure_api/lib/disclosure_automation/ops/cn_cninfo_ownership_change_source.ex
```

### Runtime adapter

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/cn_cninfo_ownership_change_adapter.ex
```

Also update adapter resolver only for:

```text
cn_cninfo_ownership_change_v1
```

### Source registry sample

```text
apps/backend/disclosure_api/priv/config_samples/source_registry.cn_cninfo_ownership_change.sample.yaml
```

### Fixtures

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_ownership_change_discovery_000404_20260330_1225049497.json
apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_ownership_change_pdf_000404_20260330_1225049497.txt
```

Use a text fixture for v0 if the existing fixture loader/test path is simpler than binary PDF parsing. The fixture must represent the public PDF text for the chosen disclosure.

Do not add additional CNInfo announcement fixtures.

### Ops runner

```text
apps/backend/disclosure_api/priv/ops/run_cn_cninfo_ownership_change_server.exs
```

### Dedupe SQL

```text
apps/backend/disclosure_api/priv/ops/cn_cninfo_ownership_change_dedupe_checks.sql
```

### Tests

```text
apps/backend/disclosure_api/test/cn_cninfo_ownership_change_runtime_idempotency_test.exs
apps/backend/disclosure_api/test/cn_cninfo_ownership_change_http_smoke_test.exs
```

### Verification docs

```text
apps/backend/disclosure_api/docs/cn_cninfo_ownership_change_manual_smoke.md
apps/backend/disclosure_api/docs/cn_cninfo_ownership_change_minimal_verification.md
apps/backend/disclosure_api/docs/cn_cninfo_ownership_change_first_run_triage.md
```

## Discovery fixture shape

The v0 discovery fixture should contain exactly one row.

Suggested JSON shape:

```json
{
  "announcements": [
    {
      "announcementId": "1225049497",
      "announcementTitle": "关于公司部分董事和高级管理人员增持公司股份计划时间过半的进展公告",
      "announcementDate": "2026-03-30",
      "secCode": "000404",
      "secName": "长虹华意",
      "announcementNum": "2026-019",
      "adjunctUrl": "finalpage/2026-03-30/1225049497.PDF",
      "adjunctType": "PDF"
    }
  ]
}
```

Do not invent `announcementTime` in v0. The frozen cursor uses announcement date plus announcement id.

## Parser requirements

The adapter must:

1. load exactly one discovery fixture row
2. compute stable external id as `CNINFO:1225049497`
3. compute cursor value as `2026-03-30|1225049497`
4. hydrate the PDF/text fixture
5. produce exactly one raw event
6. normalize exactly one digest item
7. emit exactly the frozen `event_id`

## Expected normalized item

```text
event_id: cn.cninfo.000404.20260330.major_shareholding_or_insider_trade.ownership_change_update.1225049497
event_family: ownership_change_update
canonical_event_type: major_shareholding_or_insider_trade
published_at_local: 2026-03-30T00:00:00+08:00
published_at_utc: 2026-03-29T16:00:00.000000Z
filing_date_local: 2026-03-30
stable_external_id: CNINFO:1225049497
cursor_value: 2026-03-30|1225049497
```

## Raw document expectations

Expected raw documents per item:

1. `CNINFO:1225049497:discovery-row`
2. `CNINFO:1225049497:pdf:1225049497`

No detail-page raw document is required for v0 unless the implementation explicitly needs it.

## Test expectations

Runtime idempotency test must assert:

- first poll sees one record
- second poll sees one record
- digest item count remains one
- repeated poll keeps the same event id
- source health becomes healthy
- cursor key is `latest_announcement_date_and_announcement_id_seen`
- cursor value is `2026-03-30|1225049497`

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

## Manual smoke pass condition

Manual smoke can pass only when:

- poll 1 and poll 2 both return `records_seen = 1`
- digest 1 and digest 2 both return `item_count = 1`
- both digests keep the frozen event id
- source health is healthy
- cursor key/value are present
- dedupe SQL is clean

## Scope guardrail

The runtime PR must not add:

- broad CN all-disclosures ingestion
- CN live API pagination
- multiple CNInfo categories
- M&A/restructuring family
- material-information family
- SSE/SZSE/BSE separate adapters
- JP
- news overlay
- cross-source merge
