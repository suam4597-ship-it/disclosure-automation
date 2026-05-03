# Stage 6.5 duplicate group operator runbook lock close-out

This document locks the Stage 6.5 duplicate group operator runbook after the runbook, guardrails, and manual smoke documentation were merged.

## Scope

Stage 6.5 documents how operators should safely use the locked duplicate group operator workflow.

Stage 6.5 is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Lock evidence

```text
PR #159 Add duplicate group operator runbook
merge commit: dd32e57de585b724160723bc00ffbdf42728144e
scope: docs-only operator runbook, guardrails, manual smoke
```

## Locked runbook coverage

Stage 6.5 locks operator documentation for:

```text
operator pre-checks
list review procedure
detail review procedure
review_state_summary interpretation
action_event_summary interpretation
action selection guide
action request requirements
idempotency and retry procedure
post-action verification
failure handling
escalation triggers
forbidden operator behavior
public response guardrails
canonical no-mutation guardrails
provider/scheduler/live-fetch/materializer guardrails
redaction checklist
```

## Locked route usage

The runbook references only locked internal/operator-only read routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

The runbook references only locked internal/operator-only action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Operators must not use public APIs for duplicate group action state.

## Locked action mapping

The runbook preserves route-derived operation mapping:

```text
confirm -> confirm_duplicate_group
reject -> reject_duplicate_group
mark-review -> mark_duplicate_group_needs_review
clear-review-state -> clear_duplicate_group_review_state
```

Request bodies must not override route-derived action operation.

## Locked action request allowlist

Allowed action request fields remain:

```text
actor_id_hash
actor_permissions
roles
request_id_hash
idempotency_key_hash
operator_reason_redacted
result_status
redaction_status
pre_review_state
post_review_state
failure_code
created_at
```

Forbidden request material remains:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reasons
provider payloads
full article text
canonical payloads
private transport material
unbounded diagnostics
```

## Locked idempotency guidance

The locked idempotency identity remains:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

Same intended action retries should reuse the same idempotency key hash.

New intended actions should use a new idempotency key hash.

## Locked authorization guidance

Backend authorization remains authoritative.

Read-only permission must not authorize actions:

```text
duplicate_group:read
```

Action-specific permissions remain:

```text
duplicate_group:confirm
duplicate_group:reject
duplicate_group:mark_review
duplicate_group:clear_review_state
```

## Locked review state interpretation

The runbook may reference only bounded `review_state_summary` fields:

```text
review_state
last_action_operation
last_action_request_id_hash
last_action_idempotency_key_hash
reviewed_by_actor_id_hash
reviewed_at
review_reason_redacted
redaction_status
```

Missing review state must not be handled by manual DB writes or backfills.

## Locked action event summary interpretation

The runbook may reference only bounded `action_event_summary` fields:

```text
action_operation
required_permission
actor_id_hash
request_id_hash
idempotency_key_hash
result_status
pre_review_state
post_review_state
failure_code
redaction_status
inserted_at
```

The runbook preserves show-only and latest-five action event summary behavior.

Operators must not request unbounded action event history through read routes.

## Locked escalation metadata

Escalations should include only bounded metadata:

```text
group_id
action_operation
request_id_hash
idempotency_key_hash
actor_id_hash
result_status
redaction_status
failure category
inserted_at or reviewed_at if present
```

Escalations must not include raw/private/canonical/provider material.

## Locked forbidden operator behavior

Operators must not:

```text
manually write source_duplicate_group_review_states
manually write source_duplicate_group_action_events
change canonical_feed_items because of duplicate group review
create provider canonical feed items because of duplicate group review
create news-only canonical events because of duplicate group review
merge official TDnet events because of duplicate group review
override official facts or citations because of duplicate group review
trigger live provider fetch from duplicate group review
trigger scheduler work from duplicate group review
materialize duplicate groups from read/action/UI routes
paste raw actor/request/idempotency identifiers into comments or tickets
paste raw provider payloads/full article text/canonical payloads into comments or tickets
```

## Public response-shape lock

The runbook preserves that duplicate group operator actions must not change:

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

Public duplicate group review/action state fields remain absent.

## Canonical no-mutation lock

The runbook preserves that duplicate group operator actions must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Provider, scheduler, and materializer lock

The runbook preserves that duplicate group read/action/UI workflows must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups from read/action/UI routes
materialize overlays
change materializer behavior
```

## Redaction lock

The runbook, guardrails, manual-smoke docs, review comments, logs, and tickets must not contain:

```text
raw actor identifier
raw request identifier
raw idempotency key
unredacted operator reason
raw provider payload
full article text
canonical payload
private transport material
SQL detail
provider secret
request header
cookie
unbounded diagnostic blob
```

Allowed placeholders:

```text
REDACTED_OPERATOR_ID
REDACTED_REQUEST_ID
REDACTED_IDEMPOTENCY_KEY
REDACTED_OPERATOR_REASON
REDACTED_PROVIDER_PAYLOAD
```

## Future work gates

Before changing operator runbook behavior, require a docs PR that states scope, affected routes, redaction policy, idempotency impact, public response-shape impact, canonical policy, provider/scheduler/materializer impact, and manual smoke checklist.

Before any future duplicate group UI implementation, public response, scheduler, provider, materializer, canonical, or external integration work, require a separate design PR.

## Close-out validation

This close-out PR is docs-only. It must not change frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router, controllers, templates, UI routes, action endpoints, scheduler code, provider clients, live fetch code, feed/controller behavior, API behavior, feed behavior, materializer behavior, or canonical mutation behavior.
