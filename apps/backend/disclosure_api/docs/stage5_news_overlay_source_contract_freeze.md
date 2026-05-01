# Stage 5 news overlay source contract freeze

This document freezes the first Stage 5 news overlay source contract.

This is a docs-only contract-freeze. It does not add runtime code, source adapters, fixtures, tests, database migrations, schedulers, scraping, or changes to locked regional runtimes.

## Baseline

This contract follows the Stage 5 design PR:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: f62847aec3213830023bfd7de3a0587d02dafc36
base commit source: PR #62 Stage 5 news overlay and cross-source merge design
```

Existing official-disclosure runtimes remain locked.

Do not mutate:

```text
event_id
stable_external_id
raw_document_external_id
raw document identity
source_key for locked official sources
adapter_key for locked official sources
locked cursor semantics
locked runtime sample scope
```

## Frozen overlay source contract

The first Stage 5 overlay source is a fixture-backed news overlay source candidate.

```text
source_key: stage5_news_overlay_fixture
adapter_key: stage5_news_overlay_fixture_v1
source_tier: reputable_news_source
document_role: news_article
runtime_scope: disabled in this PR
network_access: forbidden in this PR
fixture_count: 0 in this PR; 1-2 future fixture rows only
overlay_mode: attach_only
news_only_event_creation: forbidden
```

The source is intentionally fixture-backed so the future runtime can be verified with deterministic inputs before any provider integration or scraping exists.

## Scope boundary

Allowed by this contract:

```text
define overlay source identity
define article identity shape
define citation object requirements
define claim_supported values
define timestamp semantics
define match evidence requirements
define redaction rules
define future fixture constraints
```

Forbidden by this contract:

```text
news overlay runtime code
cross-source merge runtime code
new production adapter
network fetch
news scraping
social scraping
provider API integration
fixture files in this PR
tests in this PR
database migrations
scheduler changes
mutation of locked official runtimes
news-only event creation
LLM-only duplicate decisions
```

## Article identity shape

Future fixture records must include a deterministic article external id.

```text
article_external_id: NEWS-FIXTURE:{jurisdiction}:{official_source_key}:{official_event_token}:{article_token}
```

Rules:

```text
jurisdiction must be lowercase ISO-like project token such as jp, cn, us, uk, eu, tw
official_source_key must reference the official source family being overlaid
official_event_token must be derived from the locked official event or stable external id
article_token must be stable across repeated fixture loads
article_external_id must not depend on mutable article title alone
article_external_id must not contain secrets
```

Example shape only:

```text
NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:article-001
```

This example is a shape example, not a fixture and not runtime data.

## Overlay id shape

The future runtime may derive overlay_id from the official canonical event and the article external id.

```text
overlay_id: news_overlay:{canonical_event_id}:{article_external_id_hash}
```

Rules:

```text
overlay_id must be deterministic
overlay_id must be stable across repeated ingestion
overlay_id must not replace event_id
overlay_id must not replace stable_external_id
overlay_id must not replace raw_document_external_id
overlay_id must not contain secrets
overlay_id must not depend on LLM output
```

The exact hash implementation is deferred to the future runtime PR.

## Article URL semantics

A future fixture article may include a source_url only if it is safe to persist.

Allowed:

```text
public article URL
public archive URL
manual fixture URL placeholder with no secret-bearing query params
```

Forbidden:

```text
signed URLs
session URLs
Authorization-bearing URLs
Subscription-Key values
API keys
cookies
tracking tokens that contain user identity
local filesystem paths containing secrets
```

If a URL cannot be safely persisted, the fixture must use a redacted source_url and a separate note explaining why.

## Timestamp semantics

Future fixture records must preserve article publication and retrieval timestamps.

```text
article_published_at:
  required when known
  ISO 8601 timestamp
  preserve original timezone when available
  also normalize to UTC in runtime output if implementation needs it

article_retrieved_at:
  required for fixture verification
  ISO 8601 timestamp
  may be fixture creation or manual retrieval timestamp
```

Publication timing may support a match, but it cannot be the only match evidence.

## Claim support values

Initial allowed claim_supported values:

```text
secondary_confirmation
article_reported_market_reaction
article_reported_background
issuer_comment_reported_by_news
analyst_comment_reported_by_news
transaction_context_reported_by_news
discrepancy_note
```

A claim_supported value must describe the article-derived claim, not the official filing fact.

Official filing facts must cite the official source first.

## Overlay context types

Initial allowed overlay_context_type values:

```text
secondary_confirmation
market_reaction
reported_background
issuer_comment
analyst_comment
transaction_context
discrepancy_note
```

The overlay_context_type must not change canonical_event_type.

## Citation object contract

Future overlay citations must preserve per-source provenance.

Required fields:

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

Optional fields:

```text
raw_document_identity
raw_document_external_id
stable_external_id
conflict_flag
match_evidence_ref
```

The citation object must not collapse official and news citations into one citation.

## Attachment contract

The future overlay attachment must be attach-only.

Required attachment fields:

```text
overlay_id
canonical_event_id
article_external_id
source_key
source_tier
document_role
article_title
article_published_at
article_retrieved_at
overlay_context_type
claim_supported
citation
match_evidence
conflict_flags
```

Rules:

```text
canonical_event_id must refer to an existing official canonical event
news overlay must not create a new canonical event
news overlay must not replace official filing facts
news overlay must not overwrite official timestamps
news overlay must not overwrite official stable_external_id
news overlay must not overwrite official raw document identities
```

## Redaction contract

No secret-bearing value may be persisted in future fixture data, citations, metadata, logs, or docs.

Forbidden:

```text
API keys
Authorization headers
Subscription keys
cookies
session tokens
signed private URLs
unredacted EDINET Subscription-Key values
```

Any EDINET request shape must remain:

```text
Subscription-Key=<redacted>
```

## Future fixture constraints

The next fixture PR may add only 1-2 manually curated overlay fixture rows.

Fixture rows must:

```text
reference a locked official canonical event
include deterministic article_external_id
include source_tier and document_role
include article_published_at and article_retrieved_at
include claim_supported and overlay_context_type
include explicit match evidence
include citation object
avoid all secret-bearing values
```

Fixture rows must not:

```text
fetch network data during tests
scrape news pages
create news-only canonical events
mutate official fixture values
mutate official event IDs
mutate official stable external IDs
mutate official raw document identities
```

## Acceptance criteria for this contract-freeze PR

```text
changed files are limited to Stage 5 docs
no runtime code is added
no source adapter is added
no fixture is added
no test is added
no migration is added
no scheduler change is added
news-only event creation remains forbidden
LLM-only duplicate decisions remain forbidden
locked official runtime identifiers remain immutable
```
