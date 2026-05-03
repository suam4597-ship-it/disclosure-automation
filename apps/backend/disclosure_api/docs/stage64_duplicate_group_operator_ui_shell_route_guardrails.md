# Stage 6.4 duplicate group operator UI shell route guardrails

This checklist defines guardrails for future internal duplicate group operator UI shell routes.

This PR is docs-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline guardrails

Future work must preserve this baseline:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: fedfde71e92b61e423020486f7c406bde8295a66
base source: PR #155 Design Stage 6.4 duplicate group operator UI experience
```

## Scope guardrails

Stage 6.4 PR B design covers only future internal/admin HTML shell route placement and dependencies.

This design does not implement UI shell routes.

Future implementation must not change locked JSON API behavior unless separately scoped and tested.

## Candidate route guardrails

Future shell route candidates:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

These candidate routes must remain internal/admin-only.

Future shell routes must not be added under public namespaces.

Forbidden route namespaces:

```text
/public/duplicate-groups
/api/public/duplicate-groups
/api/events duplicate group fields
/api/feed duplicate group fields
provider callback routes
scheduler routes
materializer routes
canonical mutation routes
```

## Existing API dependency guardrails

Future shell routes may depend only on existing internal/operator-only JSON APIs.

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

Future shell routes must not create alternate read/action/write APIs.

## Shell responsibility guardrails

Allowed shell responsibilities:

```text
serve an internal operator-only page shell
load initial static configuration that contains no private identifiers
identify existing API routes the UI may call
show a generic redaction/guardrail notice
fail closed for unauthenticated or non-operator users
```

Forbidden shell responsibilities:

```text
query duplicate group tables directly
query action state tables directly
write action events
write review states
materialize duplicate groups
trigger provider live fetch
call provider clients
enqueue scheduler work
mutate canonical data
change public API/feed responses
embed raw actor identifiers
embed raw request identifiers
embed raw idempotency keys
embed provider payloads
embed canonical payloads
embed unbounded diagnostics
```

## Data loading guardrails

A future shell must load list/detail/action data through locked JSON APIs.

List data source:

```text
GET /api/admin/duplicate-groups
```

Detail data source:

```text
GET /api/admin/duplicate-groups/:group_id
```

Action submission routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

A future shell route must not add a second server-side read projection path unless separately designed and tested.

## List shell guardrails

Future list shell behavior must remain bounded.

Allowed filters:

```text
confidence
source_key
member_kind
redaction_status
limit
```

The list shell must not fetch or display action event history.

## Detail shell guardrails

Future detail shell behavior may display bounded detail data from the locked show API.

Allowed sections:

```text
group summary
member summary table
review_state_summary
action_event_summary
action controls
redaction/guardrail notice
```

The detail shell must keep `action_event_summary` bounded and show-only.

## Authorization guardrails

Future shell routes must be internal/operator-only.

Minimum requirements:

```text
authenticated actor
operator or admin role for shell access
read permission for viewing list/detail data
action-specific permissions for enabling action controls
backend authorization remains authoritative
```

Client-side authorization must never replace backend authorization.

## Action control guardrails

Future shell action controls must map exactly to locked action routes.

```text
Confirm duplicate group -> POST /api/admin/duplicate-groups/:group_id/confirm
Reject duplicate group -> POST /api/admin/duplicate-groups/:group_id/reject
Mark needs review -> POST /api/admin/duplicate-groups/:group_id/mark-review
Clear review state -> POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The shell must not allow request-body override of route-derived action operation.

## Action request guardrails

Allowed future shell action request fields:

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

Locked idempotency identity remains:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

A future shell may disable duplicate clicks, but backend idempotency remains authoritative.

## Failure rendering guardrails

Future shell failure rendering must remain bounded.

Allowed failure categories:

```text
authentication required
action permission missing
duplicate group not found
invalid request
idempotency conflict
state transition rejected
temporary unavailable
```

Forbidden failure rendering material:

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
```

## Public response-shape guardrails

Future shell route work must not change:

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

Public duplicate group review/action state fields must remain absent unless a separate public response-shape design explicitly changes that policy.

## Canonical no-mutation guardrails

Future shell route work must not:

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

Future shell route work must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
change materializer behavior
```

## Validation guardrails for future implementation

Future implementation PRs should verify:

```text
changed files are limited to shell route/controller/template/static assets and targeted tests unless justified
candidate shell routes are internal/admin-only
existing JSON APIs remain unchanged
shell does not query duplicate group/action state tables directly
shell does not write action state
shell does not trigger materialization
shell does not trigger provider/scheduler/live-fetch work
shell does not mutate canonical data
read-only users cannot trigger actions
action controls map to locked routes only
request body cannot override route-derived operation
public response shapes are unchanged
changed-file strict redaction check passes
```
