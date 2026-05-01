# Stage 5 cross-source merge policy

This document defines the Stage 5 cross-source merge policy for official disclosure events and news overlay attachments.

This document is design-only. It does not add runtime code, merge logic, source adapters, fixtures, tests, database migrations, schedulers, or changes to locked regional runtimes.

## Baseline

Stage 5 begins from the locked official-disclosure baseline:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 7983785bb04d9ad3718117ab24f807599046ee96
```

Existing source-specific identifiers remain locked.

Do not mutate:

```text
event_id
stable_external_id
raw_document_external_id
raw document identity
source_key
adapter_key
locked cursor semantics
locked runtime sample scope
```

## Definitions

```text
event_id:
  source-specific canonical event identity

stable_external_id:
  stable source-specific external identity used by the adapter contract

raw_document_external_id:
  source-specific raw document identity

duplicate_group_key:
  cross-source grouping identity for records that describe the same real-world event

overlay attachment:
  a news or secondary-source record attached to an existing official canonical event
```

## Core rule

The official event remains canonical.

```text
official event_id remains unchanged
news does not create a replacement event_id for the same official event
news does not overwrite official filing facts
news overlay attaches to the canonical event
related sources may share a duplicate_group_key
```

## Official-to-official merge policy

Official sources may be grouped when deterministic evidence indicates they describe the same real-world event.

Allowed evidence:

```text
same issuer identifiers plus same event family plus same effective date
same issuer identifiers plus same transaction identifiers
same issuer identifiers plus same filing identifiers
explicit known stable-id mapping
explicit official document URL cross-reference
```

A match should not be finalized from issuer name similarity alone.

A match should not be finalized from publication timing alone.

## News overlay merge policy

A news overlay may attach to an official canonical event when deterministic candidate keys or explicit evidence exist.

Candidate evidence:

```text
issuer identifiers
issuer name and ticker mentions
event family
canonical event type
headline/title entity mentions
publication window
official document URL referenced in article
transaction identifiers
filing identifiers
named parties
amounts, dates, or security identifiers that match official data
```

A news overlay candidate must retain match evidence.

Suggested match evidence shape:

```text
candidate_event_id
matched_issuer_identifier
matched_event_family
matched_publication_window
matched_official_url
matched_transaction_identifier
matched_parties
matched_amounts_or_dates
confidence_reason
```

## LLM boundary

LLM-only duplicate decisions are forbidden.

```text
LLM may suggest candidate matches.
LLM may summarize evidence.
LLM may classify article context.
LLM must not finalize duplicate_group_key.
LLM must not mutate canonical event identity.
LLM must not overwrite official facts.
```

Every finalized merge or overlay attachment must have deterministic candidate keys or explicit source evidence.

## Publication window policy

Publication timing can support a match but cannot stand alone.

Initial suggested windows:

```text
official filing to news article: 0 to +7 days
news article before official filing: -2 to 0 days, only if explicit identifiers or official URL exist
older background article: allowed only as related context, not duplicate evidence by timing alone
```

The implementation stage may narrow these windows per source family after fixtures are frozen.

## Duplicate group assignment

A duplicate_group_key may group official and overlay sources, but it must not replace source-specific identifiers.

Suggested generation policy:

```text
prefer existing official canonical event_id as seed when one official event anchors the group
use deterministic normalized issuer/event/date components only after policy freeze
never include news-only opaque identifiers as the sole group key seed
```

The exact key format is deferred until the Stage 5 fixture/contract PR.

## Conflict policy

When official and news sources disagree:

```text
official source wins for legal filing facts
news value may be stored as reported_value or overlay_claim
conflict flag must be preserved
citations must remain source-specific
no silent overwrite is allowed
```

Candidate conflict flags:

```text
news_official_timestamp_conflict
news_official_amount_conflict
news_official_parties_conflict
news_unconfirmed_claim
official_update_supersedes_news
```

## Reversibility

Stage 5 merge and overlay changes should be reversible.

Removing a news overlay must not delete or modify the official canonical event.

Removing a duplicate_group_key must not delete or modify:

```text
event_id
stable_external_id
raw_document_external_id
raw document identity
locked source cursor
```

## Acceptance criteria for future implementation

Before runtime implementation, the project must have:

```text
frozen overlay source contract
frozen official + overlay fixture pair
explicit duplicate_group_key format
explicit match evidence schema
idempotency test
HTTP smoke test
storage dedupe or merge check
manual smoke plan
lock close-out document
```
