# Stage 5 Reuters news overlay fixture close-out

This document closes out the first Stage 5 official + news overlay fixture candidate.

This PR adds one fixture payload and supporting docs only. It does not add runtime code, source adapters, tests, database migrations, schedulers, scraping, network fetches, or changes to locked regional runtimes.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 0fbe3ee77a8781fd73aa9d7a8218dc62014a6e18
base commit source: PR #64 Stage 5 news overlay fixture capture gate
source contract: stage5_news_overlay_source_contract_freeze.md
match evidence contract: stage5_news_overlay_match_evidence_contract.md
fixture capture sheet: stage5_news_overlay_fixture_capture_sheet.md
fixture gate: stage5_news_overlay_fixture_gate.md
```

## Added fixture payload

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/stage5_news_overlay_fixture_jp_tdnet_140120260430515474_reuters_jp_article_001.json
```

## Overlay source contract

```text
source_key: stage5_news_overlay_fixture
adapter_key: stage5_news_overlay_fixture_v1
source_tier: reputable_news_source
document_role: news_article
overlay_mode: attach_only
news_only_event_creation: forbidden
```

## Official anchor

The fixture attaches to the locked JP TDnet official event.

```text
official_source_key: jp_tdnet_timely_disclosure
official_adapter_key: jp_tdnet_timely_disclosure_v1
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
issuer: ロート製薬株式会社
security_code: 4527
official_title: 株主提案に関する書面受領のお知らせ
official_pdf_token: 140120260430515474
official_pdf_url: https://www.release.tdnet.info/inbs/140120260430515474.pdf
published_at_local: 2026-04-30T19:00:00+09:00
published_at_utc: 2026-04-30T10:00:00.000000Z
```

## News overlay fixture

```text
article_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
overlay_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
source_name: Reuters Japan / ロイター
source_url: https://jp.reuters.com/markets/global-markets/JKGTTV5MI5PFRGFVTC37DW73GE-2026-04-30/
article_title: 英ファンドＡＶＩ、ロートの会長解任議案を提出　企業統治改善求める
article_published_at: 2026-04-30T10:30:00Z
article_retrieved_at: 2026-05-01T07:04:55Z
claim_supported: transaction_context_reported_by_news
overlay_context_type: transaction_context
```

## News-only context handling

This fixture intentionally includes news-only context that is not treated as an official filing fact.

News-only overlay claims:

```text
AVI submitted a shareholder proposal seeking dismissal of Rohto chairman Kunio Yamada.
AVI called for governance and business-portfolio reforms.
Reuters connected the article to Rohto's same-day disclosure that it received shareholder proposal documents and would disclose the board's opinion after review.
```

These claims are stored under `overlayClaims` with:

```text
claimKind: news_only_context or secondary_confirmation
canonicalFactOverride: false
sourceCitationRef: citation:reuters-jp-article-001
```

The fixture does not use Reuters to overwrite official TDnet filing facts.

## Official facts preserved

```text
event_id unchanged: true
stable_external_id unchanged: true
raw document identity unchanged: true
official timestamp unchanged: true
canonical_event_type unchanged: true
news claims do not overwrite official facts: true
```

## Match evidence

The fixture match is based on explicit official and article evidence, not LLM-only matching.

```text
match_decision_source: manual_fixture_author
match_rule: issuer_identifier_and_event_family_and_date
matched official event: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
matched security code: 4527
article ticker mention: 4527.T
matched issuer: Rohto Pharmaceutical / ロート製薬株式会社
matched event theme: shareholder proposal / 株主提案
publication window: article published 30 minutes after official TDnet timestamp
ambiguity_flags: []
conflict_flags: []
```

Publication timing is supporting evidence only. The fixture also uses issuer/security-code evidence, title/theme evidence, and Reuters' link to Rohto's same-day disclosure.

## Citation separation

The fixture keeps official and news citations separate.

Official citation:

```text
citation_id: citation:tdnet-official-140120260430515474
source_tier: official_exchange_storage
claim_supported: official disclosure receipt of shareholder proposal documents
```

News citation:

```text
citation_id: citation:reuters-jp-article-001
source_tier: reputable_news_source
claim_supported: news-only transaction context and secondary confirmation
```

## Backup candidate not included

Bloomberg was supplied as a backup candidate for the same story family, but this PR does not add it as a fixture row.

Reason:

```text
first fixture row limit remains one Reuters overlay row
Reuters directly links the news context to Rohto's same-day disclosure
Bloomberg can remain a future backup candidate if a second fixture is needed
```

## Runtime lock boundary

This fixture PR does not lock any runtime.

Before Stage 5 runtime lock, future work must still add:

```text
source registry sample if needed by runtime
adapter implementation
idempotency test
HTTP smoke test
citation provenance test
storage-level overlay/dedupe check
manual smoke
runtime lock close-out
```

The fixture metadata marks:

```text
directArticleFetchRequiredBeforeRuntimeLock: true
```

That is intentional. The current fixture is based on supplied public article metadata and external corroboration, but the future runtime lock should still verify direct fetch/access behavior or document a no-fetch fixture-only path.

## Guardrails preserved

```text
no runtime code
no source adapter
no tests
no database migrations
no scheduler changes
no network fetch in repo code
no scraping
no news-only canonical event
no LLM-only duplicate decision
no mutation of locked official runtime identifiers
no API key or secret-bearing value
```

## Acceptance status

```text
fixture row references one locked official canonical event: yes
fixture row uses stage5_news_overlay_fixture / stage5_news_overlay_fixture_v1: yes
fixture row is attach-only: yes
fixture row has deterministic article_external_id: yes
fixture row has explicit match_evidence: yes
fixture row has separate official and news citation objects: yes
fixture row does not mutate official identifiers: yes
fixture row does not store secrets: yes
fixture row does not create a news-only event: yes
```
