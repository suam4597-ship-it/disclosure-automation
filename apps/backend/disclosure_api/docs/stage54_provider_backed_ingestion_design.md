# Stage 5.4 provider-backed ingestion design

This document defines the Stage 5.4 design for introducing provider-backed news overlay ingestion after Stage 5.3 locked multi-overlay behavior for Reuters and Bloomberg metadata fixtures.

This is a design document only. It does not add provider clients, credentials, live HTTP fetches, schedulers, migrations, runtime code, fixtures, tests, routes, feed/controller changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 03a2bc552777405e071a1d70fc944dae16108ee3
base commit source: PR #98 Close out Stage 5.3 multi-overlay lock
locked official source: jp_tdnet_timely_disclosure
locked overlay sources:
  - stage5_news_overlay_fixture
  - stage53_news_overlay_fixture
locked attachment table: news_overlay_attachments
locked API shape: item.overlays[]
locked feed shape: news_overlays[]
locked overlay order: Reuters then Bloomberg
stage: Stage 5.4 provider-backed ingestion design
status: design-only
```

## Goal

Stage 5.4 should define how real provider-backed ingestion can be introduced without weakening the Stage 5.3 source-of-truth rules.

The goal is not to fetch live provider data in this PR. The goal is to define the contract and guardrails for future provider-backed ingestion PRs.

## Non-goals

Stage 5.4 design does not authorize:

```text
live Reuters fetch in this PR
live Bloomberg fetch in this PR
provider credentials in repository files
provider request headers in fixtures/logs/tests
signed private URLs in fixtures/logs/tests
full article text storage
provider canonical feed item creation
news-only canonical event creation
automatic canonical fact override
new public API routes
feed/controller response shape changes
scheduler integration
schema/migration changes
```

## Source-of-truth rule

The official TDnet event remains the canonical anchor.

Provider-backed news data may only attach context to an existing official TDnet canonical event unless a later, separately designed stage explicitly changes this rule.

Locked rule:

```text
TDnet canonical event: source of truth
default provider mode: attach_only
canonical_fact_override: false
provider data: non-canonical overlay context
```

Provider-backed ingestion must not copy provider headline, timestamp, URL, or article facts into official TDnet canonical fields.

## Provider-backed ingestion boundary

Future provider-backed ingestion should be split into clear layers:

```text
provider config boundary
provider client boundary
provider response normalization boundary
official-event matching boundary
raw staging boundary
attachment materialization boundary
read model/API/feed boundary
```

### Provider config boundary

Provider credentials and request configuration must be supplied only through runtime configuration, environment variables, or a secret manager.

Repository files may include only redacted sample keys such as:

```text
REDACTED_REUTERS_API_KEY
REDACTED_BLOOMBERG_API_KEY
```

Repository files must not include real values for:

```text
Subscription-Key
Authorization
Cookie
provider bearer tokens
provider usernames/passwords
signed private URLs
```

### Provider client boundary

Future provider clients should be explicit opt-in and disabled by default in test/dev unless a controlled manual smoke explicitly enables them.

Recommended behavior:

```text
use_live_fetch: false by default
manual trigger required for live fetch
bounded timeout
bounded retry count
no scheduler in the first implementation PR
no logging of request headers or response body text
redacted error metadata only
```

### Provider response normalization boundary

Provider responses should normalize into a metadata-only overlay candidate before raw staging.

Allowed normalized fields:

```text
provider
source_key
article_external_id
title or headline metadata
published_at
url
language
jurisdiction
matched official identifiers
citation metadata
overlay claims metadata
redacted fetch diagnostics
```

Disallowed normalized fields:

```text
full article body
request headers
raw provider credentials
signed private URLs
cookies
authorization tokens
unbounded provider payload dumps
```

### Official-event matching boundary

A provider-backed overlay may become visible only if it directly matches an official TDnet event.

Recommended direct match evidence:

```text
canonical_event_id equals official TDnet event id
matchedCanonicalEventId equals official TDnet event id
matchedOfficialStableExternalId equals official stable external id
provider article metadata references the TDnet disclosure id
```

If direct official evidence is missing or ambiguous, the overlay must remain hidden or quarantined.

Recommended hidden states:

```text
hidden_missing_direct_official_identifier
hidden_conflict_requires_review
hidden_source_not_allowed
hidden_provider_fetch_error
hidden_redaction_violation
```

### Raw staging boundary

Raw staging should remain idempotent and metadata-only.

Required raw staging behavior:

```text
stable external_event_key per provider article
stable raw document external id per provider article metadata
canonical_feed_mutation=false
news_only_event_creation=false
overlay_mode=attach_only
canonical_fact_override=false
no full article body
no provider credentials
```

### Attachment materialization boundary

Materialization into `news_overlay_attachments` should preserve the Stage 5.2/5.3 rules:

```text
only visible, directly matched overlays materialize as visible attachments
canonical_fact_override=false
source_tier=reputable_news_source
document_role=news_article
overlay_mode=attach_only
no provider canonical feed items
idempotent upsert by official item + provider article identity
```

### Read model/API/feed boundary

Stage 5.4 provider-backed ingestion must preserve locked response shapes:

```text
read model: item.overlays[]
API: item.overlays[]
feed: news_overlays[]
```

It must not change:

```text
top-level API response shape
feed item count
feed item ordering
official TDnet fields
official TDnet citations
official source URL
```

## Ordering policy

Provider-backed overlays should continue to use deterministic ordering.

Locked Stage 5.3 order for the fixture pair remains:

```text
1. Reuters
2. Bloomberg
```

For future provider-backed overlays, ordering should be based on persisted attachment fields, not live fetch timing.

Recommended order:

```text
1. display_state
2. published_at
3. provider priority
4. article_external_id
```

Provider priority must be explicit and tested if introduced.

## Citation policy

Provider-backed citations must remain separated by role.

Required citation contract:

```text
official TDnet citations:
  isCanonicalSource=true
  sourceKey=jp_tdnet_timely_disclosure

