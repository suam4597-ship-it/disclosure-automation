# Stage 6.1 duplicate group action state storage guardrails

This checklist defines guardrails for future internal duplicate group operator action state and event storage.

This PR is docs-only. It does not add migrations, schema modules, runtime DB writes, event writes, routes, controllers, UI, action endpoints, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Storage scope guardrails

Future storage must be internal-only and operator-only.

Candidate future tables:

```text
source_duplicate_group_review_states
source_duplicate_group_action_events
```

These tables must not be public response tables.

## Review state field allowlist

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

Forbidden review state fields:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted review reason
raw provider payloads
full article text
canonical payloads
provider transport material
unbounded diagnostics
```

## Action event field allowlist

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

Forbidden action event fields:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reason
raw provider payloads
full article text
canonical payloads
provider transport material
unbounded diagnostics
```

## Review state allowlist

Allowed review states:

```text
unknown
confirmed_by_operator
rejected_by_operator
needs_review
cleared
```

Unknown review states must be rejected.

## Action operation allowlist

Allowed operations:

```text
confirm_duplicate_group
reject_duplicate_group
mark_duplicate_group_needs_review
clear_duplicate_group_review_state
```

Unknown operations must be rejected.

## Permission guardrails

Future storage writes must only happen after Stage 6.0 authorization has passed.

Required rules:

```text
authenticated actor required
operator/admin role required
action-specific permission required
read-only duplicate_group:read permission cannot authorize action writes
actor_id_hash must match action request actor_id_hash
```

## Idempotency guardrails

Recommended action event uniqueness:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

Recommended review state uniqueness:

```text
group_id
```

Future implementation must not use raw idempotency keys, raw request body, raw actor identity, provider payloads, full article text, or canonical payloads as idempotency inputs.

## Transaction guardrails

If future runtime code writes both action event and review state, it must do so transactionally.

Required behavior:

```text
validate request before DB write
validate authorization before DB write
validate audit event before DB write
insert or reuse idempotent action event
update review state in same transaction
avoid partial event/state writes
return bounded error on conflict or failure
```

## Runtime side-effect guardrails

Future storage implementation must not also add:

```text
action endpoints
UI
scheduler work
provider clients
live provider fetch
public response changes
canonical mutation
materializer behavior changes
```

These require separate design and implementation PRs.

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

Public duplicate group action state fields must remain absent unless a separate public response-shape design explicitly changes that policy.

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

Review state is advisory internal metadata only.

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

## Redaction guardrails

Future storage, changesets, runtime writers, tests, docs, review comments, logs, and manual-smoke output must not include non-redacted private provider or operator material.

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
unredacted operator reasons
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

## Validation guardrails for future implementation

A future implementation PR should verify:

```text
migration creates internal tables only
schemas validate bounded fields
schemas reject forbidden raw/private fields
idempotency uniqueness is enforced
runtime writer validates Stage 6.0 contracts before writes
runtime writer uses transaction for event/state writes
no public response shape changes
no canonical mutation
no provider/scheduler/live-fetch behavior
changed-file strict redaction check passes
```
