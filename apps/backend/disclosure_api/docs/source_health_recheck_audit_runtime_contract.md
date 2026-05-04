# Source Health Recheck Audit Runtime Contract

## Status

Decision/design contract for future source health recheck audit runtime behavior.

This document is docs-only. It does not change runtime behavior, tests, routes, controllers, database migrations, schemas, providers, schedulers, materializers, canonical data, UI, idempotency runtime behavior, or public API/feed behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: f1620373045c751d2cb216aeb191dfa363a3745e
base source: PR #218 Lock source health recheck audit storage migration
stream: source health recheck audit runtime contract
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
audit storage table -> created and tested
raw/private/canonical response material -> forbidden
```

## Runtime audit goal

Runtime audit should record bounded operator accountability for source health recheck without changing the public/admin response shape.

Audit should answer:

```text
which source_key was targeted
which route operation occurred
which result status occurred
which idempotency status occurred
which bounded actor/request/idempotency hashes were supplied
whether the reason was redacted
when the event occurred
```

Audit must not become a raw request log.

## Decision

Write bounded audit events for every source health recheck attempt that reaches the source health recheck route boundary.

The audit write should be introduced as a best-effort internal record, but tests should verify it is written for the main expected outcomes.

## Audit timing

Audit timing should follow the route decision points:

```text
unknown source -> write not_found audit event
source_health:read denied -> write forbidden audit event
authorized request without idempotency key -> write untracked audit event
authorized request with new idempotency record -> write accepted audit event
authorized request with reused idempotency record -> write reused audit event
```

## Result status mapping

Use these bounded result_status values:

```text
accepted
reused
untracked
forbidden
not_found
```

Meaning:

```text
accepted -> authorized request created new idempotent work
reused -> authorized request reused active idempotency record
untracked -> authorized request did not include idempotency_key_hash and remained temporarily accepted
forbidden -> route denied by source health permission gate
not_found -> source_key did not resolve to a source
```

## Idempotency status mapping

Use these bounded idempotency_status values:

```text
accepted
reused
untracked
none
```

Meaning:

```text
accepted -> new idempotency record
reused -> existing idempotency record reused
untracked -> no idempotency key supplied but request accepted
none -> request did not reach idempotency flow, such as forbidden or not_found
```

## Route operation

The route operation must be derived by runtime code, not request body.

Locked route operation:

```text
source_health:recheck
```

Request body fields must not override it.

Forbidden request body selectors include:

```text
operation
action_operation
route_operation
action
queue
worker
payload
```

## Audit storage fields

Runtime may write only bounded fields already approved by the storage contract:

```text
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
```

## Idempotency linkage

When an idempotency record exists, audit should link to it through:

```text
idempotency_key_id
```

When the request is untracked, forbidden, or not_found, the link may be nil.

## Response shape

Audit runtime writes must not change the default source health recheck response shape.

Do not include audit event id in the response in the first implementation.

A future response contract PR may add a bounded audit reference if needed.

## Audit failure behavior

The first implementation should prefer best-effort audit writes.

If the audit write fails unexpectedly after the main route outcome is already known, the route should avoid exposing audit internals in the response.

Recommended first behavior:

```text
audit failure does not expose SQL details, stack traces, or internal diagnostics
```

Whether audit failure should block the recheck response should be decided in a future reliability PR after operational needs are clearer.

## Required future tests

The next runtime PR should add tests proving:

```text
accepted recheck creates bounded audit event
reused recheck creates bounded audit event
untracked recheck creates bounded audit event
read-only forbidden attempt creates bounded audit event
unknown source attempt creates bounded audit event
request body operation override does not alter route_operation
response shape does not include audit event id
forbidden raw/private/canonical fields are not stored in audit event
```

## Recommended next PR

Recommended next PR:

```text
Add source health recheck audit runtime tests
```

Recommended scope:

```text
test-first or test-mostly
minimal runtime audit write helper
no response shape change
no strict missing-key rejection
no audit query/read API
no poll behavior expansion
no provider/materializer/canonical mutation
```

## Non-goals

This PR does not implement:

```text
audit runtime writes
audit schema module
audit event response references
audit query/read APIs
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
apps/backend/disclosure_api/docs/source_health_recheck_audit_runtime_contract.md
```

No Codex test command is required for this docs-only decision PR.
