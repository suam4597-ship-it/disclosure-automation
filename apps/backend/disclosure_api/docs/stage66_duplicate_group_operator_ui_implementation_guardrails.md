# Stage 6.6 duplicate group operator UI implementation guardrails

This checklist defines guardrails for Stage 6.6 duplicate group operator UI implementation work.

Stage 6.6 PR A is docs-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline guardrails

Future implementation must preserve this baseline:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 686a3d3be22b32c7f0bdd9ebe7b3b2bbdf6ccbd7
base source: PR #160 Lock duplicate group operator runbook
```

Locked internal read routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Locked internal action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

## Scope guardrails

Stage 6.6 implementation PRs must be small and sequential.

Recommended sequence:

```text
PR 162: minimal internal/admin UI shell route implementation
PR 163: operator duplicate group list screen
PR 164: operator duplicate group detail screen
PR 165: operator action controls
PR 166: operator UI integration tests and smoke checks
PR 167: Stage 6.6 operator UI lock close-out
```

Each PR must state whether it changes routes, controllers, templates, frontend assets, tests, or docs.

## Current app structure guardrails

The app currently has a JSON API scope and JSON controller macro. Future UI implementation must not assume that a browser pipeline, HTML controller macro, template stack, LiveView stack, static asset path, or JavaScript bundle already exists.

If a future PR introduces any of these, it must keep the change scoped and explicitly validate the changed files.

## Route guardrails

Allowed future internal/admin UI routes:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

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

UI routes must not replace, alias, or mutate locked JSON API routes.

## Controller and rendering guardrails

A future UI implementation should use a dedicated UI shell controller, separate from `AdminDuplicateGroupController`.

The existing JSON controller must remain the locked JSON API surface.

Allowed shell responsibilities:

```text
serve an internal operator-only page shell
return text/html for UI shell routes
embed static, non-private API route configuration
show a generic redaction/guardrail notice
fail closed for unauthenticated or non-operator users
```

Forbidden shell responsibilities:

```text
query duplicate group tables directly
query review state tables directly
query action event tables directly
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

## API dependency guardrails

The UI must use only locked internal/operator-only JSON APIs.

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

The UI must not create alternate read/action/write APIs.

## List screen guardrails

Allowed list filters:

```text
confidence
source_key
member_kind
redaction_status
limit
```

Allowed list display fields:

```text
group_id
confidence
source_keys
match_reasons
member_count
has_official_tdnet_event
has_provider_overlay
redaction_status
review_state_summary.review_state
review_state_summary.last_action_operation
review_state_summary.reviewed_at
```

Forbidden list display fields:

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

The list screen must not fetch or display action event history.

## Detail screen guardrails

Allowed detail sections:

```text
group summary
member summary table
review_state_summary
latest-five action_event_summary
action controls
redaction/guardrail notice
```

The detail screen may display only bounded `action_event_summary` data returned by the locked show API.

The detail screen must not request unbounded action history.

## Action control guardrails

Future action controls must map exactly to locked action routes:

```text
Confirm duplicate group -> POST /api/admin/duplicate-groups/:group_id/confirm
Reject duplicate group -> POST /api/admin/duplicate-groups/:group_id/reject
Mark needs review -> POST /api/admin/duplicate-groups/:group_id/mark-review
Clear review state -> POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The UI must not submit an `action_operation` field that can override route-derived operation.

Route-derived operation mapping remains:

```text
confirm -> confirm_duplicate_group
reject -> reject_duplicate_group
mark-review -> mark_duplicate_group_needs_review
clear-review-state -> clear_duplicate_group_review_state
```

## Action request guardrails

Allowed action request fields:

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

## Authorization guardrails

Future UI routes must be internal/operator-only.

Minimum requirements:

```text
authenticated actor
operator or admin role for shell access
duplicate_group:read permission for list/detail data
action-specific permissions for enabling action controls
backend authorization remains authoritative
```

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

Client-side button visibility or disabled state must not replace backend authorization.

## Idempotency guardrails

Locked idempotency identity remains:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

The UI may prevent duplicate clicks, but backend idempotency remains authoritative.

Same intended action retries should reuse the same idempotency key hash.

New intended actions should use a new idempotency key hash.

## Refresh guardrails

After a successful action, the UI may refresh by calling:

```text
GET /api/admin/duplicate-groups/:group_id
```

Optional list refresh may call:

```text
GET /api/admin/duplicate-groups
```

Refresh must not trigger provider live fetch, scheduler work, duplicate group materialization, overlay materialization, canonical mutation, or public feed updates.

## Failure rendering guardrails

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

## Redaction guardrails

Future UI implementation, tests, fixtures, docs, review comments, logs, and tickets must not contain:

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

## Public response-shape guardrails

Future UI work must not change:

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

Future UI work must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

Operator review state remains internal advisory metadata.

## Provider, scheduler, and materializer guardrails

Future UI work must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
change materializer behavior
```

## Validation guardrails for PR 162

PR 162 should verify:

```text
changed files are limited to router, dedicated UI shell controller, targeted shell route test, and docs unless explicitly justified
/admin/duplicate-groups is internal/admin-only
/admin/duplicate-groups/:group_id is internal/admin-only
shell responses are text/html
shell embeds no raw/private identifiers
shell does not query duplicate group/action state tables directly
shell does not write action state
shell does not trigger materialization
shell does not trigger provider/scheduler/live-fetch work
shell does not mutate canonical data
existing JSON API routes remain unchanged
```

## Validation guardrails for PR 163 through PR 166

Later UI PRs should verify:

```text
list screen uses only GET /api/admin/duplicate-groups
list screen excludes action_event_summary
detail screen uses only GET /api/admin/duplicate-groups/:group_id
detail screen keeps action_event_summary latest-five and show-only
action controls call locked POST routes only
request body cannot override route-derived operation
read-only users cannot trigger actions
raw/private identifiers are not rendered
public API/feed response shape is unchanged
canonical/provider/scheduler/materializer side effects remain absent
```

## Stop conditions

Do not merge future Stage 6.6 implementation PRs if they:

```text
add public duplicate group fields
change public response shapes
change existing JSON API route behavior
change action endpoint behavior
change action write behavior
bypass Stage 6.1 writer
bypass Stage 6.0 authorization gate
query duplicate group/action state tables directly from UI routes
write action state from UI routes
allow request-body override of route-derived action operation
show raw actor/request/idempotency identifiers
show unredacted operator reasons
show raw provider payloads or full article text
show canonical payloads
return unbounded diagnostics
mutate canonical data
trigger provider/scheduler/live-fetch work
change materializer behavior
```
