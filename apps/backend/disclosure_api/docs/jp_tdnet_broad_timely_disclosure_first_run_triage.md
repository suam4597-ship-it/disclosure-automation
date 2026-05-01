# JP TDnet broad timely disclosure first-run triage

Use this when the controlled JP TDnet broad timely disclosure runtime slice fails during first run.

## Frozen identifiers

```text
source_key: jp_tdnet_broad_timely_disclosure
adapter_key: jp_tdnet_broad_timely_disclosure_v1
sample_count: 3
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
```

Expected event ids:

```text
jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
jp.tdnet.2871.20260430.material_information_update.material_information_update.140120260430515256
jp.tdnet.6088.20260430.material_information_update.material_information_update.140120260430514945
```

## If adapter resolution fails

Check:

```text
DisclosureAutomation.Runtime.Adapter.resolve/1
```

Expected mapping:

```text
jp_tdnet_broad_timely_disclosure_v1 -> DisclosureAutomation.Runtime.JPTDnetBroadTimelyDisclosureAdapter
```

## If source cannot load

Check:

```text
apps/backend/disclosure_api/priv/config_samples/source_registry.jp_tdnet_broad_timely_disclosure.sample.yaml
apps/backend/disclosure_api/lib/disclosure_automation/ops/jp_tdnet_broad_timely_disclosure_source.ex
```

## If discovery returns wrong row count

Expected:

```text
3 rows
```

Check fixture:

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_broad_timely_disclosure_discovery_20260430.json
```

## If event ids differ

Check:

- normalized security code, not raw TDnet row code, is used in event id
- row date compact is `20260430`
- event family is `material_information_update`
- canonical event type is `material_information_update`
- final token is the PDF document token

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
- acquisition wording
- shareholder proposal wording
- ownership-change wording

## If duplicate rows appear

Run:

```text
apps/backend/disclosure_api/priv/ops/jp_tdnet_broad_timely_disclosure_dedupe_checks.sql
```

Expected:

- queries 1-6 return no rows
- query 7 returns row_count = 1 for all six raw document external ids

## Scope guardrail

Do not fix first-run issues by adding:

- broad live TDnet pagination
- additional TDnet rows
- EDINET runtime
- CN broad runtime
- title/category inference
- news overlay
- cross-source merge
