# Stage 5 news overlay fixture gate

This document gates the first Stage 5 official + news overlay fixture PR.

This is a docs-only gate. It does not add runtime code, source adapters, fixture payload files, tests, database migrations, schedulers, scraping, or changes to locked regional runtimes.

## Baseline

This gate follows:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 23bad671087854d4d4b553e862602b88350b4d51
base commit source: PR #63 Stage 5 news overlay source contract freeze
capture sheet: stage5_news_overlay_fixture_capture_sheet.md
```

## Decision

The first actual overlay fixture PR is blocked until at least one real, verifiable article record is supplied and reviewed against the capture sheet.

Do not invent article data.

Do not use synthetic news as if it were reputable news.

Do not use a placeholder URL as if it were a real source.

## Required supplied article evidence

A future fixture PR needs one of the following:

```text
public article URL plus article title and publication time
public archive URL plus article title and publication time
manual article reference with source name, retrieval note, and enough metadata to verify provenance
```

For paywalled or access-controlled articles, the fixture may store only safe metadata and a non-secret URL. It must not store cookies, tokens, signed URLs, or private access credentials.

## Minimum metadata to proceed

At least one article must provide:

```text
source_name
source_url or redacted/manual source reference
article_title
article_published_at
article_retrieved_at
article_language
claim_supported
overlay_context_type
matched official event anchor
explicit match evidence
```

## Preferred first official anchor

The preferred first official anchor is the locked JP TDnet single event.

```text
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
official_source_key: jp_tdnet_timely_disclosure
issuer_name: ロート製薬株式会社
normalized_security_code: 4527
pdf_document_token: 140120260430515474
official_title: 株主提案に関する書面受領のお知らせ
```

This anchor is preferred because it is already locked as a single-source official runtime and has a stable PDF token.

## Alternative official anchors

A future fixture PR may instead use one of the locked CNInfo or SEC official events if a better matching article is supplied.

The article must still attach to an existing locked official canonical event and must not create a news-only event.

## Fixture row limit

The first fixture PR may add:

```text
minimum: 1 overlay fixture row
maximum: 2 overlay fixture rows
```

Any broader overlay fixture set is out of scope.

## Fixture storage guidance

Future fixture payload files should follow existing project fixture conventions.

Suggested path pattern:

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/stage5_news_overlay_fixture_<jurisdiction>_<official_token>_<article_token>.json
```

Suggested sample registry path, if needed by future runtime:

```text
apps/backend/disclosure_api/priv/config_samples/source_registry.stage5_news_overlay_fixture.sample.yaml
```

This gate PR does not add those files.

## Future fixture object sketch

A future fixture row may use a structure like:

```json
{
  "overlays": [
    {
      "articleExternalId": "NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:article-001",
      "canonicalEventId": "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474",
      "sourceKey": "stage5_news_overlay_fixture",
      "sourceTier": "reputable_news_source",
      "documentRole": "news_article",
      "sourceName": "<real source name>",
      "sourceUrl": "<public or redacted source URL>",
      "articleTitle": "<real article title>",
      "articlePublishedAt": "<ISO 8601 timestamp>",
      "articleRetrievedAt": "<ISO 8601 timestamp>",
      "claimSupported": "secondary_confirmation",
      "overlayContextType": "secondary_confirmation",
      "matchEvidence": {},
      "citation": {},
      "conflictFlags": []
    }
  ]
}
```

This is a schema sketch only. Placeholder values must be replaced by real supplied article evidence before fixture payload files are committed.

## Required verification for future fixture PR

A future fixture PR must verify:

```text
article data is not invented
article source is reputable or explicitly documented
article URL/source reference is safe to persist
article_external_id is deterministic
canonical_event_id points to a locked official event
match_evidence satisfies stage5_news_overlay_match_evidence_contract.md
citation satisfies stage5_news_overlay_source_contract_freeze.md
fixture does not mutate official event_id
fixture does not mutate official stable_external_id
fixture does not mutate official raw_document_external_id
fixture does not create a news-only event
fixture stores no secrets
```

## User action needed before actual fixture PR

To proceed beyond this gate, provide at least one real article candidate for a locked official event.

Preferred format:

```text
official event anchor:
article source name:
article URL:
article title:
article publication timestamp:
article retrieval timestamp:
claim the article supports:
why it matches the official event:
```

Do not provide API keys, cookies, signed URLs, or private access tokens.

## Acceptance criteria for this gate PR

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
