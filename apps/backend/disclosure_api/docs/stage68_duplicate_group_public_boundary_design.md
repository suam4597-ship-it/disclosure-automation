# Stage 6.8 duplicate group public boundary design

This document defines a docs-only public-boundary design after Stage 6.7 duplicate group operator UI polish was locked.

Stage 6.8 PR A is design-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 79d8328ef417b13d0bd1386c7be3b1e4a7fa16b1
base source: PR #173 Lock Stage 6.7 duplicate group UI polish
stage: Stage 6.8 PR A duplicate group public boundary design
status: docs-only
```

## Purpose

Stage 6.8 documents the boundary between internal duplicate group operator state and any future public exposure discussion.

The current policy remains:

```text
public duplicate group review/action state fields are absent
operator UI remains internal/admin only
operator review state remains advisory-only and non-canonical
public feed/API response shapes remain unchanged
canonical records remain unchanged
```

This design does not approve public exposure. It defines gates that must be satisfied before any future public exposure PR can be considered.

## Locked internal routes

Internal/admin UI routes remain:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

Internal/operator-only JSON APIs remain:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

No public route is added by this design.

## Current public boundary

The following public surfaces must not expose duplicate group review/action state:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
item.overlays[]
news_overlays[]
feed item_count
feed ordering
official TDnet fields
official citations
public API envelope
public feed envelope
```

The following remain forbidden unless a separate public exposure implementation PR is approved after this boundary design:

```text
public duplicate group IDs
public duplicate group confidence
public duplicate group members
public duplicate group match reasons
public review_state_summary
public action_event_summary
public operator action state
public operator reason
public idempotency metadata
public actor/request metadata
```

## Non-goals

This design does not authorize:

```text
public duplicate group UI
public duplicate group API
public feed duplicate group fields
public event duplicate group fields
public overlay duplicate group fields
public action state exposure
public review state exposure
public action history exposure
new public route namespace
new public schema fields
new public response envelope
canonical mutation
provider canonical item creation
news-only canonical event creation
official TDnet event merge
official fact override
official citation override
provider live fetch
scheduler work
materializer behavior changes
```

## Future public exposure gates

Before any public exposure PR, require a separate implementation proposal that states:

```text
exact public route or response field names
exact response envelope impact
redaction model
abuse/misinterpretation risk
operator metadata exclusion proof
canonical no-mutation proof
public feed ordering impact
public feed item_count impact
official TDnet field impact
official citation impact
cache/backward compatibility impact
test plan
rollback plan
```

The future proposal must prove that no raw/private operator or provider material can appear in public responses.

## Candidate public-safe summary model

If public exposure is ever considered, it should start with a minimal, non-operator, non-action summary.

Candidate fields for a future design discussion only:

```text
has_related_sources: boolean
related_source_count: integer
related_source_kinds: bounded enum list
```

Explicitly not approved in this PR:

```text
group_id
confidence
match_reasons
member IDs
provider names beyond already-public citations
review_state_summary
action_event_summary
operator action state
actor_id_hash
request_id_hash
idempotency_key_hash
operator_reason_redacted
```

## Required redaction rule

Any future public summary must be derived from already-public event/overlay relationships or a separate public-safe projection.

It must not derive directly from operator action tables or render:

```text
source_duplicate_group_action_events
source_duplicate_group_review_states
operator reason material
actor/request/idempotency metadata
raw provider payloads
full article text
canonical payloads
private transport material
unbounded diagnostics
```

## Required canonical rule

Any future public exposure must be read-only.

It must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

Operator review state remains internal advisory metadata and must not become canonical truth.

## Required provider, scheduler, and materializer rule

Any future public exposure must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups from public read routes
materialize overlays
change materializer behavior
```

## Required test gates

Before any public exposure implementation can merge, tests must prove:

```text
public event response shape is intentional and documented
public feed response shape is intentional and documented
operator fields remain absent
raw/private identifiers remain absent
unredacted operator reasons remain absent
provider payloads remain absent
canonical payloads remain absent
full article text remains absent
public feed ordering is unchanged unless explicitly approved
public feed item_count is unchanged unless explicitly approved
canonical data is not mutated
provider/scheduler/materializer side effects are absent
```

## Stop conditions

Stop and re-scope any future public exposure work if it:

```text
adds public duplicate group fields without a design gate
changes public response shapes without explicit approval
exposes operator review state
exposes operator action state
exposes action_event_summary
exposes actor/request/idempotency metadata
exposes unredacted operator reasons
exposes provider payloads or full article text
exposes canonical payloads
changes public feed ordering unexpectedly
changes public feed item_count unexpectedly
mutates canonical data
triggers provider/scheduler/live-fetch/materializer work
```
