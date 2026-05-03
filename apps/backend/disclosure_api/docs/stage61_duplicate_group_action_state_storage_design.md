# Stage 6.1 duplicate group action state storage design

This document defines a docs-only design for future internal duplicate group operator action state and event storage after Stage 6.0 was locked.

This PR is design-only. It does not add migrations, schema modules, runtime write code, routes, controllers, UI, action endpoints, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: c1ef26f81bcb3401a10a5df9e8a7a90e9562f66f
base source: PR #142 Lock Stage 6.0 duplicate group operator actions
stage: Stage 6.1 PR A duplicate group action state storage design
status: docs-only
locked Stage 5.9 storage: source_duplicate_groups and source_duplicate_group_members
locked Stage 5.9 read route: GET /api/admin/duplicate-groups and GET /api/admin/duplicate-groups/:group_id
locked Stage 6.0 action contract: pure no-op action request validation
locked Stage 6.0 event contract: pure no-op event validation
locked Stage 6.0 authorization gate: pure authorization for no-op previews
```

## Goal

Define future internal storage for duplicate group operator review state and operator action event history before implementing any migration or DB write.

The future storage should allow the system to remember bounded operator decisions for internal duplicate groups while preserving Stage 5.9 and Stage 6.0 guardrails.

## Non-goals

This design does not authorize or implement:

```text
migration files
schema modules
runtime DB writes
event writes
action endpoints
routes
controllers
UI
scheduler work
provider clients
live provider fetch
public duplicate group fields
public API response-shape changes
public feed response-shape changes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event merge
official fact override
official citation override
```

## Candidate internal tables

Future implementation should use internal-only tables.

Recommended tables:

```text
source_duplicate_group_review_states
source_duplicate_group_action_events
```

These tables are internal/operator-only and must not be used as public API/feed response tables.

## Review state table design

Candidate table:

```text
source_duplicate_group_review_states
```

Purpose:

```text
store the latest bounded operator review state for one duplicate group
```

Candidate columns:

```text
id
group_id
review_state
last_action_operation
last_action_request_id_hash
last_action_idempotency_key_hash
reviewed_by_actor_id_hash
reviewed_at
review_reason_redacted
redaction_status
inserted_at
updated_at
```

Recommended uniqueness:

```text
unique group_id
```

Allowed review states:

```text
unknown
confirmed_by_operator
rejected_by_operator
needs_review
cleared
```

Allowed last action operations:

```text
confirm_duplicate_group
reject_duplicate_group
mark_duplicate_group_needs_review
clear_duplicate_group_review_state
```

## Action event table design

Candidate table:

```text
source_duplicate_group_action_events
```

Purpose:

```text
store bounded redacted operator action event history for duplicate groups
```

Candidate columns:

```text
id
group_id
action_operation
required_permission
actor_id_hash
request_id_hash
idempotency_key_hash
operator_reason_redacted
result_status
pre_review_state
post_review_state
failure_code
redaction_status
inserted_at
```

Recommended uniqueness:

```text
unique group_id + action_operation + actor_id_hash + idempotency_key_hash
```

The uniqueness policy should support safe retries without duplicate event rows.

## Relationship to Stage 5.9 storage

Future storage should reference duplicate groups by deterministic `group_id` only.

It must not:

```text
modify source_duplicate_groups columns in the same PR unless separately designed
modify source_duplicate_group_members columns in the same PR unless separately designed
change Stage 5.9 materializer behavior
change Stage 5.9 read projection behavior
change Stage 5.9 read route behavior
```

A future migration may add a foreign key only if it remains internal and does not alter public response behavior.

## Idempotency policy

Future runtime writes should be idempotent.

Recommended idempotency identity:

```text
group_id
action_operation
actor_id_hash
idempotency_key_hash
```

Future write behavior should:

```text
return the existing action event for duplicate retries
avoid duplicate event rows
avoid conflicting review state updates for the same idempotency identity
preserve bounded redacted fields only
```

Future write behavior should reject:

```text
raw idempotency keys
raw request bodies
raw actor identifiers
provider payloads
full article text
canonical payloads
```

## Review state transition policy

Candidate transitions:

```text
confirm_duplicate_group -> confirmed_by_operator
reject_duplicate_group -> rejected_by_operator
mark_duplicate_group_needs_review -> needs_review
clear_duplicate_group_review_state -> cleared
```

Future implementation should validate transition intent through Stage 6.0 contracts before any DB write.

Future implementation should not infer canonical disclosure truth from a review state.

Review state is advisory internal metadata only.

## Write ordering policy

Recommended future runtime flow:

```text
1. validate action request contract
2. validate authorization gate
3. build bounded event through audit/event contract
4. insert or reuse idempotent action event
5. update latest review state
6. return bounded internal operator result
```

Future implementation must use a DB transaction if both event and review state are written.

If event write succeeds and state update fails, the operation should roll back or return a bounded failure without partial side effects.

## Allowed stored fields

Allowed review state fields:

```text
group_id
review_state
last_action_operation
last_action_request_id_hash
last_action_idempotency_key_hash
reviewed_by_actor_id_hash
reviewed_at
review_reason_redacted
redaction_status
inserted_at
updated_at
```

Allowed action event fields:

```text
group_id
action_operation
required_permission
actor_id_hash
request_id_hash
idempotency_key_hash
operator_reason_redacted
result_status
pre_review_state
post_review_state
failure_code
redaction_status
inserted_at
```

## Forbidden stored fields

Future storage must reject:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reason
raw provider bodies
full article text
provider secret values
provider transport metadata
request header values
response header values
cookie values
canonical feed payloads
provider canonical creation payloads
raw body similarity payloads
full text similarity payloads
unbounded diagnostics
```

## Public response guardrails

Future storage work must not change:

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

Public duplicate group action state fields remain absent unless a future public response-shape design explicitly changes that policy.

## Canonical no-mutation guardrails

Future storage work must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Provider and scheduler guardrails

Future storage work must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
read provider credentials
store provider credentials
store provider transport metadata
materialize duplicate groups
materialize overlays
```

## Future implementation sequence

Recommended sequence after this design:

```text
1. Docs-only action state storage design
2. Migration for internal review state and action event tables
3. Schema modules and changeset validation for bounded stored fields
4. Runtime internal writer with transaction and idempotency
5. Route/action endpoint design refresh if needed
6. Operator-only action endpoints after storage and authorization are locked
7. Optional UI design after route behavior is locked
```

This PR covers only step 1.

## Stop conditions

Do not merge a future storage implementation if it:

```text
adds action endpoints
adds UI
changes public response shapes
adds public duplicate group action fields
mutates canonical feed data
creates provider canonical feed items
creates news-only events
merges official TDnet events
overrides official facts or citations
stores raw actor identifiers
stores raw request identifiers
stores raw idempotency keys
stores provider credentials
stores provider transport material
stores raw provider payloads
stores full article text
triggers live provider fetch
triggers scheduler/provider work
bypasses Stage 6.0 action contracts
bypasses Stage 6.0 authorization rules
```
