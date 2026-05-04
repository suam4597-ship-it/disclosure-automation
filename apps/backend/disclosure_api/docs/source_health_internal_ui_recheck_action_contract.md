# Source Health Internal UI Recheck Action Contract

## Status

Design contract for the source health internal UI recheck action.

This document is docs-only. It does not add UI controls, frontend code, backend runtime behavior, tests, routes, controllers, templates, provider behavior, materializer behavior, canonical behavior, poll behavior, audit read UI, or public API/feed behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 3b80c6175fb6c8e5cb0cb974c92616acbc8ff96f
base source: PR #230 Lock source health internal UI detail shell
stream: source health internal UI recheck action contract
status: docs-only design
```

## Prior UI locks

The internal source health UI track has already locked:

```text
GET /admin/source-health -> bounded list shell
GET /admin/source-health/:source_key -> bounded detail shell
unknown detail source -> bounded 404 state
recheck action controls -> not rendered yet
poll action controls -> not rendered
audit UI -> not rendered
forbidden sensitive material -> not rendered
```

## Backend contract available to the UI

The UI may call the existing bounded backend route:

```text
POST /api/admin/source-health/:source_key/recheck
```

Locked backend outcomes:

```text
source_health:recheck -> 202 Accepted
source_health:read -> 403 Forbidden
unknown source -> 404 Not Found
idempotency_status -> accepted / reused / untracked when present
audit events -> written internally without response shape change
```

## Goal

Add a permission-aware recheck action on the source health detail page without exposing unsafe controls or changing backend response contracts.

The action should help an operator safely request a recheck and understand the bounded result.

## UI action states

### Read-only state

When the operator has only:

```text
source_health:read
```

The UI should display:

```text
recheck_action=disabled
recheck_reason=read_only
```

The UI must not submit the recheck request for read-only users.

### Recheck-allowed state

When the operator has:

```text
source_health:recheck
```

The UI may display:

```text
recheck_action=enabled
```

The action must submit only to:

```text
POST /api/admin/source-health/:source_key/recheck
```

### Unknown source state

When the detail page is in the bounded not-found state, the UI must not display an enabled recheck action.

Display:

```text
recheck_action=not_available
```

## Request payload contract

The UI may send bounded operator context:

```text
actor_id_hash
actor_permissions
request_id_hash
idempotency_key_hash
reason_redacted
redaction_status
created_at
```

The UI must not send request-body controls for:

```text
operation
action_operation
route_operation
action
queue
worker
payload
provider fetch
materializer
canonical mutation
poll
```

## Idempotency requirement

The UI should generate or receive a bounded idempotency key hash per recheck click.

Preferred behavior:

```text
one recheck click -> one idempotency_key_hash
retry of same UI submission -> same idempotency_key_hash
new deliberate click -> new idempotency_key_hash
```

If idempotency key generation fails, backend currently supports untracked 202, but the UI should prefer tracked requests.

## Response display contract

### 202 Accepted

Show a bounded success message.

If idempotency status is present:

```text
accepted -> Recheck request accepted.
reused -> A similar recent recheck request was reused.
untracked -> Recheck request accepted without tracking.
```

Do not display raw job internals.

### 403 Forbidden

Show:

```text
You do not have permission to recheck this source.
```

If a 403 occurs despite the UI showing an enabled action, the UI should refresh or mark permission state stale.

### 404 Not Found

Show:

```text
Source not found.
```

Provide a safe link back to:

```text
/admin/source-health
```

### Other errors

Show bounded generic error text only.

Do not show stack traces, SQL details, raw response payloads, or unbounded diagnostics.

## Audit display contract

The recheck action UI must not show audit event identifiers in the first implementation.

Do not display:

```text
audit_event
audit_event_id
```

Audit read UI is a separate future track.

## Poll remains out of scope

The UI must not add poll controls as part of this recheck action work.

Still gated:

```text
POST /api/admin/sources/:source_key/poll
```

## Required future tests

The next implementation PR should prove:

```text
read-only detail state renders disabled recheck action
recheck permission detail state renders enabled recheck action
not-found detail state does not render enabled action
enabled action targets only the locked backend recheck route
request payload includes bounded idempotency context
request payload does not include operation/queue/worker/poll controls
202 accepted/reused/untracked messages are bounded
403 and 404 messages are bounded
audit event ids are not displayed
forbidden sensitive material is not displayed
```

## Recommended next PR

Recommended next PR:

```text
Add source health internal UI recheck action tests
```

Recommended scope:

```text
test-first or test-mostly
permission-state rendering only at first
no full JS behavior if not needed
no poll UI
no audit UI
no backend response changes
```

## Non-goals

This PR does not implement:

```text
recheck button
form submission
JavaScript behavior
backend response changes
audit read UI
poll UI
operator runbook
end-to-end UI smoke test
```

## Stop conditions

Stop and re-scope if future UI work:

```text
lets source_health:read trigger recheck
adds operation/queue/worker/poll controls
shows audit event identifiers
shows forbidden sensitive material
changes backend response shapes without contract approval
adds poll UI without a dedicated poll gate
```

## Validation

This PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_internal_ui_recheck_action_contract.md
```

No Codex test command is required for this docs-only recheck action contract PR.
