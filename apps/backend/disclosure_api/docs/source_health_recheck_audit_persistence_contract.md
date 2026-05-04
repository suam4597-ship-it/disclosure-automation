# Source Health Recheck Audit Persistence Contract

## Status

Decision/design contract for future source health recheck audit persistence.

This document is docs-only. It does not change runtime behavior, tests, routes, controllers, database migrations, schemas, providers, schedulers, materializers, canonical data, UI, idempotency runtime behavior, or public API/feed behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 7aabf2fe9272822d53b4b53b5e7eff4820e10dd6
base source: PR #215 Lock source health recheck idempotency runtime
stream: source health recheck audit persistence contract
status: docs-only decision/design
```

## Prior locks

The source health recheck backend track has already locked:

```text
source_health:read -> bounded 403 for existing source recheck
source_health:recheck -> bounded 202 for existing source positive path
unknown source key -> bounded 404
bounded health_checks enqueue model -> approved at HTTP contract layer
idempotency storage table -> created and tested
runtime idempotency -> accepted / reused / untracked behavior implemented and validated
raw actor/request/idempotency/reason/private/canonical response material -> forbidden
```

## Goal

Audit persistence should answer:

```text
who triggered source health recheck, using bounded hash identity
which source was targeted
which route operation was executed
which idempotency behavior occurred
when the request was accepted, reused, denied, or rejected
why the operator triggered it, using redacted reason only
```

Audit persistence must not become a raw request log or diagnostic dump.

## Decision

Use a dedicated bounded audit event table for source health recheck.

Preferred future table name:

```text
source_health_recheck_audit_events
```

A dedicated audit table is preferred because audit history has a different lifecycle from idempotency storage.

Idempotency storage supports retry safety.

Audit storage supports operator accountability and incident review.

## Relationship to idempotency storage

Audit events may reference the idempotency record when safe.

Recommended relationship:

```text
source_health_recheck_audit_events.idempotency_key_id -> source_health_recheck_idempotency_keys.id
```

The reference should be optional because missing idempotency hashes remain temporarily accepted as untracked requests.

## Required audit fields

Future audit records should contain bounded fields only:

```text
id
source_key
route_operation
result_status
idempotency_status
actor_id_hash
request_id_hash
idempotency_key_hash
idempotency_key_id
reason_redacted
redaction_status
occurred_at
metadata
inserted_at
updated_at
```

## Route operation source

`route_operation` must be derived from the route/controller path, not from request body.

Allowed value for this track:

```text
source_health:recheck
```

Request body fields such as `operation`, `action_operation`, `route_operation`, `action`, `queue`, `worker`, or `payload` must not control the audit route operation.

## Result status values

Recommended bounded `result_status` values:

```text
accepted
reused
untracked
forbidden
not_found
failed
```

Initial implementation may start with:

```text
accepted
reused
untracked
forbidden
not_found
```

`failed` can be added when error handling/audit tests are explicitly designed.

## Idempotency status values

Recommended bounded `idempotency_status` values:

```text
accepted
reused
untracked
none
```

Use:

```text
accepted -> new idempotency record and accepted work
reused -> existing active idempotency record reused
untracked -> request accepted without idempotency_key_hash
none -> request did not reach idempotency flow, such as forbidden or not_found
```

## Allowed audit inputs

Runtime may use these request inputs for audit only if already bounded/redacted:

```text
source_key
actor_id_hash
request_id_hash
idempotency_key_hash
reason_redacted
redaction_status
actor_permissions
created_at
```

`actor_permissions` may be stored only if bounded and useful for audit review. If stored, it must not include raw identity material.

## Forbidden audit inputs

Future audit storage must not store:

```text
raw_actor_id
raw_request_id
raw_idempotency_key
unredacted_reason
headers
cookies
tokens
provider credentials
raw provider payload
full article text
SQL details
stack traces
canonical payload
private actor context
unbounded diagnostics
```

## Response behavior

Audit persistence should not change the default recheck HTTP response shape.

Do not include an audit event id in the response unless a separate response contract PR approves it.

The first implementation should keep audit persistence write-only from the response perspective.

## Audit timing

Recommended timing:

```text
write audit event after route authorization decision and source lookup result are known
```

The audit should record all relevant bounded outcomes:

```text
forbidden read-only attempt
unknown source attempt
authorized untracked accepted request
authorized accepted idempotent request
authorized reused idempotent request
```

## Required future tests

Before runtime audit persistence is merged, add tests that prove:

```text
accepted recheck creates bounded audit event
reused recheck creates bounded audit event
untracked recheck creates bounded audit event
read-only forbidden attempt creates bounded audit event
unknown source attempt creates bounded audit event
request body operation override does not alter route_operation
forbidden raw/private fields are not stored
audit event does not change HTTP response shape
```

## Recommended next PR

Recommended next PR:

```text
Add source health recheck audit storage migration tests
```

Recommended scope:

```text
migration + DB structure tests first
dedicated audit table
bounded required columns
forbidden raw/private/canonical columns absent
optional link to idempotency record
no runtime audit writing yet
```

## Non-goals

This PR does not implement:

```text
audit migration
audit schema
audit runtime writes
audit response references
strict missing-key rejection
idempotency cleanup
job result lookup
poll behavior
provider fetch behavior
materializer behavior
canonical mutation
source health internal UI
```

## Stop conditions

Stop and re-scope if future work:

```text
adds duplicate controller modules
lets source_health:read trigger recheck for existing source records
allows request-body operation override to select audit route operation
allows request-body operation override to select poll/materialize/canonicalize/provider fetch behavior
allows request body to select queue, worker, or job payload shape
stores or returns raw actor/request/idempotency identifiers
stores or returns unredacted reason
persists or returns secrets, headers, cookies, tokens, raw payloads, full article text, SQL details, stack traces, or unbounded diagnostics
changes public response shapes without a contract PR
calls provider clients inline
triggers materializers inline
mutates canonical data
```

## Validation

This PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_recheck_audit_persistence_contract.md
```

No Codex test command is required for this docs-only decision PR.
