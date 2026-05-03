# Stage 6.7 duplicate group operator UI polish guardrails

This checklist defines guardrails for Phase 2 duplicate group operator UI polish work.

Stage 6.7 PR A is docs-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline guardrails

Future implementation must preserve this baseline:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: a0d5c006a70cf06449b86024a6f40df62060e505
base source: PR #167 Lock Stage 6.6 duplicate group operator UI
```

Locked UI routes:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

Locked JSON APIs:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

## Scope guardrails

Stage 6.7 polish work may improve UI states and usability only.

Allowed polish categories:

```text
loading states
empty states
bounded error states
action confirmation step
duplicate-click prevention
permission-aware button disabled states
bounded success feedback
filter persistence
basic accessibility and usability
```

Forbidden scope:

```text
new UI routes
new JSON API routes
new action operations
new public fields
new canonical behavior
new provider/scheduler/materializer behavior
new storage
new migrations
new schemas
```

## Loading state guardrails

Allowed loading states:

```text
loading duplicate groups
loaded duplicate groups
unable to load duplicate groups
loading duplicate group detail
loaded duplicate group detail
unable to load duplicate group detail
submitting action
action submitted and detail refreshed
unable to submit action
```

Loading states must not reveal raw request bodies, SQL details, provider payloads, canonical payloads, stack traces, or unbounded diagnostics.

## Empty state guardrails

Allowed empty states:

```text
No duplicate groups found.
No members found.
No latest actions found.
No review state recorded yet.
```

Empty states must not instruct operators to perform manual DB writes, manual backfills, provider fetches, scheduler work, materializer work, or canonical changes.

## Error state guardrails

Allowed bounded error categories:

```text
authentication required
action permission missing
duplicate group not found
invalid request
idempotency conflict
state transition rejected
temporary unavailable
unable to load duplicate groups
unable to load duplicate group detail
unable to submit action
```

Forbidden error rendering:

```text
SQL details
raw request bodies
private actor context
provider payloads
full text
canonical payloads
headers
cookies
secrets
unbounded diagnostics
stack traces
```

## Action confirmation guardrails

Future confirmation UI may show:

```text
group_id
action label
locked route path
post_review_state
bounded redaction warning
operator_reason_redacted field
idempotency_key_hash field
```

Future confirmation UI must not show or submit:

```text
action_operation request-body override
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reasons
provider payloads
canonical payloads
full article text
unbounded diagnostics
```

## Duplicate-click guardrails

The UI may disable action buttons while a request is pending.

Backend idempotency remains authoritative:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

The UI must not introduce new idempotency identities.

## Permission state guardrails

Client-side permission state is advisory only.

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

Backend authorization remains authoritative.

## Action request guardrails

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
```

Forbidden action request material remains:

```text
action_operation override
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

## Success feedback guardrails

Allowed success feedback fields:

```text
action_operation
required_permission
actor_id_hash
request_id_hash
idempotency_key_hash
result_status
redaction_status
pre_review_state
post_review_state
review_state
action_event_inserted
```

Forbidden success feedback material:

```text
unredacted operator reason
raw actor identifiers
raw request identifiers
raw idempotency keys
provider payloads
full article text
canonical payloads
unbounded diagnostics
```

## List screen guardrails

List screen must still use only:

```text
GET /api/admin/duplicate-groups
```

Allowed filters remain:

```text
confidence
source_key
member_kind
redaction_status
limit
```

List screen must not render:

```text
action_event_summary
operator_reason_redacted action history
raw actor identifiers
raw request identifiers
raw idempotency keys
provider payloads
canonical payloads
full article text
unbounded diagnostics
```

List screen must not call action routes.

## Detail screen guardrails

Detail screen must still use only:

```text
GET /api/admin/duplicate-groups/:group_id
```

Action event summary must remain:

```text
show-response-only
latest-five-from-show-response
```

Detail screen must not request unbounded action history.

## Action control guardrails

Action buttons must map exactly to locked routes:

```text
Confirm duplicate group -> POST /api/admin/duplicate-groups/:group_id/confirm
Reject duplicate group -> POST /api/admin/duplicate-groups/:group_id/reject
Mark needs review -> POST /api/admin/duplicate-groups/:group_id/mark-review
Clear review state -> POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The route chooses the operation.

The UI must not submit an `action_operation` request body field.

## Public response-shape guardrails

Stage 6.7 UI polish must not change:

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

Stage 6.7 UI polish must not:

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

Stage 6.7 UI polish must not:

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

Future UI polish, tests, fixtures, docs, review comments, logs, and tickets must not contain:

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

Future implementation PRs should verify:

```text
changed files remain scoped to UI controller/tests/docs unless explicitly justified
existing JSON API behavior remains unchanged
list still excludes action_event_summary
show still keeps action_event_summary bounded and show-only
action controls still use locked routes only
action request body still excludes action_operation
read-only permission does not authorize actions
public response shapes are unchanged
canonical/provider/scheduler/materializer side effects remain absent
```

## Stop conditions

Do not merge Stage 6.7 implementation PRs if they:

```text
add public duplicate group fields
change public response shapes
change existing JSON API route behavior
change action endpoint behavior
change action writer behavior
add new action operations
submit action_operation in request bodies
request unbounded action history
query duplicate group/action state tables from the UI controller
write action state from UI routes directly
show raw actor/request/idempotency identifiers
show unredacted operator reasons
show raw provider payloads or full article text
show canonical payloads
return unbounded diagnostics
mutate canonical data
trigger provider/scheduler/live-fetch work
change materializer behavior
```
