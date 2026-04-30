# JP TDnet candidate contract v0

This document narrows JP discovery to one candidate source and one candidate first family.

It is not a runtime contract lock yet because a deterministic public TDnet/JPX sample still needs to be captured.

## Candidate contract status

- status: `candidate_pre_freeze`
- runtime implementation allowed: `no`
- fixtures allowed: `no`
- tests allowed: `no`
- sample YAML allowed: `no`

## Source identity

- source key: `jp_tdnet_timely_disclosure`
- display name: `Japan TDnet Timely Disclosure Updates`
- region code: `jp`
- source type: `api` or `html`, pending source inspection
- source class: `regulatory_filing_feed`
- source tier: `official_exchange_storage`
- operator/source owner candidate: `Tokyo Stock Exchange / Japan Exchange Group`
- official platform rationale: TDnet/JPX is the official timely-disclosure route for listed-company corporate information.

## Discovery surface

- public latest-disclosure surface: `JPX Company Announcements Disclosure Service`
- public historical surface: `JPX Listed Company Search`
- paid/reference API surface: `TDnet API Service`
- detail URL shape candidate: `TODO_PUBLIC_SAMPLE_REQUIRED`
- attachment URL shape candidate: `TODO_PUBLIC_SAMPLE_REQUIRED`

## Runtime contract candidate

- adapter key: `jp_tdnet_timely_disclosure_v1`
- parser strategy: `TDnet/JPX disclosure index row + attachment/detail parser`
- discovery mode: `tdnet_disclosure_index_fixture`
- hydrate mode: `tdnet_disclosure_detail_or_attachment`
- cursor key: `latest_disclosure_datetime_and_disclosure_number_seen`
- cursor value shape: `<YYYY-MM-DDTHH:MM:SS+09:00>|<disclosure_number>|<disclosure_history_number>`

Fallback only if disclosure number/history number is unavailable on the public surface:

- fallback cursor key: `latest_disclosure_datetime_and_document_token_seen`
- fallback cursor value shape: `<YYYY-MM-DDTHH:MM:SS+09:00>|<pdf_or_document_token>`

## Identity rules

Preferred:

- stable external identity rule: `TDNET:<disclosure_number>:<disclosure_history_number>`
- raw event key seed: `TDNET:<disclosure_number>:<disclosure_history_number>`
- duplicate group seed: `TDNET:<disclosure_number>:<disclosure_history_number>`

Fallback:

- stable external identity rule: `TDNET:<security_code>:<disclosure_datetime_jst>:<pdf_or_document_token>`

Canonical event id shape candidate:

```text
jp.tdnet.<security_code>.<YYYYMMDD>.<canonical_event_type>.<event_family>.<stable_id_tail>
```

## First thin-slice scope candidate

Preferred v0:

- event family: `timely_disclosure_update`
- canonical event type: `material_information_update`
- expected first fixture item count: `1`
- expected raw document count per item: `2` or `3`
  - `2` if discovery row + PDF/detail document are sufficient
  - `3` if a separate detail page is needed to reach the document
- expected canonical item source count per item: `2`

Backup v0 if a narrower sample is clearer:

- event family: `major_transaction_update`
- canonical event type: `major_investment_or_asset_sale`

Alternative if tender-offer sample is clearer:

- event family: `takeover_or_scheme_update`
- canonical event type: `tender_offer_or_go_private`

## Sample facts to capture

- sample company / issuer: `TODO_PUBLIC_SAMPLE_REQUIRED`
- sample security code: `TODO_PUBLIC_SAMPLE_REQUIRED`
- sample title: `TODO_PUBLIC_SAMPLE_REQUIRED`
- sample source category: `TODO_PUBLIC_SAMPLE_REQUIRED`
- sample disclosure datetime local: `TODO_PUBLIC_SAMPLE_REQUIRED`
- sample disclosure datetime UTC: `TODO_PUBLIC_SAMPLE_REQUIRED`
- sample disclosure number: `TODO_PUBLIC_SAMPLE_REQUIRED`
- sample disclosure history number: `TODO_PUBLIC_SAMPLE_REQUIRED`
- sample detail URL: `TODO_PUBLIC_SAMPLE_REQUIRED`
- sample attachment URL: `TODO_PUBLIC_SAMPLE_REQUIRED`

## Source-appropriate canonical item source names

- official storage name: `TDnet / JPX`
- official source name: `JPX Company Announcements Disclosure Service`
- discovery source name: `TDnet/JPX disclosure index row`
- primary disclosure document source name: `TDnet/JPX disclosure attachment or detail document`

## Fixture plan for later implementation PR

Do not create these paths in this candidate PR.

- isolated sample YAML path: `apps/backend/disclosure_api/priv/config_samples/source_registry.jp_tdnet_timely_disclosure.sample.yaml`
- discovery fixture path: `apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_timely_disclosure_discovery_<sample>.json`
- detail fixture path: `apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_timely_disclosure_detail_<sample>.html`
- attachment fixture path: `apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_timely_disclosure_attachment_<sample>.pdf`
- source helper path: `apps/backend/disclosure_api/lib/disclosure_automation/ops/jp_tdnet_timely_disclosure_source.ex`
- adapter path: `apps/backend/disclosure_api/lib/disclosure_automation/runtime/jp_tdnet_timely_disclosure_adapter.ex`
- isolated server runner path: `apps/backend/disclosure_api/priv/ops/run_jp_tdnet_timely_disclosure_server.exs`
- dedupe SQL path: `apps/backend/disclosure_api/priv/ops/jp_tdnet_timely_disclosure_dedupe_checks.sql`
- runtime idempotency test path: `apps/backend/disclosure_api/test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs`
- HTTP smoke test path: `apps/backend/disclosure_api/test/jp_tdnet_timely_disclosure_http_smoke_test.exs`

## Remaining blockers before freeze

Capture and record one exact public TDnet/JPX sample with:

- disclosure datetime in JST
- company/security code
- company name
- disclosure title
- stable disclosure number/history number or public document token
- detail URL and/or attachment URL
- minimum raw-document set

Without that sample, the candidate contract must not advance to runtime implementation.
