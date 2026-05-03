# Stage 6.8 duplicate group public boundary close-out

This document closes out Stage 6.8 duplicate group public-boundary design after the boundary design, guardrails, and manual smoke documents were merged.

This close-out PR is documentation-only. It does not add or modify frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 74db2775fff7a67577a2d363abfe598cb2807c7a
base source: PR #174 Design Stage 6.8 duplicate group public boundary
stage: Stage 6.8 close-out
status: docs-only
```

## Stage 6.8 evidence

```text
PR #174 Design Stage 6.8 duplicate group public boundary
scope: docs-only boundary design, guardrails, and manual smoke
```

Stage 6.8 does not approve public exposure. It only locks the public-boundary policy and future gate requirements.

## Locked current policy

The current policy remains:

```text
public duplicate group review/action state fields are absent
operator UI remains internal/admin only
operator review state remains advisory-only and non-canonical
public feed/API response shapes remain unchanged
canonical records remain unchanged
```

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

No public route was added.

## Locked public surfaces

The following public surfaces remain unchanged and must not expose duplicate group review/action state:

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

## Locked forbidden public material

The following remain forbidden unless a future design gate explicitly approves a scoped public implementation:

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

## Locked future gate

Before any future public exposure implementation, a proposal must document:

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

## Locked redaction rule

Future public exposure must not render:

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

## Locked canonical rule

Any future public exposure must be read-only and must not:

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

## Locked provider, scheduler, and materializer rule

Future public exposure must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups from public read routes
materialize overlays
change materializer behavior
```

## Locked test gates

Future public exposure tests must prove:

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

## Future work gates

The next implementation work should be selected explicitly from one of these tracks:

```text
public exposure proposal only after a dedicated gate review
internal UI maintenance only with scoped route/API/action impact notes
frontend framework or asset pipeline only after a separate design PR
non-UI backend work only with separate stage design and guardrails
```

## Close-out validation

This close-out PR is docs-only.

It must not change frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router, controllers, templates, UI routes, action endpoints, scheduler code, provider clients, live fetch code, feed/controller behavior, API behavior, feed behavior, materializer behavior, or canonical mutation behavior.
