# TW MOPS material information first-run triage

## If the source does not upsert

Check:

- `apps/backend/disclosure_api/lib/disclosure_automation/ops/tw_mops_material_information_source.ex`
- `apps/backend/disclosure_api/priv/config_samples/source_registry.tw_mops_material_information.sample.yaml`
- `source_key = tw_mops_material_information`

## If adapter resolution fails

Check:

- `apps/backend/disclosure_api/lib/disclosure_automation/runtime/adapter.ex`

The source must resolve:

- `adapter_key = tw_mops_material_information_v1`

## If discovery returns zero rows

Check the discovery fixture:

- `apps/backend/disclosure_api/priv/fixtures/source_payloads/tw_mops_material_information_result_2330_20260430_162938_1.html`

The v0 adapter expects exactly one result item where:

- `data-co-id = 2330`
- `data-seq-no = 1`
- `data-spoke-date = 20260430`
- `data-spoke-time = 162938`

## If the detail fixture does not load

Check the sample YAML detail page map:

```text
MOPS:2330:20260430:162938:1
```

It must point to:

```text
source_payloads/tw_mops_material_information_detail_2330_20260430_162938_1.html
```

## If cursor is missing

Check that the discovery row exposes all four cursor components:

- `spoke_date`
- `spoke_time`
- `co_id`
- `seq_no`

Expected cursor value:

```text
20260430|162938|2330|1
```

## If published time is wrong

The fixture uses Taiwan local time with fixed UTC+08:00 offset:

- local: `2026-04-30T16:29:38+08:00`
- UTC: `2026-04-30T08:29:38Z`

The body displays ROC date `115/04/30`; the URL `spoke_date` already uses Gregorian `20260430`.

## If exact event_id drifts

Expected v0 event id:

```text
tw.mops.2330.20260430.major_investment_or_asset_sale.material_information_update.1
```

If this changes, inspect:

- company code source
- Gregorian `spoke_date`
- canonical event type
- event family
- sequence number

## If raw document counts are wrong

Expected minimum raw-document set:

- `MOPS:2330:20260430:162938:1:detail-page`
- `MOPS:2330:20260430:162938:1:discovery-row`

## If Windows PowerShell blocks mix

Use `mix.bat` instead of `mix`.
