# UK FCA NSM takeover/scheme minimal verification

## Test gate

```powershell
$env:MIX_ENV="test"; mix.bat test test/uk_fca_nsm_takeover_scheme_updates_runtime_idempotency_test.exs
$env:MIX_ENV="test"; mix.bat test test/uk_fca_nsm_takeover_scheme_updates_http_smoke_test.exs
```

## Expected assertions

- `records_seen == 1`
- digest `item_count == 1`
- `region_code == "uk"`
- `home_market_region_code == "uk"`
- `event_family == "takeover_or_scheme_update"`
- `canonical_event_type == "tender_offer_or_go_private"`
- repeated poll keeps the same `event_id`
- source health becomes `healthy`
- cursor key is `latest_filing_at_and_artefact_id_seen`

## Expected v0 exact values

- `event_id`: `uk.fca_nsm.british_land_company_public_limited_company_the.20260420.tender_offer_or_go_private.takeover_or_scheme_update.5c9e4a51_b4c6_4977_86d3_ac8567261289`
- `published_at_local`: `2026-04-20T06:00:00+01:00`
- `published_at_utc`: starts with `2026-04-20T05:00:00`
- `filing_date_local`: `2026-04-20`
- stable external id: `NSM:RNS:5c9e4a51-b4c6-4977-86d3-ac8567261289`
- cursor: `2026-04-20T06:13:00|RNS|5c9e4a51-b4c6-4977-86d3-ac8567261289`

## Dedupe SQL

Run:

```text
priv/ops/uk_fca_nsm_takeover_scheme_updates_dedupe_checks.sql
```

Expected:

- queries 1-6 return no rows
- query 7 returns two rows with `row_count = 1`
