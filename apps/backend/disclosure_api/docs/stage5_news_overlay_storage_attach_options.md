# Stage 5 news overlay storage attach options

This document compares storage attach paths for the first Stage 5 news overlay runtime.

This is a docs-only storage preflight. It does not add runtime code, source adapters, tests, database migrations, schedulers, scraping, or changes to locked regional runtimes.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 0e43756f7ca303ab1b3cd006060ee975e64349ad
base commit source: PR #65 Stage 5 Reuters news overlay fixture candidate
```

## Problem

The Reuters overlay fixture is intentionally attached to an existing locked TDnet official event.

The runtime must attach news-only context without changing official facts.

If the runtime reuses the same canonical event upsert path as official sources, it may accidentally replace official fields such as:

```text
headline
canonical_url
published_at
source_tier
official_source_url
portable_citations
source_meta
```

Therefore the storage attach path must be selected before runtime code is added.

## Option A: dedicated overlay attachment storage

Preferred long-term option.

Conceptual shape:

```text
news_overlay_attachments
  overlay_id unique
  canonical_event_id
  source_key
  article_external_id
  source_tier
  document_role
  article_title
  article_published_at
  article_retrieved_at
  overlay_context_type
  claim_supported
  overlay_claims json
  match_evidence json
  citations json
  conflict_flags json
  inserted_at
  updated_at
```

Required constraints:

```text
overlay_id unique
canonical_event_id required
article_external_id required
source_key required
canonical_event_id + article_external_id unique
```

Pros:

```text
strongest non-mutation boundary
supports multiple overlays per official event
supports clean deletion or correction of overlay without deleting official event
supports per-source provenance
supports later UI query path
```

Cons:

```text
requires database migration
requires schema module
requires query/read path updates
requires storage-level tests
```

## Option B: append-only canonical metadata attach

Possible short-term option only if strict before/after tests prove no official fields change.

Conceptual shape:

```text
canonical_feed_items.contract_v1.source_meta.stage5_news_overlay[]
canonical_feed_items.contract_v1.portable_citations[] append Reuters citation only
```

Mandatory guardrails:

```text
all official top-level fields remain byte-for-byte unchanged
all official source_meta fields remain unchanged except adding a new stage5_news_overlay namespace
all official citations remain unchanged and in place
Reuters citation is appended, not substituted
published_at remains official TDnet timestamp
canonical_url remains official TDnet PDF URL
headline remains official TDnet title
```

Pros:

```text
smaller implementation
may avoid migration
faster to show overlay in existing feed payloads
```

Cons:

```text
higher mutation risk
harder to remove overlay cleanly
harder to model multiple overlays
harder to distinguish official fields from overlay fields in old clients
```

## Option C: raw-document-only overlay staging

Lowest-risk staging option.

Conceptual shape:

```text
raw_documents stores Reuters article metadata fixture
raw_events stores overlay candidate event
canonical_feed_items unchanged
manual or future runtime reads staged overlay later
```

Pros:

```text
no canonical mutation
no new canonical event
low risk for locked official event contract
```

Cons:

```text
overlay is not visible in canonical feed
requires later attachment path
may delay Stage 5 product value
```

## Recommendation

Recommended next implementation path:

```text
Option A if database migration is acceptable.
Option C if a no-migration staging step is preferred.
Avoid Option B unless tests can prove byte-for-byte preservation of official fields.
```

## Required tests by option

### Option A tests

```text
overlay insert is idempotent by overlay_id
overlay insert does not update canonical_feed_items
overlay insert references existing canonical_event_id
overlay citation remains separate from official citation
overlay claims preserve canonicalFactOverride=false
storage count remains stable on repeated poll
```

### Option B tests

```text
before/after official top-level contract_v1 fields are byte-for-byte equal
before/after official source_meta excluding stage5_news_overlay is byte-for-byte equal
before/after official citations remain present
Reuters citation is appended, not replacing TDnet citations
repeated poll does not duplicate overlay metadata
```

### Option C tests

```text
raw_document insert is idempotent by article_external_id
raw_event insert is idempotent by overlay_id or article_external_id
canonical_feed_items count remains unchanged
canonical official item remains unchanged
future attach candidate can be queried by canonical_event_id
```

## Required manual smoke by option

Manual smoke should capture:

```text
official event still returns TDnet canonical fields
overlay attachment or staging row exists exactly once
Reuters overlay claims are visible in overlay namespace only
Reuters citation is separate from TDnet citation
repeated run is idempotent
no secret-bearing values are present
```

## Runtime no-go

Do not implement runtime until the selected option is explicitly recorded in the runtime PR body and tests match that option.

Runtime is blocked if:

```text
storage path mutates official facts
storage path cannot prove idempotency
storage path cannot preserve separate citation provenance
storage path requires live Reuters fetch in tests
storage path creates a news-only canonical event
```
