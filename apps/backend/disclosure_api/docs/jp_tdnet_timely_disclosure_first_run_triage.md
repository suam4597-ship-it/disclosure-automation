# JP TDnet timely disclosure first-run triage

Use this when the isolated JP TDnet timely disclosure runtime slice fails during first run.

## Frozen identifiers

```text
source_key: jp_tdnet_timely_disclosure
adapter_key: jp_tdnet_timely_disclosure_v1
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
cursor_value: 2026-04-30T19:00:00+09:00|4527|140120260430515474
```

## If adapter resolution fails

Check:

```text
DisclosureAutomation.Runtime.Adapter.resolve/1
```

Expected mapping:

```text
jp_tdnet_timely_disclosure_v1 -> DisclosureAutomation.Runtime.JPTDnetTimelyDisclosureAdapter
```

## If source cannot load

Check:

```text
apps/backend/disclosure_api/priv/config_samples/source_registry.jp_tdnet_timely_disclosure.sample.yaml
apps/backend/disclosure_api/lib/disclosure_automation/ops/jp_tdnet_timely_disclosure_source.ex
```

Expected source key:

```text
jp_tdnet_timely_disclosure
```

## If discovery returns zero rows

Check the source filter:

```text
normalized_security_code: 4527
pdf_document_token: 140120260430515474
row_date: 2026-04-30
```

Check the fixture path:

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_timely_disclosure_discovery_4527_20260430_1900_140120260430515474.json
```

The fixture must contain exactly one row.

## If hydration fails

Check the PDF text fixture path:

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_timely_disclosure_pdf_4527_20260430_1900_140120260430515474.txt
```

The config key must map:

```text
TDNET:4527:20260430:1900:140120260430515474 -> source_payloads/jp_tdnet_timely_disclosure_pdf_4527_20260430_1900_140120260430515474.txt
```

## If event id differs

Expected:

```text
jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
```

Check:

- normalized security code is `4527`, not raw row code `45270`
- row date compact is `20260430`
- event family is `material_information_update`
- canonical event type is `material_information_update`
- final token is `140120260430515474`

## If cursor differs

Expected:

```text
2026-04-30T19:00:00+09:00|4527|140120260430515474
```

Check that the cursor uses:

- local publication datetime with `+09:00`
- normalized security code `4527`
- PDF document token `140120260430515474`

Do not use title text in the cursor.

## If category is inferred

This is a contract violation for v0.

Expected:

```text
source_category = null
material_category = unknown
source_category_inferred = false
```

Do not infer category from:

- title text
- PDF text
- shareholder proposal semantics

## If duplicate rows appear

Run:

```text
apps/backend/disclosure_api/priv/ops/jp_tdnet_timely_disclosure_dedupe_checks.sql
```

Expected:

- queries 1-6 return no rows
- query 7 returns row_count = 1 for both raw document external ids

## If JP lane is empty

Check that `region_code` and `home_market_region_code` are both:

```text
jp
```

Then check:

```bash
curl -s 'http://127.0.0.1:4000/api/feed/region/jp'
```

Expected:

```text
slot_id = lane.jp
items include the frozen event_id
```

## Scope guardrail

Do not fix first-run issues by adding:

- broad TDnet pagination
- additional TDnet rows
- EDINET runtime
- JPX Listed Company Search adapter
- title/category inference
- news overlay
- cross-source merge
