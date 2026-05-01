# Stage 5 duplicate group policy

This document defines the Stage 5 duplicate group policy for cross-source grouping.

This document is design-only. It does not add runtime code, source adapters, fixtures, tests, database migrations, schedulers, scraping, or changes to locked regional runtimes.

## Purpose

Stage 5 introduces a duplicate_group_key as a cross-source grouping identity for records that describe the same real-world event.

A duplicate_group_key is not a replacement for source-specific canonical identifiers.

## Identifier boundaries

```text
event_id:
  source-specific canonical event identity

stable_external_id:
  source-specific stable external identity

raw_document_external_id:
  source-specific raw document identity

duplicate_group_key:
  cross-source grouping identity for the same real-world event
```

Existing locked identifiers must not be mutated.

Do not mutate:

```text
event_id
stable_external_id
raw_document_external_id
raw document identity
source_key
adapter_key
locked cursor semantics
```

## Core policy

```text
official single-source locked runtimes keep existing event_id
duplicate_group_key can be introduced or expanded in Stage 5
duplicate_group_key must not replace event_id
duplicate_group_key must not replace stable_external_id
duplicate_group_key must not replace raw_document_external_id
```

A duplicate group may contain:

```text
one official canonical event
multiple official canonical events from different official sources
one or more issuer releases
one or more news overlay attachments
one or more secondary aggregator records, if later enabled
```

Stage 5 v1 should prefer groups anchored by at least one official canonical event.

## News-only groups

Stage 5 v1 forbids news-only event creation.

Therefore, a news-only duplicate group must not create a canonical event in Stage 5 v1.

```text
news-only duplicate_group_key without official anchor: forbidden for canonical event creation
news-only candidate cluster for later review: may be deferred to Stage 5.5 or Stage 6
```

## Group anchor policy

Initial group anchor preference:

```text
1. official regulatory/exchange event
2. official issuer release, only if no regulatory/exchange source exists and later policy allows it
3. reputable news source, not allowed as Stage 5 v1 canonical anchor
```

When an official canonical event exists, the group should be anchored to that event without changing its event_id.

## Candidate duplicate evidence

Duplicate group membership requires deterministic evidence or explicit source evidence.

Allowed evidence examples:

```text
same issuer identifier
same ticker or security identifier
same event family
same canonical event type
same effective date
same filing date
same transaction identifier
same document identifier
same official document URL
same named parties
same reported amount or consideration
explicit official cross-reference
```

Weak evidence that cannot stand alone:

```text
similar issuer name only
similar title only
publication time only
LLM semantic similarity only
market movement only
```

## LLM boundary

LLM-only duplicate decisions are forbidden.

```text
LLM may suggest candidate duplicate groups.
LLM may summarize match evidence.
LLM may classify context.
LLM must not finalize duplicate_group_key.
LLM must not mutate event_id.
LLM must not mutate stable_external_id.
LLM must not mutate raw_document_external_id.
```

Every finalized duplicate group assignment must have deterministic candidate keys or explicit evidence.

## Duplicate group key format

The exact duplicate_group_key format is deferred until the Stage 5 contract-freeze and fixture PR.

Design constraints for the future format:

```text
deterministic
stable across repeated ingestion
source-neutral where possible
anchored to official canonical event when available
safe to compute without secrets
safe to expose in portable metadata
not dependent on LLM output
not dependent on mutable news article titles alone
```

Possible seed options for later evaluation:

```text
official canonical event_id seed
normalized issuer identifier + event family + effective date seed
explicit transaction identifier seed
explicit official URL hash seed
```

No seed format is finalized in this docs-only PR.

## Group expansion policy

A duplicate group may be expanded when new evidence appears.

Expansion must preserve:

```text
existing event_id values
existing stable_external_id values
existing raw_document_external_id values
existing official citations
existing source-specific provenance
```

Group expansion must record why a new source was added.

Suggested evidence record:

```text
duplicate_group_key
candidate_source_key
candidate_record_id
matched_event_id
match_evidence
match_decision_source
created_at
```

## Group removal policy

A mistaken duplicate group membership should be removable without deleting the underlying official event or raw documents.

Removal must not delete:

```text
official canonical event
raw event
raw document
canonical item source
official citation
locked cursor
```

## Conflict and ambiguity

If duplicate evidence is ambiguous, do not finalize group membership.

The system may retain a candidate for manual review, but Stage 5 v1 should not create ambiguous runtime merge behavior.

Candidate ambiguity flags:

```text
multiple_possible_official_matches
issuer_identifier_missing
only_title_similarity
publication_window_only
conflicting_transaction_identifiers
conflicting_parties
conflicting_amounts
```

## Acceptance criteria for future implementation

Before duplicate_group_key runtime implementation, the project must define:

```text
exact duplicate_group_key format
match evidence schema
candidate ambiguity policy
fixture pair for official + overlay source
fixture pair for official + official source if applicable
idempotency test
storage-level duplicate group check
manual verification plan
lock close-out document
```
