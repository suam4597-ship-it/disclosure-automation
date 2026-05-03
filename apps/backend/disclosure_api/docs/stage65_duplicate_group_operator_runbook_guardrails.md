# Stage 6.5 duplicate group operator runbook guardrails

This checklist defines guardrails for the duplicate group operator runbook.

This PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline guardrails

Future work must preserve this baseline:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: d7b5c7b4b5c2b2cdd3effa6fc23a40a10e19af9f
base source: PR #158 Close out duplicate group operator workflow
```

## Scope guardrails

This runbook is operator documentation only.

It must not change:

```text
runtime behavior
authorization behavior
storage behavior
route behavior
UI behavior
public response behavior
canonical behavior
provider behavior
scheduler behavior
materializer behavior
```

## Route usage guardrails

The runbook may reference only locked internal/operator-only routes.

Read routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The runbook must not instruct operators to use public APIs for duplicate group action state.

## Action mapping guardrails

The runbook must preserve route-derived action operation mapping:

```text
confirm -> confirm_duplicate_group
reject -> reject_duplicate_group
mark-review -> mark_duplicate_group_needs_review
clear-review-state -> clear_duplicate_group_review_state
```

The runbook must not instruct operators to override action operation through request body fields.

## Request metadata guardrails

Allowed request fields:

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

Forbidden request material:

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

## Idempotency guardrails

The runbook must preserve locked idempotency identity:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

Same intended action retry should reuse the same idempotency key hash.

New intended action should use a new idempotency key hash.

## Authorization guardrails

The runbook must preserve backend authorization as authoritative.

Read-only permission must not authorize actions:

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

## Review state guardrails

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

## Action event summary guardrails

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

The runbook must preserve show-only and latest-five summary behavior.

The runbook must not ask operators to request unbounded action event history from read routes.

## Escalation guardrails

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

Escalations must not include raw/private/canonical/provider materials.

## Forbidden operator instructions

The runbook must not instruct operators to:

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
```

## Public response-shape guardrails

The runbook must preserve that duplicate group operator actions do not change:

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

Public duplicate group review/action state fields must remain absent.

## Canonical no-mutation guardrails

The runbook must preserve that duplicate group operator actions do not:

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

The runbook must preserve that duplicate group read/action/UI workflows do not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups from read/action/UI routes
materialize overlays
change materializer behavior
```

## Redaction guardrails

The runbook, review comments, logs, tickets, and manual-smoke output must not contain:

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

## Validation guardrails

Reviewers should verify:

```text
changed files are limited to runbook docs
runbook references only locked routes
runbook preserves route-derived operation mapping
runbook preserves idempotency identity
runbook preserves backend authorization authority
runbook does not instruct manual DB writes
runbook preserves public response-shape guardrails
runbook preserves canonical no-mutation guardrails
runbook preserves provider/scheduler/live-fetch/materializer guardrails
changed-file strict redaction check passes
```
