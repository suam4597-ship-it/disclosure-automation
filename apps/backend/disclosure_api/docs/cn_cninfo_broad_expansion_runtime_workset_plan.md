# CNInfo broad expansion controlled runtime workset plan

This document defines the exact next implementation PR after CNInfo broad expansion contract-freeze.

Do not implement unbounded CNInfo live pagination. Implement only the three frozen fixture rows.

## Implementation branch recommendation

```text
chatgpt-cn-cninfo-broad-runtime-v1
```

Base the branch on the merge commit of the CNInfo broad contract-freeze close-out PR.

## Frozen contract to implement

```text
source_key: cn_cninfo_broad_announcement_feed
adapter_key: cn_cninfo_broad_announcement_feed_v1
region_code: cn
source_tier: official_exchange_storage
cursor_key: latest_announcement_date_and_announcement_id_seen
sample row count: 3
```

## Expected event ids

```text
cn.cninfo.603660.20260501.major_shareholding_or_insider_trade.ownership_change_update.1225274841
cn.cninfo.603350.20260501.shareholder_meeting.shareholder_meeting_update.1225274838
cn.cninfo.300376.20260501.board_or_management_change.board_change_update.1225274454
```

## Files to create in the runtime PR

### Source helper

```text
apps/backend/disclosure_api/lib/disclosure_automation/ops/cn_cninfo_broad_announcement_feed_source.ex
```

### Runtime adapter

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/cn_cninfo_broad_announcement_feed_adapter.ex
```

Also update adapter resolver only for:

```text
cn_cninfo_broad_announcement_feed_v1
```

### Source registry sample

```text
apps/backend/disclosure_api/priv/config_samples/source_registry.cn_cninfo_broad_announcement_feed.sample.yaml
```

Use `source_type: api`.

### Fixtures

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_broad_announcement_feed_discovery_20260501.json
apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_broad_announcement_feed_pdf_603660_20260501_1225274841.txt
apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_broad_announcement_feed_pdf_603350_20260501_1225274838.txt
apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_broad_announcement_feed_pdf_300376_20260501_1225274454.txt
```

### Ops runner

```text
apps/backend/disclosure_api/priv/ops/run_cn_cninfo_broad_announcement_feed_server.exs
```

### Dedupe SQL

```text
apps/backend/disclosure_api/priv/ops/cn_cninfo_broad_announcement_feed_dedupe_checks.sql
```

### Tests

```text
apps/backend/disclosure_api/test/cn_cninfo_broad_announcement_feed_runtime_idempotency_test.exs
apps/backend/disclosure_api/test/cn_cninfo_broad_announcement_feed_http_smoke_test.exs
```

### Verification docs

```text
apps/backend/disclosure_api/docs/cn_cninfo_broad_announcement_feed_manual_smoke.md
apps/backend/disclosure_api/docs/cn_cninfo_broad_announcement_feed_minimal_verification.md
apps/backend/disclosure_api/docs/cn_cninfo_broad_announcement_feed_first_run_triage.md
```

## Parser requirements

The adapter must:

1. load exactly three CNInfo discovery fixture rows
2. produce exactly three discovery items
3. hydrate exactly one PDF/text fixture per row
4. compute stable external ids using `CNINFO:<stockCode>:<YYYYMMDD>:<announcementId>`
5. compute cursor values using `<YYYY-MM-DD>|<announcementId>`
6. emit exactly the three frozen event ids
7. preserve `sec_code`, `sec_name`, `company_name`, `announcement_id`, `org_id`, `detail_url`, `adjunct_url`, and `pdf_url`
8. preserve the locked CNInfo ownership-change adapter and cursor semantics unchanged

## Expected normalized rows

### Row 1

```text
sec_code: 603660
event_family: ownership_change_update
canonical_event_type: major_shareholding_or_insider_trade
stable_external_id: CNINFO:603660:20260501:1225274841
cursor_value: 2026-05-01|1225274841
```

### Row 2

```text
sec_code: 603350
event_family: shareholder_meeting_update
canonical_event_type: shareholder_meeting
stable_external_id: CNINFO:603350:20260501:1225274838
cursor_value: 2026-05-01|1225274838
```

### Row 3

```text
sec_code: 300376
event_family: board_change_update
canonical_event_type: board_or_management_change
stable_external_id: CNINFO:300376:20260501:1225274454
cursor_value: 2026-05-01|1225274454
```

## Expected storage counts after repeated poll

```text
raw_events: 3
canonical_feed_items: 3
raw_documents: 6
canonical_item_sources: 6
representative source count: 3
```

## Locked CNInfo regression

The runtime PR must continue to pass:

```bash
mix test test/cn_cninfo_ownership_change_runtime_idempotency_test.exs
mix test test/cn_cninfo_ownership_change_http_smoke_test.exs
```

## Broad runtime tests

The new broad runtime tests must assert:

```text
first poll records_seen = 3
second poll records_seen = 3
latest digest item_count = 3
all three frozen event ids are present
source health is healthy
cursor key/value are present
all three stable external ids are present
raw document count is six
```

## Scope guardrail

The runtime PR must not add:

```text
JP broad runtime
EDINET runtime
SSE/SZSE/BSE adapters
unbounded CNInfo pagination
all CNInfo categories at once
news overlay
cross-source merge
```
