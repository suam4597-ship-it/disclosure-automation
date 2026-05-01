# Stage 5 source precedence and citation policy

This document defines Stage 5 source precedence and citation rules for official disclosure events, issuer releases, news overlay, aggregators, and unverified sources.

This document is design-only. It does not add runtime code, source adapters, fixtures, tests, database migrations, schedulers, scraping, or changes to locked regional runtimes.

## Source precedence

Initial source precedence:

```text
1. official regulatory/exchange storage
2. official company / issuer release
3. reputable news source
4. secondary aggregator
5. social / rumor / unverified source
```

Precedence controls which source wins when sources conflict about legal filing facts.

Precedence must not erase lower-precedence provenance. Lower-precedence sources may remain as context, related source, discrepancy evidence, or overlay citation.

## Official regulatory/exchange storage

Official regulatory and exchange sources are canonical for filing facts.

Examples:

```text
SEC EDGAR
AFM
UK FCA NSM
TW MOPS
CNInfo
JP TDnet
JP EDINET
```

Official filing facts include:

```text
filing timestamp
filing date
document identity
stable external id
issuer identifier
event family
canonical event type
official document URL or storage reference
filing contents extracted from official source
```

## Official company / issuer releases

Issuer releases may provide official issuer-side context. They do not supersede regulatory/exchange filings for regulatory filing facts unless the official source itself references or incorporates the issuer release as the primary document.

Issuer releases may be useful for:

```text
management explanation
transaction narrative
issuer quote
press release timing
investor relations URL
```

## Reputable news source

A reputable news source may provide context, secondary confirmation, reported market reaction, analyst interpretation, or background.

A news source must not be used as the citation for facts that are only established by an official filing.

## Secondary aggregator

A secondary aggregator may help discovery or provide secondary context.

Aggregator claims should be treated as lower-precedence unless independently supported by official filings, issuer releases, or reputable news sources.

## Social / rumor / unverified source

Social, rumor, and unverified sources are not valid as canonical evidence for filing facts or merge finalization.

They may be recorded only as explicitly unverified context after a later policy and safety review. Stage 5 v1 does not implement social scraping or rumor ingestion.

## Citation principles

Citations must remain source-specific.

```text
official filing facts cite official source first
issuer-release context cites issuer source separately
news-derived context cites news source separately
aggregator-derived context cites aggregator separately
do not collapse official and news citations into one
do not cite news source for facts that are only in official filings
do not cite official filing for claims that appear only in news context
```

## Citation object requirements

A portable citation object should preserve:

```text
source_name
source_tier
source_key
source_url
claim_supported
document_role
published_at
retrieved_at
raw_document_identity
raw_document_external_id
stable_external_id if applicable
event_id if applicable
overlay_id if applicable
```

## Document roles

Suggested document roles:

```text
official_filing
official_exchange_disclosure
official_issuer_release
news_article
secondary_aggregator_page
manual_verification_note
```

A document role should not imply source precedence by itself. Source tier and document role should both be stored.

## Claim support

Each citation must identify the claim it supports.

Examples:

```text
claim_supported: filing timestamp
claim_supported: document identity
claim_supported: issuer statement
claim_supported: article-reported market reaction
claim_supported: analyst interpretation
claim_supported: discrepancy note
```

## Conflict citation rule

When official and news sources conflict, both citations may be retained, but their supported claims must differ.

Example:

```text
official citation:
  claim_supported: official filing timestamp
  source_tier: official regulatory/exchange storage

news citation:
  claim_supported: article-reported timestamp claim
  source_tier: reputable news source
  conflict_flag: news_official_timestamp_conflict
```

## Citation display policy

User-facing citation display should prefer official citations for canonical filing facts and display overlay citations for context.

Suggested order:

```text
1. official filing citation
2. issuer release citation
3. news overlay citation
4. aggregator citation
5. unverified source citation, if ever enabled by later policy
```

## Redaction policy

Portable citations must never store secrets.

Forbidden in citation objects:

```text
API keys
Authorization headers
Subscription keys
cookies
session tokens
signed private URLs
local filesystem paths containing secrets
```

When an EDINET request shape is referenced, it must remain redacted:

```text
Subscription-Key=<redacted>
```

## Acceptance criteria for future implementation

Before source precedence or citation runtime code is added, the project must define:

```text
storage schema or metadata shape for source_tier
storage schema or metadata shape for document_role
citation object schema
claim_supported allowed values or validation policy
redaction test
fixture pair with official and overlay citations
manual verification plan
```
