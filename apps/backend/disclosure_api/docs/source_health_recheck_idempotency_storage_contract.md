# Source Health Recheck Idempotency Storage Contract

## Status

Decision/design contract for future source health recheck idempotency storage.

This document is docs-only. It does not change runtime behavior, tests, routes, controllers, database migrations, schemas, providers, schedulers, materializers, canonical data, UI, audit persistence, or public API/feed behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 880bb739ceddaa5227bc16cdbd5d9c469ca1070d
base source: PR #209 Decide source health recheck idempotency enforcement model
stream: source health recheck idempotency storage contract
status: docs-only decision/design
```

## Prior decision

The future idempotency enforcement target is:

```text
best-effort dedupe by source_key + idempotency_key_hash
```

This contract defines what must be stored before that model is implemented.

## Storage decision

Use a dedicated idempotency storage record for source health recheck.

Preferred future table name:

```text
source_health_recheck_idempotency_keys
```

A dedicated table is preferred over embedding this state only in job metadata because idempotency is an operator request boundary, not just a queue implementation detail.

## Required key

The best-effort dedupe key is:

```text
source_key + idempotency_key_hash
```

This pair should be unique within the active dedupe window.

## Required fields

Future storage records should contain only bounded, redacted fields:

```text
id
source_key
idempotency_key_hash
request_id_hash
actor_id_hash
status
job_reference
created_at
expires_at
last_seen_at
metadata
```

`job_reference` must be bounded. It may store a safe job id or safe queue reference if available, but it must not store raw queue internals that expose private payloads.

`metadata` must remain bounded and optional. It should not become a dump of request headers, provider responses, worker internals, or raw payloads.

## Forbidden fields

Future storage records must not contain:

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

## Expiry decision

Use a short operational dedupe window for the first implementation.

Recommended first value:

```text
15 minutes
```

Rationale:

```text
The immediate goal is operator retry safety and queue amplification control, not long-term audit indexing.
```

Longer retention can be designed later as part of audit persistence.

## Status values

Future storage records should use a bounded status enum.

Recommended values:

```text
accepted
reused
expired
failed
```

Initial implementation may only need:

```text
accepted
reused
```

## Response contract decision

Use the following future response model:

```text
202 Accepted for both newly accepted and reused requests
```

The response should include a bounded idempotency status field if runtime implementation supports it.

Recommended response concept:

```json
{
  "source_key": "example_source",
  "queue": "health_checks",
  "idempotency_status": "accepted"
}
```

For a repeated request within the dedupe window:

```json
{
  "source_key": "example_source",
  "queue": "health_checks",
  "idempotency_status": "reused"
}
```

The exact response shape must be locked by tests before runtime enforcement is merged.

## Missing idempotency key behavior

The current characterized behavior accepts missing `idempotency_key_hash` with bounded 202.

Do not change that in the first storage implementation unless a separate contract PR approves the behavior change.

Recommended first implementation behavior:

```text
missing idempotency_key_hash -> bypass dedupe but keep bounded 202 response
```

Future strict behavior can be considered later.

## Race behavior

Future implementation should handle concurrent duplicate requests safely.

Expected behavior:

```text
first request creates idempotency record and enqueues source health work
second request with same source_key + idempotency_key_hash reuses the existing record when possible
both responses remain bounded and admin-safe
```

A database unique constraint should be considered for:

```text
source_key + idempotency_key_hash + active dedupe window
```

If active-window uniqueness is difficult at the database level, the implementation should document the limitation and use best-effort transactional lookup/insert behavior.

## Audit boundary

Idempotency storage is not the full audit log.

It may contain bounded audit-adjacent hashes:

```text
actor_id_hash
request_id_hash
idempotency_key_hash
```

But it must not contain raw identifiers or unredacted reasons.

A future audit persistence PR may link to idempotency records, but that should be designed separately.

## Required future tests

Before runtime implementation is considered complete, add tests for:

```text
same source_key + same idempotency_key_hash returns bounded reused behavior within window
same source_key + different idempotency_key_hash remains accepted as separate work
missing idempotency_key_hash remains bounded and does not expose raw identifiers
expired idempotency record allows new accepted work
stored fields contain only bounded redacted values
response does not expose raw actor/request/idempotency identifiers
read-only actor remains 403
unknown source remains 404
request body cannot choose queue, worker, operation, or payload shape
```

## Recommended next PR

Recommended next PR:

```text
Add source health recheck idempotency storage design close-out
```

or, if moving to code next:

```text
Add source health recheck idempotency storage migration tests
```

Use the close-out PR first if reviewers want the storage contract locked before writing migrations.

## Non-goals

This PR does not implement:

```text
database migration
schema module
runtime dedupe
strict missing-key rejection
audit log persistence
audit log response references
retry semantics
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
apps/backend/disclosure_api/docs/source_health_recheck_idempotency_storage_contract.md
```

No Codex test command is required for this docs-only decision PR.