overlay citations:
  isCanonicalSource=false
  sourceKey=<provider overlay source key>
```

Flattened citations may contain official citations before overlay citations, but non-canonical overlay citations must remain filterable by `isCanonicalSource=false`.

## Redaction policy

Provider-backed ingestion must be redaction-first.

Never persist or log:

```text
Subscription-Key values
Authorization header values
Cookie header values
provider credentials
provider request headers
signed private URLs
full article body text
unredacted provider error payloads
```

Allowed diagnostic fields should be bounded and redacted:

```text
provider
request_id hash or redacted request id
status code
retry count
timeout flag
redacted error class
fetched_at timestamp
```

## Failure policy

Provider fetch failure must not impact official TDnet feed availability.

Required behavior:

```text
official TDnet ingestion remains independent
provider failures do not create canonical events
provider failures do not mutate official feed items
provider failures can create hidden diagnostic overlay candidates only if redacted
API/feed may continue returning existing materialized overlays
```

## Security and compliance notes

Stage 5.4 provider-backed ingestion must treat provider data as externally licensed content.

Default storage posture:

```text
store metadata and citations only
avoid storing full article text
avoid storing raw provider payloads
store only what is needed for overlay display and traceability
```

Any future decision to store full article text requires a separate design, legal/compliance review, storage policy, redaction policy, and tests.

## Recommended first implementation slice after design

The first implementation PR after this design should not connect to a live provider.

Recommended first slice:

```text
provider ingestion boundary interfaces
redacted provider fetch result structs/maps
static offline provider adapter used only in tests
no credentials
no network
no scheduler
no migrations
no feed/API shape changes
```

This creates a safe seam for later provider-backed ingestion without increasing runtime blast radius.

## Stop conditions

Do not merge a Stage 5.4 implementation PR if it:

```text
adds real provider credentials
logs provider request headers
stores full article body text
performs live provider fetch by default
adds scheduler-triggered provider fetches before manual-mode lock
creates provider canonical feed items
creates news-only canonical events
mutates official TDnet canonical fields
changes locked API/feed response shapes unexpectedly
breaks Stage 5.3 multi-overlay ordering or citation separation
```
