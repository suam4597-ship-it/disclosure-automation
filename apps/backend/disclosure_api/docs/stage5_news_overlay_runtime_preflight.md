# Stage 5 news overlay runtime preflight

This document gates the first Stage 5 news overlay runtime slice after the Reuters overlay fixture candidate.

This is a docs-only preflight. It does not add runtime code, source adapters, tests, database migrations, schedulers, scraping, or changes to locked regional runtimes.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 0e43756f7ca303ab1b3cd006060ee975e64349ad
base commit source: PR #65 Stage 5 Reuters news overlay fixture candidate
fixture payload: priv/fixtures/source_payloads/stage5_news_overlay_fixture_jp_tdnet_140120260430515474_reuters_jp_article_001.json
```

## Why preflight is required

Existing official-disclosure runtime adapters normalize source records into canonical feed items.

The Stage 5 overlay runtime must not simply normalize a Reuters overlay into a replacement canonical item because that could accidentally mutate or overwrite the locked official TDnet canonical event.

The overlay runtime must be attach-only.

## Runtime write-path decision

The first runtime implementation must choose an attach-only write path before code is added.

Allowed implementation shapes:

```text
1. separate overlay attachment storage linked by canonical_event_id
2. append-only overlay metadata table keyed by overlay_id
3. safe metadata attach path that preserves existing official canonical fields byte-for-byte
```

Forbidden implementation shapes:

```text
canonical_feed_items upsert that overwrites official contract_v1 with Reuters-derived fields
raw_event normalization that changes official event_id semantics
using Reuters article as canonical_url for the official event
using Reuters article published_at as official published_at
using Reuters article title as official headline
using Reuters citation as the official filing citation
```

## Required non-mutation checks

Before runtime merge, tests or manual checks must prove these official fields stay unchanged:

```text
event_id
stable_external_id
raw_document_external_id
raw document identity
published_at_local
published_at_utc
filing_date_local
canonical_event_type
event_family
official_source_url
official_source_name
portable official citations
```

## Required overlay attach checks

Runtime must prove that overlay content is added as overlay-only context.

Required checks:

```text
overlay_id is deterministic
overlay_id is stable across repeated poll
overlay attaches to existing canonical_event_id
overlayClaims are preserved
overlayClaims have canonicalFactOverride=false
Reuters citation remains separate from TDnet citation
match_evidence is preserved
conflict_flags are preserved
source_tier is reputable_news_source
document_role is news_article
```

## Required fixture scope

The first runtime slice may use only this fixture:

```text
stage5_news_overlay_fixture_jp_tdnet_140120260430515474_reuters_jp_article_001.json
```

No additional Reuters rows, Bloomberg rows, live article fetches, or scraping may be added in the first runtime PR.

## Required source contract

```text
source_key: stage5_news_overlay_fixture
adapter_key: stage5_news_overlay_fixture_v1
source_tier: reputable_news_source
document_role: news_article
overlay_mode: attach_only
news_only_event_creation: forbidden
```

## Direct article fetch boundary

The fixture was created from user-supplied public article metadata.

The first runtime may remain fixture-only and must not fetch the Reuters URL during automated tests.

Before runtime lock close-out, one of these must be recorded:

```text
fixture-only runtime lock path accepted, with no network fetch requirement
or
direct article fetch/access verified manually and documented without storing copyrighted article text or secrets
```

Do not store full Reuters article text in the repository.

Do not bypass paywalls, copy protected full text, store cookies, or store signed URLs.

## Storage design options to evaluate

The implementation PR must explicitly document which option it chooses.

### Option A: dedicated overlay attachment storage

Preferred long-term design.

```text
news_overlay_attachments table or equivalent schema
overlay_id unique
canonical_event_id foreign/key reference
source_key
article_external_id
overlay_claims json
match_evidence json
citations json
conflict_flags json
```

Pros:

```text
best non-mutation boundary
supports multiple overlays per official event
supports removal without deleting official event
```

Cons:

```text
requires migration
requires new query path
```

### Option B: append-only canonical metadata attach

Possible only if the storage layer can append overlay metadata without changing official fields.

```text
canonical_feed_items.contract_v1.source_meta.stage5_news_overlay appended
no official fields changed
portable citations appended without replacing official citations
```

Pros:

```text
smaller runtime change
may avoid migration
```

Cons:

```text
higher risk of accidental official field mutation
requires strict before/after tests
```

### Option C: raw-document-only overlay staging

Possible short-term staging option.

```text
store Reuters overlay fixture as raw_document and raw_event only
no canonical feed mutation
manual query or future runtime consumes staged overlay later
```

Pros:

```text
lowest mutation risk
no canonical overwrite
```

Cons:

```text
overlay not visible in feed yet
requires future attach path
```

## Recommended next PR

Do not implement full runtime until the storage attach path is chosen.

Recommended next PR:

```text
Stage 5 news overlay storage attach design
```

It should decide between Option A, B, and C and include exact non-mutation test expectations.

## No-go conditions for runtime implementation

Do not proceed to runtime implementation if:

```text
implementation would overwrite canonical_feed_items.contract_v1 official fields
implementation cannot prove official IDs remain unchanged
implementation requires Reuters network fetch in tests
implementation stores full article text
implementation stores secret-bearing values
implementation creates a news-only canonical event
implementation finalizes match via LLM-only decision
```

## Acceptance criteria for this preflight PR

```text
changed files are limited to Stage 5 docs
no runtime code is added
no adapter is added
no fixture payload is added
no test is added
no migration is added
no scheduler change is added
runtime implementation is explicitly blocked until attach-only storage path is chosen
```
