# TW MOPS contract-freeze input sheet

This sheet translates the TSMC MOPS material-information sample into implementation-ready contract values.

## Frozen family

- chosen family: `material information / major announcement`
- chosen source key: `tw_mops_material_information`
- chosen display name: `Taiwan MOPS Material Information`
- chosen region code: `tw`

## Runtime contract

- adapter key: `tw_mops_material_information_v1`
- parser strategy: `MOPS action-target/result row parser + MOPS material-information detail parser`
- discovery mode: `mops_material_information_result_fixture`
- hydrate mode: `mops_material_information_detail`
- cursor key: `latest_spoke_date_time_and_sequence_seen`

## Identity rules

- raw document external id rule: `MOPS:<co_id>:<spoke_date>:<spoke_time>:<seq_no>:<document_role>`
- document identity rule: `MOPS:<co_id>:<spoke_date>:<spoke_time>:<seq_no>:<document_role>`
- raw event key seed: `mops:<co_id>:<spoke_date>:<spoke_time>:<seq_no>`
- duplicate group seed: `MOPS:<co_id>:<spoke_date>:<spoke_time>:<seq_no>`
- canonical event id shape: `tw.mops.<co_id>.<spoke_date>.<canonical_event_type>.<event_family>.<seq_no>`

## First event mapping

- first event family: `material_information_update`
- first canonical event type: `major_investment_or_asset_sale`
- source-appropriate canonical item source names:
  - primary: `MOPS Material Information Detail Page`
  - discovery: `MOPS Material Information Result Row`

## Fixture scope

- discovery fixture path: `source_payloads/tw_mops_material_information_result_2330_20260430_162938_1.html`
- detail fixture path: `source_payloads/tw_mops_material_information_detail_2330_20260430_162938_1.html`
- linked attachment fixture path if required: `none for v0`
- expected raw-document count per item: `2`
- expected canonical item source count per item: `2`

## Exact values to lock after first green run

- `event_id`: `TODO after first implementation run`
- `event_family`: `material_information_update`
- `canonical_event_type`: `major_investment_or_asset_sale`
- `published_at_local`: `2026-04-30T16:29:38+08:00`
- `published_at_utc`: `2026-04-30T08:29:38.000000Z`
- chosen stable external identity value: `MOPS:2330:20260430:162938:1`
- chosen cursor value: `20260430|162938|2330|1`

## Decision

- [x] contract freeze complete — open isolated implementation PR
- [ ] contract freeze incomplete — stay in discovery stage
- [ ] current family rejected — promote backup family

## Remaining first-run confirmation

The contract is ready for an isolated v0 implementation PR.
During first-run verification, confirm the exact canonical event id produced by the adapter and lock it after green tests.
