# Source Health Internal UI Track Design

## Status

Design gate for the source health internal UI track.

This document is docs-only. It does not add or modify UI routes, templates, frontend code, backend runtime code, tests, controllers, schedulers, provider clients, materializers, canonical data, audit query APIs, or poll behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 15b62cfa46b9b27949a9e7bdf050b966ce6c626d
base source: PR #222 Add source health recheck backend final close-out
stream: source health internal UI track design
status: docs-only design
```

## Backend state entering UI track

The source health recheck backend safety track is closed for the recheck route.

Locked backend behavior includes:

```text
GET /api/admin/source-health -> bounded source health list
GET /api/admin/source-health/:source_key -> bounded source health detail
POST /api/admin/source-health/:source_key/recheck -> bounded recheck route
unknown source key -> bounded 404
source_health:read -> bounded 403 for existing source recheck
source_health:recheck -> bounded 202 for existing source positive path
bounded health_checks enqueue model
runtime idempotency -> accepted / reused / untracked
audit runtime events -> accepted / reused / untracked / forbidden / not_found
forbidden sensitive material is not exposed in responses or audit rows
```

## UI goal

Build an internal operator UI for safe source health review and recheck operation.

The UI should answer:

```text
Which sources exist?
Which sources need attention?
Can this operator trigger recheck?
What happened after recheck was requested?
```

The UI must not become a raw provider or debug console.

## Proposed UI pages

### 1. Source health list

Proposed route:

```text
/admin/source-health
```

Purpose:

```text
show source list
show health status summary
show active or paused state
provide link to detail page
support bounded backend filters if already available
```

Allowed display fields:

```text
source_key
display_name
source_type
region_code
health_status
last_seen_published_at
last_success_at
last_failure_at
active
```

Forbidden display material:

```text
raw provider data
private configuration
credentials or request internals
full raw document text
stack traces or SQL internals
canonical payloads
unbounded diagnostics
```

### 2. Source health detail

Proposed route:

```text
/admin/source-health/:source_key
```

Purpose:

```text
show one bounded source health record
show safe cursor/config summary when present
show recheck action area
show safe 404 state
```

The detail page must use only the bounded backend response fields.

### 3. Recheck action area

Behavior:

```text
source_health:recheck -> enabled recheck action
source_health:read -> disabled recheck action or read-only explanation
unknown source -> bounded not-found state
```

The UI must not offer controls for operation, queue, worker, provider fetch, materializer, canonical mutation, or poll.

The UI may send bounded operator context fields:

```text
actor_id_hash
actor_permissions
request_id_hash
idempotency_key_hash
reason_redacted
redaction_status
created_at
```

## Response handling

### 202 Accepted

Show a bounded success message.

If `idempotency_status` is present:

```text
accepted -> New recheck request accepted.
reused -> A similar recent request was reused.
untracked -> Recheck accepted without idempotency tracking.
```

Do not show raw job internals.

### 403 Forbidden

Show:

```text
You do not have permission to recheck this source.
```

The recheck action should be disabled for read-only users whenever possible.

### 404 Not Found

Show:

```text
Source not found.
```

Provide a safe link back to the source list.

### Other errors

Show bounded generic error text only.

## Idempotency requirement

Each recheck click should use a bounded idempotency key hash when possible.

If an idempotency key cannot be generated, backend currently supports untracked 202 behavior, but UI should prefer tracked requests.

## Audit requirement

The first UI implementation does not need to show audit history.

Audit read/query UI is a separate future track.

Do not show audit event IDs in the recheck result unless a future response contract approves it.

## Permission model

The UI should distinguish:

```text
source_health:read -> list and detail only
source_health:recheck -> can trigger recheck
source_health:poll -> out of scope and gated
```

## Poll route remains out of scope

The UI track must not add or expose poll actions by default.

Still gated:

```text
POST /api/admin/sources/:source_key/poll
```

## Recommended implementation sequence

### PR 1: UI route design lock

```text
lock intended internal UI routes
confirm no public source health UI route
keep poll hidden
```

### PR 2: Source health list UI shell

```text
bounded list fields only
no recheck action yet
read-only safe
```

### PR 3: Source health detail UI shell

```text
bounded detail fields only
safe loading and not-found states
no recheck action yet or disabled placeholder only
```

### PR 4: Recheck action UI

```text
permission-aware action
202 / 403 / 404 display states
idempotency hash support
no operation override controls
```

### PR 5: UI smoke and runbook close-out

```text
operator list flow
detail flow
permissioned recheck flow
read-only denial flow
safe error-state display
```

## Required tests before UI track close-out

Future UI work should prove:

```text
source health UI routes are internal only
list page displays only bounded fields
detail page displays only bounded fields
read-only user cannot trigger recheck from UI
recheck user sees bounded 202 success state
403 and 404 are displayed safely
poll action is not exposed
```

## Non-goals

This design does not implement:

```text
UI routes
UI controllers
HTML templates
React components
API response changes
audit read UI
poll UI
provider fetch controls
materializer controls
canonical mutation controls
monitoring dashboards
```

## Stop conditions

Stop and re-scope if future UI work:

```text
adds public source health UI routes
adds duplicate controller modules
displays forbidden sensitive material
lets source_health:read trigger recheck
offers operation, queue, worker, provider, materializer, canonical, or poll controls
changes backend response shapes without a contract PR
```

## Validation

This PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_internal_ui_track_design.md
```

No Codex test command is required for this docs-only UI track design PR.
