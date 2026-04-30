# JP TDnet timely-disclosure candidate contract v0

This document narrows JP discovery to one candidate source and one candidate first family.

It is not a runtime contract lock yet because the exact public TDnet/JPX sample row still needs to be captured.

## Candidate contract status

- status: `candidate_pre_freeze`
- runtime implementation allowed: `no`
- fixtures allowed: `no`
- tests allowed: `no`
- sample YAML allowed: `no`

## Source identity

- source key candidate: `jp_tdnet_timely_disclosure`
- display name candidate: `Japan TDnet Timely Disclosure Announcements`
- region code: `jp`
- source type candidate: `api` or `html`
- source class: `regulatory_filing_feed`
- source tier candidate: `official_exchange_storage`
- operator/source owner candidate: `Tokyo Stock Exchange / Japan Exchange Group`
- official platform rationale: JPX describes TDnet as the listed-company timely-disclosure network and describes Company Announcements Disclosure Service as the public inspection surface for TDnet disclosures.

## Discovery surface candidates

- authority/overview page: `https://www.jpx.co.jp/english/equities/listing/disclosure/tdnet/`
- English disclosure page: `https://www.jpx.co.jp/english/listing/disclosure/`
- Japanese Company Announcements Disclosure Service: `TODO_PUBLIC_INSPECTION_URL`
- Listed Company Search historical surface: `TODO_LISTED_COMPANY_SEARCH_URL`
- paid TDnet API reference: `https://www.jpx.co.jp/english/markets/paid-info-listing/tdnet/02.html`

Do not use paid TDnet API as the v0 runtime source unless a contract explicitly exists.

## Runtime contract candidate

- adapter key candidate: `jp_tdnet_timely_disclosure_v1`
- parser strategy candidate: `TDnet/JPX disclosure row + detail/PDF parser`
- discovery mode candidate: `tdnet_company_announcement_fixture`
- hydrate mode candidate: `tdnet_detail_or_pdf_attachment`
- cursor key candidate: `latest_disclosure_datetime_and_disclosure_number_seen`
- cursor value shape candidate: `<disclosure_datetime_local>|<disclosure_number>`

Fallback cursor if disclosure number is unavailable:

- fallback cursor key: `latest_disclosure_datetime_security_code_and_document_token_seen`
- fallback cursor value shape: `<disclosure_datetime_local>|<security_code>|<document_or_pdf_token>`

## Identity rules candidates

Preferred stable external identity:

```text
TDNET:<disclosure_number>:<disclosure_history_number>
```

Fallback stable external identity:

```text
TDNET:<disclosure_datetime_local>:<security_code>:<document_or_pdf_token>
```

Do not use title text as the stable identity.

## Raw document identity candidates

### Discovery row

- raw document external id rule: `TDNET:<stable_external_id>:discovery-row`
- document identity rule: `TDNET:<stable_external_id>:discovery-row`
- document role: `discovery_metadata`
- MIME type: `application/json` or `text/html`

### Detail page

- raw document external id rule: `TDNET:<stable_external_id>:detail-page`
- document identity rule: `TDNET:<stable_external_id>:detail-page`
- document role: `source_detail_page`
- MIME type: `text/html`

### PDF attachment

- raw document external id rule: `TDNET:<stable_external_id>:pdf:<document_or_pdf_token>`
- document identity rule: `TDNET:<stable_external_id>:pdf:<document_or_pdf_token>`
- document role: `primary_regulatory_disclosure`
- MIME type: `application/pdf`

## First thin-slice scope candidate

- event family candidate: `timely_disclosure_update`
- canonical event type candidate: `material_information_update`
- expected first fixture item count: `1`
- expected raw document count per item: `TODO`
- expected canonical item source count per item: `TODO`

## Candidate sample facts

These must be filled after public-source capture:

- sample company / issuer: `TODO`
- sample security code: `TODO`
- sample title: `TODO`
- sample disclosure category: `TODO`
- sample disclosure datetime local: `TODO`
- sample disclosure datetime UTC: `TODO`
- sample disclosure number: `TODO`
- sample disclosure history number: `TODO`
- sample detail URL: `TODO`
- sample PDF URL: `TODO`

## Source-appropriate canonical item source names

- official storage name: `TDnet / JPX Company Announcements Disclosure Service`
- official source name: `TDnet Timely Disclosure`
- discovery source name: `TDnet/JPX disclosure row`
- primary disclosure document source name: `TDnet/JPX disclosure document`

## Fixture plan for later implementation PR

Do not create these paths in this candidate PR.

- isolated sample YAML path: `apps/backend/disclosure_api/priv/config_samples/source_registry.jp_tdnet_timely_disclosure.sample.yaml`
- discovery fixture path: `apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_timely_disclosure_discovery_<sample>.json`
- detail fixture path: `apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_timely_disclosure_detail_<sample>.html`
- PDF fixture path: `apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_timely_disclosure_pdf_<sample>.pdf`
- source helper path: `apps/backend/disclosure_api/lib/disclosure_automation/ops/jp_tdnet_timely_disclosure_source.ex`
- adapter path: `apps/backend/disclosure_api/lib/disclosure_automation/runtime/jp_tdnet_timely_disclosure_adapter.ex`
- isolated server runner path: `apps/backend/disclosure_api/priv/ops/run_jp_tdnet_timely_disclosure_server.exs`
- dedupe SQL path: `apps/backend/disclosure_api/priv/ops/jp_tdnet_timely_disclosure_dedupe_checks.sql`
- runtime idempotency test path: `apps/backend/disclosure_api/test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs`
- HTTP smoke test path: `apps/backend/disclosure_api/test/jp_tdnet_timely_disclosure_http_smoke_test.exs`

## Remaining blockers before freeze

Capture and record one exact public TDnet/JPX sample row, including:

- disclosure datetime local
- security code
- company name
- title
- disclosure number or equivalent stable id
- disclosure history number, if available
- category/public item code, if available
- detail URL and/or PDF URL
- whether the sample remains retrievable outside the 31-day latest-disclosure window

Without the exact row and stable identity/cursor evidence, the candidate contract must not advance to runtime implementation.
