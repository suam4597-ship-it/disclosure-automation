# Stage 6.8 duplicate group public boundary guardrails

This checklist defines guardrails for any future duplicate group public exposure discussion.

Stage 6.8 PR A is docs-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline guardrails

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 79d8328ef417b13d0bd1386c7be3b1e4a7fa16b1
base source: PR #173 Lock Stage 6.7 duplicate group UI polish
```

## Current locked policy

Current policy remains:

```text
public duplicate group review/action state fields are absent
operator UI remains internal/admin only
operator review state remains advisory-only and non-canonical
public feed/API response shapes remain unchanged
canonical records remain unchanged
```

## Forbidden public fields

Do not expose these fields publicly unless a future design gate explicitly approves them:

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

## Public response-shape guardrails

Do not change these public surfaces in Stage 6.8 PR A:

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

## Future design gate guardrails

Before any public exposure implementation, require a proposal that documents:

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

## Redaction guardrails

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

## Canonical guardrails

Future public exposure must be read-only and must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Provider, scheduler, and materializer guardrails

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

## Test gate guardrails

Future implementation tests must prove:

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

Stop and re-scope if a future PR:

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
