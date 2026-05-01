# Stage 5 news overlay fixture capture sheet

This document defines the capture sheet for the first official + news overlay fixture pair.

This is a docs-only capture gate. It does not add runtime code, source adapters, fixture payload files, tests, database migrations, schedulers, scraping, or changes to locked regional runtimes.

## Baseline

This capture sheet follows:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 23bad671087854d4d4b553e862602b88350b4d51
base commit source: PR #63 Stage 5 news overlay source contract freeze
source contract: stage5_news_overlay_source_contract_freeze.md
match evidence contract: stage5_news_overlay_match_evidence_contract.md
```

The overlay source contract remains:

```text
source_key: stage5_news_overlay_fixture
adapter_key: stage5_news_overlay_fixture_v1
source_tier: reputable_news_source
document_role: news_article
overlay_mode: attach_only
news_only_event_creation: forbidden
```

## Current status

No news overlay fixture row is frozen in this PR.

A fixture row must not be created from invented article data. A future fixture PR must use an actual supplied article, public article URL, or explicitly redacted/manual article reference with enough provenance to verify the overlay claim.

## Candidate official anchor A: JP TDnet locked event

This official anchor is already locked and may be used for the first fixture pair.

```text
official_source_key: jp_tdnet_timely_disclosure
official_adapter_key: jp_tdnet_timely_disclosure_v1
official_source_tier: official_exchange_storage
official_document_role: official_exchange_disclosure
jurisdiction: jp
event_family: material_information_update
canonical_event_type: material_information_update
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
published_at_local: 2026-04-30T19:00:00+09:00
published_at_utc: 2026-04-30T10:00:00.000000Z
filing_date_local: 2026-04-30
issuer_name: ロート製薬株式会社
normalized_security_code: 4527
tdnet_raw_row_code: 45270
pdf_document_token: 140120260430515474
official_attachment_url: https://www.release.tdnet.info/inbs/140120260430515474.pdf
official_title: 株主提案に関する書面受領のお知らせ
```

Expected future article external id shape:

```text
NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:article-001
```

## Candidate official anchor B: CNInfo broad locked event

This optional official anchor may be used for a second fixture pair after a matching article is supplied.

```text
official_source_key: cn_cninfo_broad_announcement_feed
official_adapter_key: cn_cninfo_broad_announcement_feed_v1
official_source_tier: official_regulatory_storage
official_document_role: official_filing
jurisdiction: cn
event_family: major_shareholding_or_insider_trade
canonical_event_type: ownership_change_update
event_id: cn.cninfo.603660.20260501.major_shareholding_or_insider_trade.ownership_change_update.1225274841
stable_external_id: CNINFO:603660:20260501:1225274841
filing_date_local: 2026-05-01
security_code: 603660
announcement_id: 1225274841
```

Expected future article external id shape:

```text
NEWS-FIXTURE:cn:cn_cninfo_broad_announcement_feed:1225274841:article-001
```

## Required article capture fields

A future fixture PR must fill these fields for each article.

```text
article_external_id:
source_name:
source_url:
article_title:
article_published_at:
article_retrieved_at:
article_language:
article_author_or_wire:
article_summary:
claim_supported:
overlay_context_type:
mentioned_issuer_identifier:
mentioned_issuer_name:
mentioned_event_family:
referenced_official_url:
referenced_official_identifier:
reported_amounts_or_dates:
reported_parties:
conflict_flags:
manual_verification_note:
```

## Allowed claim_supported values

```text
secondary_confirmation
article_reported_market_reaction
article_reported_background
issuer_comment_reported_by_news
analyst_comment_reported_by_news
transaction_context_reported_by_news
discrepancy_note
```

## Allowed overlay_context_type values

```text
secondary_confirmation
market_reaction
reported_background
issuer_comment
analyst_comment
transaction_context
discrepancy_note
```

## Required match evidence fields

Each future fixture row must include:

```text
matched_canonical_event_id
matched_official_source_key
matched_official_stable_external_id
matched_official_event_family
matched_official_canonical_event_type
matched_issuer_evidence
matched_publication_window
match_rule
match_inputs
match_decision_source
```

Allowed match_decision_source values:

```text
deterministic_rule
manual_fixture_author
manual_verification
```

Forbidden finalized match_decision_source values:

```text
llm_only
semantic_similarity_only
publication_window_only
headline_similarity_only
```

## Required citation object fields

Each future overlay citation must include:

```text
source_name
source_tier
source_key
source_url
claim_supported
document_role
published_at
retrieved_at
article_external_id
overlay_id
canonical_event_id
```

Official filing facts must cite official sources separately. News-derived context must cite the news article separately.

## Redaction requirements

Do not store:

```text
API keys
Authorization headers
Subscription keys
cookies
session tokens
signed private URLs
unredacted EDINET Subscription-Key values
secret-bearing query params
local filesystem paths containing secrets
```

Any EDINET request shape must remain:

```text
Subscription-Key=<redacted>
```

## No-go conditions

Do not create a future fixture row if any of these are true:

```text
article is invented
article URL or source reference cannot be verified manually
article source contains secret-bearing access data
article cannot be linked to a locked official event with explicit evidence
only evidence is publication timing
only evidence is title similarity
only evidence is LLM semantic similarity
candidate article matches multiple official events ambiguously
fixture would require mutating official event_id
fixture would require mutating stable_external_id
fixture would require mutating raw_document_external_id
```

## Future fixture PR acceptance criteria

The next fixture PR may add 1-2 manually curated fixture rows only if each row satisfies this capture sheet.

Required future checks:

```text
fixture row references one locked official canonical event
fixture row uses stage5_news_overlay_fixture / stage5_news_overlay_fixture_v1
fixture row is attach-only
fixture row has deterministic article_external_id
fixture row has explicit match_evidence
fixture row has separate news citation object
fixture row does not mutate official identifiers
fixture row does not store secrets
fixture row does not create a news-only event
```

## Acceptance criteria for this capture-gate PR

```text
changed files are limited to Stage 5 docs
no runtime code is added
no source adapter is added
no fixture payload file is added
no test is added
no migration is added
no scheduler change is added
no invented article data is committed
locked official runtime identifiers remain immutable
```
