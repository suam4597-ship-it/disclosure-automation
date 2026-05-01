# CNInfo broad announcement feed first-run triage

Use this when the controlled CNInfo broad announcement feed runtime slice fails during first run.

## Frozen identifiers

```text
source_key: cn_cninfo_broad_announcement_feed
adapter_key: cn_cninfo_broad_announcement_feed_v1
sample_count: 3
cursor_key: latest_announcement_date_and_announcement_id_seen
```

Expected event ids:

```text
cn.cninfo.603660.20260501.major_shareholding_or_insider_trade.ownership_change_update.1225274841
cn.cninfo.603350.20260501.shareholder_meeting.shareholder_meeting_update.1225274838
cn.cninfo.300376.20260501.board_or_management_change.board_change_update.1225274454
```

## If adapter resolution fails

Check:

```text
DisclosureAutomation.Runtime.Adapter.resolve/1
```

Expected mapping:

```text
cn_cninfo_broad_announcement_feed_v1 -> DisclosureAutomation.Runtime.CNCNInfoBroadAnnouncementFeedAdapter
```

## If source cannot load

Check:

```text
apps/backend/disclosure_api/priv/config_samples/source_registry.cn_cninfo_broad_announcement_feed.sample.yaml
apps/backend/disclosure_api/lib/disclosure_automation/ops/cn_cninfo_broad_announcement_feed_source.ex
```

## If discovery returns wrong row count

Expected:

```text
3 rows
```

Check fixture:

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_broad_announcement_feed_discovery_20260501.json
```

## If event ids differ

Check:

- sec code is used in event id
- date compact is `20260501`
- event family/canonical type comes from each fixture row
- final token is the announcement id

## If cursor differs

Expected date-only cursor values:

```text
2026-05-01|1225274841
2026-05-01|1225274838
2026-05-01|1225274454
```

Do not mutate the locked CNInfo ownership-change cursor.

## If duplicate rows appear

Run:

```text
apps/backend/disclosure_api/priv/ops/cn_cninfo_broad_announcement_feed_dedupe_checks.sql
```

Expected:

- queries 1-6 return no rows
- query 7 returns row_count = 1 for all six raw document external ids

## Scope guardrail

Do not fix first-run issues by adding:

- unbounded CNInfo live pagination
- all CNInfo categories at once
- JP broad runtime changes
- EDINET runtime
- SSE/SZSE/BSE adapters
- news overlay
- cross-source merge
