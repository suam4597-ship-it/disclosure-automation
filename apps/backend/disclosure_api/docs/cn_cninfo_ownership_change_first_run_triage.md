# CNInfo ownership-change first-run triage

## If the source does not upsert

Check:

- `apps/backend/disclosure_api/lib/disclosure_automation/ops/cn_cninfo_ownership_change_source.ex`
- `apps/backend/disclosure_api/priv/config_samples/source_registry.cn_cninfo_ownership_change.sample.yaml`
- `source_key = cn_cninfo_ownership_change`

## If adapter resolution fails

Check:

- `apps/backend/disclosure_api/lib/disclosure_automation/runtime/adapter.ex`

The source must resolve:

- `adapter_key = cn_cninfo_ownership_change_v1`

## If discovery returns zero rows

Check the discovery fixture:

- `apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_ownership_change_discovery_000404_20260330_1225049497.json`

The v0 adapter expects exactly one result item where:

- `announcementId = 1225049497`
- `announcementDate = 2026-03-30`
- `secCode = 000404`

## If the PDF text fixture does not load

Check the sample YAML PDF page map:

```text
CNINFO:1225049497
```

It must point to:

```text
source_payloads/cn_cninfo_ownership_change_pdf_000404_20260330_1225049497.txt
```

## If cursor is missing

Check that the discovery row exposes both cursor components:

- `announcementDate`
- `announcementId`

Expected cursor value:

```text
2026-03-30|1225049497
```

## If published time is wrong

The v0 fixture intentionally uses date-only China local midnight with UTC+08:00 offset:

- local: `2026-03-30T00:00:00+08:00`
- UTC: `2026-03-29T16:00:00Z`

Do not add a guessed `announcementTime` value in v0.

## If exact event_id drifts

Expected v0 event id:

```text
cn.cninfo.000404.20260330.major_shareholding_or_insider_trade.ownership_change_update.1225049497
```

If this changes, inspect:

- security code source
- announcement date source
- canonical event type
- event family
- announcement id

## If raw document counts are wrong

Expected minimum raw-document set:

- `CNINFO:1225049497:discovery-row`
- `CNINFO:1225049497:pdf:1225049497`

No separate detail-page raw document is expected in v0.

## If Windows PowerShell blocks mix

Use `mix.bat` instead of `mix`.
