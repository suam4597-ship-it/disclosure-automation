# Stage 6.0 duplicate group operator actions audit design

This document defines a docs-only design for future duplicate group operator actions after the Stage 5.9 duplicate group workflow was locked.

This PR is design-only. It does not add runtime action code, runtime authorization integration, audit writes, migrations, schema modules, routes, controllers, UI, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 3cc59f3e091d9eef6da666840ce5e0a8038a89c9
base source: PR #136 Lock Stage 5.9 duplicate group workflow
stage: Stage 6.0 PR A duplicate group operator actions audit design
status: docs-only
locked Stage 5.9 route: GET /api/admin/duplicate-groups and GET /api/admin/duplicate-groups/:group_id
locked Stage 5.9 storage: source_duplicate_groups and source_duplicate_group_members
locked Stage 5.9 read projection: internal read-only duplicate group projection
```

## Goal

Define future operator actions for duplicate group review before implementing any action endpoint or mutation behavior.

The goal is to let an authorized operator record review intent for internal duplicate groups while keeping Stage 5.9 public response, canonical disclosure, and provider integration guardrails intact.

## Non-goals

This design does not authorize or implement:

```text
action endpoints
runtime action code
runtime authorization integration
audit table writes
schema migrations
UI changes
public duplicate group fields
public API response-shape changes
public feed response-shape changes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event merge
official fact override
official citation override
scheduler-triggered grouping
provider live fetch
provider clients
```

## Candidate future actions

Future duplicate group actions should remain explicit, bounded, and operator-only.

Candidate action operations:

```text
confirm_duplicate_group
reject_duplicate_group
mark_duplicate_group_needs_review
clear_duplicate_group_review_state
```

Each operation requires a separate authorization permission and a bounded reason.

## Action semantics

### confirm_duplicate_group

Records that an operator confirms the internal advisory duplicate grouping.

Allowed future effect:

```text
update internal duplicate group review metadata only
write bounded redacted audit event
return bounded internal operator response
```

Forbidden effect:

```text
merge official TDnet events
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
override official facts
override official citations
change public feed/API response shapes
```

### reject_duplicate_group

Records that an operator rejects the internal advisory duplicate grouping.

Allowed future effect:

```text
update internal duplicate group review metadata only
write bounded redacted audit event
return bounded internal operator response
```

Forbidden effect:

```text
delete official events
delete news overlays
mutate canonical data
change public responses
trigger provider fetch
```

### mark_duplicate_group_needs_review

Records that an internal duplicate group needs additional operator review.

Allowed future effect:

```text
set bounded internal review state
write bounded redacted audit event
```

Forbidden effect:

```text
auto-confirm grouping
auto-reject grouping
trigger scheduler/provider work
```

### clear_duplicate_group_review_state

Clears a bounded internal review state when separately authorized.

Allowed future effect:

```text
clear internal review metadata
write bounded redacted audit event
```

Forbidden effect:

```text
delete duplicate group rows
mutate canonical data
change public responses
```

## Permission model

Future action permissions must be separate from read permissions.

Read permission:

```text
duplicate_group:read
```

Action permissions:

```text
duplicate_group:confirm
duplicate_group:reject
duplicate_group:mark_review
duplicate_group:clear_review_state
```

Read-only permission must not authorize action operations.

Action requests must require:

```text
authenticated actor context
operator/admin role
action-specific permission
actor_id_hash
request_id_hash
idempotency_key_hash
bounded redacted operator reason
```

Forbidden actor/request fields:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reason fields
unknown actor context fields
```

## Idempotency policy

Future action endpoints must require a bounded idempotency key or idempotency key hash.

The future action service should be safe to retry without duplicate audit writes or conflicting state transitions.

Recommended idempotency identity:

```text
group_id
action_operation
actor_id_hash
idempotency_key_hash
```

Forbidden idempotency inputs:

```text
raw operator identity
raw request body
raw provider payload
full article text
provider transport metadata
```

## Audit policy

Future action audit events must be bounded and redacted.

Allowed audit fields:

```text
action_operation
group_id
actor_id_hash
request_id_hash
idempotency_key_hash
required_permission
result_status
pre_review_state
post_review_state
redacted_operator_reason
failure_code
redaction_status
created_at
```

Forbidden audit fields:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
raw provider bodies
full article text
provider secret values
provider transport metadata
canonical feed payloads
provider canonical creation payloads
unbounded diagnostics
```

## Storage policy

Future implementation should not reuse public response tables for action state.

If storage is needed, it should be internal-only and designed separately before implementation.

Candidate future internal fields:

```text
review_state
reviewed_by_actor_id_hash
reviewed_at
review_reason_redacted
last_action_request_id_hash
```

A future schema/migration PR must preserve:

```text
bounded field sizes
redaction checks
idempotency uniqueness
no public API/feed exposure
no canonical mutation
```

## Route policy

Future action endpoints, if implemented, should be operator-only and action-only:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

These routes are not implemented by this design PR.

Future action route responses must be bounded internal responses only and must not mutate public response shapes.

## Public response guardrails

Future action work must not change:

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

Public duplicate group fields remain absent unless a separate public response-shape design explicitly changes that policy.

## Canonical no-mutation guardrails

Future duplicate group actions remain non-canonical unless a separate canonical mutation design explicitly changes the policy.

Forbidden by default:

```text
canonical_feed_items mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event merge
official fact override
official citation override
canonical fact override
```

## Provider and scheduler guardrails

Future duplicate group actions must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
materialize provider overlays
materialize duplicate groups
read provider credentials
store provider credentials
store provider transport metadata
```

## Redaction policy

Future action request validation, action results, audit events, logs, docs, tests, review comments, and manual-smoke output must not include non-redacted private provider or operator material.

Forbidden material:

```text
provider secret values
provider transport material
request header values
response header values
cookie values
raw provider response bodies
full article text
canonical feed payloads
provider canonical creation payloads
raw actor identifiers
raw request identifiers
raw idempotency keys
unbounded diagnostics
```

Allowed placeholders:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_OPERATOR_ID
REDACTED_REQUEST_ID
REDACTED_IDEMPOTENCY_KEY
```

## Failure behavior

Future action endpoints should fail closed.

Recommended behavior:

```text
401 or 403 for unauthorized access
404 for missing or unauthorized-not-revealed group
400 for invalid bounded request body
409 for idempotency or state-transition conflicts
422 for invalid action state transition
```

Error responses must remain bounded and must not leak raw request body, provider material, private actor context, SQL errors, or unbounded diagnostics.

## Future implementation sequence

Recommended future sequence:

```text
1. Docs-only duplicate group action/audit design
2. Pure duplicate group action request contract
3. Pure duplicate group action audit contract
4. Internal no-op action preview service
5. Optional internal storage/schema design for review state and audit writes
6. Runtime action service with idempotency and bounded audit behavior
7. Operator-only action routes after authorization behavior is locked
8. UI design only after route/action behavior is locked
```

This PR covers only step 1.

## Stop conditions

Do not merge future action implementation if it:

```text
adds action endpoints before action contract/audit contract are locked
uses read permission as action permission
stores raw actor identifiers
stores raw request identifiers
stores raw idempotency keys
stores provider credentials
stores provider transport metadata
stores raw provider payloads
stores full article text
changes public API/feed response shapes
adds public duplicate group fields
mutates canonical feed items
creates provider canonical feed items
creates news-only events
merges official TDnet events
overrides official facts
overrides official citations
triggers live provider fetch
triggers scheduler/provider work
adds UI in a contract/action service PR
breaks redaction checks
```
