# Stage 6.4 duplicate group operator UI shell route design

This document defines a docs-only design for future internal duplicate group operator UI shell routes after the Stage 6.4 operator UI/experience design was merged.

This PR is design-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: fedfde71e92b61e423020486f7c406bde8295a66
base source: PR #155 Design Stage 6.4 duplicate group operator UI experience
stage: Stage 6.4 PR B duplicate group operator UI shell route design
status: docs-only
locked Stage 5.9 read routes: GET /api/admin/duplicate-groups and GET /api/admin/duplicate-groups/:group_id
locked Stage 6.2 action routes: POST /api/admin/duplicate-groups/:group_id/confirm, reject, mark-review, clear-review-state
locked Stage 6.3 read metadata: review_state_summary and show-only action_event_summary
locked Stage 6.4 PR A: operator UI/experience design only, no UI implementation
```

## Purpose

Stage 6.4 PR B defines where a future internal operator UI shell could be mounted and how it should depend on locked duplicate group read/action APIs without implementing the shell.

The future shell should be a thin internal/admin-only page container. It should not introduce new public APIs, new action semantics, new storage, provider work, scheduler work, materializer behavior, or canonical mutations.

## Non-goals

This design does not authorize or implement:

```text
frontend components
HTML templates
LiveView modules
JavaScript bundles
CSS assets
UI routes
router changes
controllers
server-side UI rendering
backend runtime code
action endpoint changes
write behavior changes
new action operations
new authorization rules
new migrations
new schema modules
public duplicate group fields
public API response-shape changes
public feed response-shape changes
scheduler work
provider clients
live provider fetch
materializer behavior changes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event merge
official fact override
official citation override
```

## Candidate shell routes

Future implementation may consider these internal/admin-only HTML shell routes:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

These routes are intentionally not under `/api` and must not change the locked JSON API routes.

Existing JSON API routes remain the data source:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Future shell routes must not replace, alias, or mutate the API routes.

## Shell responsibility

A future shell route should only provide a bounded internal UI container.

Allowed shell responsibilities:

```text
serve an internal operator-only page shell
load initial static configuration that contains no private identifiers
identify the existing API routes the UI may call
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

## Data dependency model

A future shell should obtain duplicate group data by calling only the locked admin JSON APIs.

List data source:

```text
GET /api/admin/duplicate-groups
```

Detail data source:

```text
GET /api/admin/duplicate-groups/:group_id
```

Action data source:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

A future shell route must not add a second server-side read projection path unless separately designed and tested.

## Candidate list shell behavior

The future list shell route:

```text
GET /admin/duplicate-groups
```

should render a page that fetches list data from:

```text
GET /api/admin/duplicate-groups
```

The shell may support only the locked bounded list filters:

```text
confidence
source_key
member_kind
redaction_status
limit
```

The list shell should not fetch or display action event history.

## Candidate detail shell behavior

The future detail shell route:

```text
GET /admin/duplicate-groups/:group_id
```

should render a page that fetches detail data from:

```text
GET /api/admin/duplicate-groups/:group_id
```

The detail shell may display:

```text
group summary
member summary table
review_state_summary
action_event_summary
action controls
redaction/guardrail notice
```

The detail shell must keep `action_event_summary` bounded and show-only, preserving the Stage 6.3 latest-five summary limit.

## Routing namespace design

Future UI shell routes should use an internal admin HTML namespace distinct from JSON APIs.

Recommended route namespace:

```text
/admin/duplicate-groups
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

A future implementation PR must document route placement and authorization behavior before adding router changes.

## Authorization design

Future shell routes must be internal/operator-only.

Minimum requirements:

```text
authenticated actor
operator or admin role for shell access
read permission for viewing list/detail data
action-specific permissions for enabling action controls
backend authorization remains authoritative
```

Read-only permission may allow viewing the shell but must not enable action controls:

```text
duplicate_group:read
```

Action controls require the existing action-specific permissions:

```text
duplicate_group:confirm
duplicate_group:reject
duplicate_group:mark_review
duplicate_group:clear_review_state
```

## Shell action control mapping

Future shell action controls must map exactly to locked action routes:

```text
Confirm duplicate group -> POST /api/admin/duplicate-groups/:group_id/confirm
Reject duplicate group -> POST /api/admin/duplicate-groups/:group_id/reject
Mark needs review -> POST /api/admin/duplicate-groups/:group_id/mark-review
Clear review state -> POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The shell must not generate or send an action operation field that can override the route-derived operation.

## Shell action request allowlist

Future shell action requests may include only bounded, already-redacted metadata accepted by locked action routes.

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

The shell must not submit raw actor identifiers, raw request identifiers, raw idempotency keys, unredacted operator reasons, provider payloads, full article text, canonical payloads, private transport material, or unbounded diagnostics.

## Idempotency and retry design

A future shell should generate or receive a stable idempotency key hash for each action attempt.

Locked idempotency identity remains:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

The shell may disable action buttons while a request is pending, but backend idempotency remains authoritative.

Retrying the same intended action after a transient failure should reuse the same idempotency key hash.

## Refresh design

After successful action submission, the future shell should refresh the detail view by calling:

```text
GET /api/admin/duplicate-groups/:group_id
```

Optional list refresh may call:

```text
GET /api/admin/duplicate-groups
```

Refresh must not trigger provider live fetch, scheduler work, duplicate group materialization, overlay materialization, canonical mutation, or public feed updates.

## Failure rendering design

Future shell routes and UI surfaces must render bounded failure states only.

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

Failure rendering must not include SQL details, raw request bodies, private actor context, provider payloads, full text, canonical payloads, headers, cookies, secrets, or unbounded diagnostics.

## Public response guardrails

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

Operator review state remains internal advisory metadata.

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

## Implementation sequence

Recommended next steps after this docs-only design is verified:

```text
1. Stage 6.4 PR B: docs-only UI shell route design
2. Stage 6.4 PR C: minimal UI shell route implementation, if a UI surface is still desired and scoped
3. Stage 6.4 PR D: operator UI frontend behavior, if a frontend target exists and is scoped
4. Stage 6.4 lock close-out after implementation and tests are verified, or close out design-only if UI implementation is deferred
```

This PR covers only step 1.

## Stop conditions

Do not merge a future shell route implementation if it:

```text
adds public duplicate group fields
changes public response shapes
changes existing API route behavior
changes action endpoint behavior
changes action write behavior
bypasses Stage 6.1 writer
bypasses Stage 6.0 authorization gate
queries action state tables directly from shell routes
writes action state from shell routes
allows request-body override of route-derived action operation
shows raw actor/request/idempotency identifiers
shows unredacted operator reasons
shows raw provider payloads or full article text
shows canonical payloads
returns unbounded diagnostics
mutates canonical data
triggers provider/scheduler/live-fetch work
changes materializer behavior
```
