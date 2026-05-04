# Source Health Recheck Idempotency Runtime Contract

## Status

Decision/design contract for future source health recheck runtime idempotency behavior.

This document is docs-only. It does not change runtime behavior, tests, routes, controllers, database migrations, schemas, providers, schedulers, materializers, canonical data, UI, audit persistence, or public API/feed behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: c3d50b387cba7a35e53e73d5bdc66c4206abf930
base source: PR #212 Lock source health recheck idempotency storage migration
stream: source health recheck idempotency runtime contract
status: docs-only decision/design
```

## Prior locks

The source health recheck track has already locked:

```text
source_health:read -> bounded 403 for existing source recheck
source_health:recheck -> bounded 202 for existing source positive path
unknown source key -> bounded 404
bounded health_checks enqueue model -> approved at HTTP contract layer
source_health_recheck_idempotency_keys table -> created and tested
source_key + idempotency_key_hash -> unique storage key
a raw/private/canonical storage denylist -> table columns absent
```

## Runtime goal

Future runtime should implement best-effort dedupe using:

```text
source_key + idempotency_key_hash
```

The goal is retry safety, not strict global exactly-once execution.

## Decision

Use a bounded lookup/create/reuse flow.

### Step 1: Validate route boundaries first

Runtime must preserve the existing order of safety checks:

```text
unknown source -> 404
source_health:read -> 403
source_health:recheck with existing source -> proceed to idempotency flow
```

### Step 2: Missing idempotency hash remains temporarily accepted

If `idempotency_key_hash` is missing, runtime should keep the current bounded 202 behavior and bypass dedupe.

This preserves the behavior characterized before storage was added.

Strict rejection may be introduced later only after a separate contract PR.

### Step 3: Lookup active record

If `idempotency_key_hash` is present, runtime should look for an active record where:

```text
source_key matches
idempotency_key_hash matches
expires_at is in the future
```

If such a record exists, runtime should not enqueue duplicate source health work.

### Step 4: Reuse response

For an active matching record, runtime should return a bounded 202 response with:

```text
idempotency_status: reused
```

The response must remain admin-safe and must not expose raw identifiers.

### Step 5: Create record and enqueue

If no active matching record exists, runtime should:

```text
create idempotency record with status accepted
enqueue bounded health_checks work
store a bounded job_reference if safe
return bounded 202 response with idempotency_status accepted
```

### Step 6: Handle race conditions safely

If two requests race to create the same record, the loser should recover by reading the existing record and returning reused behavior.

A database unique constraint already exists on:

```text
source_key + idempotency_key_hash
```

Runtime should treat uniqueness conflicts as a reuse path, not a server error, when possible.

## Response contract

Future idempotency-aware response should preserve HTTP 202 for both accepted and reused requests.

Recommended accepted response concept:

```json
{
  "source_key": "example_source",
  "queue": "health_checks",
  "idempotency_status": "accepted"
}
```

Recommended reused response concept:

```json
{
  "source_key": "example_source",
  "queue": "health_checks",
  "idempotency_status": "reused"
}
```

The exact response shape must be locked by tests before runtime enforcement merges.

## Storage writes

Runtime may write only bounded fields:

```text
source_key
idempotency_key_hash
request_id_hash
actor_id_hash
status
job_reference
expires_at
last_seen_at
metadata
```

Runtime must not write:

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

## Expiry behavior

The initial dedupe window is:

```text
15 minutes
```

Implementation should calculate:

```text
expires_at = current time + 15 minutes
```

Expired records should not block new accepted work.

Cleanup of expired records is not required for the first runtime implementation, but should be designed later if storage growth becomes a concern.

## Audit boundary

This runtime contract does not implement full audit persistence.

Idempotency storage may include bounded audit-adjacent hashes, but it is not the final audit log.

Allowed audit-adjacent values:

```text
actor_id_hash
request_id_hash
idempotency_key_hash
```

Forbidden values remain raw identifiers and unredacted reason text.

## Required next tests

The next code PR should be test-first or test-mostly.

Required runtime tests:

```text
same source_key + same idempotency_key_hash -> first response accepted, second response reused
same source_key + different idempotency_key_hash -> both accepted
missing idempotency_key_hash -> bounded 202 and no idempotency record required
expired record -> new accepted behavior
read-only actor -> 403 and no idempotency record
unknown source -> 404 and no idempotency record
request body cannot choose queue, worker, operation, or payload shape
response does not expose raw actor/request/idempotency identifiers
storage does not persist raw/private/canonical material
```

## Recommended next PR

Recommended next PR:

```text
Add source health recheck idempotency runtime tests
```

Recommended scope:

```text
test-first or test-mostly
minimal runtime code only as needed to satisfy idempotency contract
no strict missing-key rejection yet
no audit persistence yet
no poll behavior expansion
no provider/materializer/canonical mutation
```

## Non-goals

This PR does not implement:

```text
runtime idempotency lookup/insert/reuse
a response shape change
a schema module
audit log persistence
audit log response references
strict missing-key rejection
expired record cleanup
job result lookup
poll behavior
provider fetch behavior
materializer behavior
canonical mutation
```

## Stop conditions

Stop and re-scope if future work:

```text
adds duplicate controller modules
lets source_health:read trigger recheck for existing source records
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
apps/backend/disclosure_api/docs/source_health_recheck_idempotency_runtime_contract.md
```

No Codex test command is required for this docs-only decision PR.
