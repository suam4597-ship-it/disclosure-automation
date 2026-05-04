# Source Health Recheck Idempotency and Audit Gate

## Status

Decision/design gate for source health recheck idempotency and audit behavior.

This document is docs-only. It does not change runtime behavior, tests, routes, controllers, providers, schedulers, materializers, canonical data, UI, or public API/feed behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 0960b880b9c8fd03d3c5f1cabe01dd4d9d42c2ca
base source: PR #205 Lock source health recheck bounded enqueue contract
stream: source health recheck idempotency and audit gate
status: docs-only decision/design
```

## Prior locks

The source health recheck track has already locked:

```text
unknown source key -> bounded 404
source_health:read -> bounded 403 for existing source recheck
source_health:recheck -> bounded 202 for existing source positive path
positive path response -> source_key and health_checks characterization
request body operation override -> does not alter response contract
request body queue/worker/payload override -> does not appear in response
raw/private/canonical response material -> forbidden
bounded health_checks enqueue model -> approved at the HTTP contract layer
```

## Remaining gap

The bounded enqueue model is now approved for the authorized positive path, but repeated calls and audit behavior remain undefined.

Open questions:

```text
Should repeated authorized recheck calls enqueue multiple jobs?
Should idempotency key hashes collapse repeated requests?
Should missing idempotency key hashes be accepted or rejected?
Which actor/request/reason fields may be recorded for audit?
Which fields must never be recorded or returned?
```

## Decision

Do not implement runtime idempotency yet.

Choose a two-step path:

```text
Track A: document and test observed repeated-call behavior first
Track B: add explicit idempotency enforcement only after observed behavior is locked
```

This means repeated authorized recheck calls may remain permissive temporarily, but the behavior must be characterized and documented before any stronger deduplication or audit persistence is added.

## Idempotency model for the next test gate

The next PR should characterize repeated-call behavior at the HTTP contract layer.

Required checks:

```text
same source_key + same idempotency_key_hash + source_health:recheck remains bounded
same source_key + different idempotency_key_hash + source_health:recheck remains bounded
missing idempotency_key_hash behavior is explicitly observed
response does not expose raw idempotency key
response does not expose raw request id
response does not expose raw actor id
response does not expose unredacted reason
```

The next PR should not assert deduplication unless the current runtime already supports it.

If duplicate enqueue behavior is observed, document it as current behavior and leave deduplication for a later runtime PR.

## Future idempotency enforcement options

Future runtime work may choose one of these models:

```text
Model 1: permissive repeated enqueue with audit-only idempotency metadata
Model 2: best-effort dedupe by source_key + idempotency_key_hash
Model 3: strict idempotency requiring idempotency_key_hash for all recheck requests
```

No model is implemented by this PR.

Recommended future default:

```text
Model 2: best-effort dedupe by source_key + idempotency_key_hash
```

But only after a dedicated implementation PR defines storage, expiry, retry semantics, and response behavior.

## Audit model for the next design gate

Audit behavior should remain bounded and redacted.

Allowed audit inputs:

```text
source_key
actor_id_hash
request_id_hash
idempotency_key_hash
reason_redacted
redaction_status
actor_permissions
created_at
route operation derived from route, not request body
```

Forbidden audit inputs:

```text
raw_actor_id
raw_request_id
raw_idempotency_key
unredacted_reason
provider credentials
headers
cookies
tokens
raw provider payloads
full article text
SQL details
stack traces
canonical payloads
private actor context
unbounded diagnostics
```

Audit should not be exposed in the immediate response unless a future response contract explicitly approves bounded audit references.

## Response guardrails

The response must continue to preserve:

```text
no raw actor id
no raw request id
no raw idempotency key
no unredacted reason
no provider credentials
no raw/private/canonical material
```

## Recommended next PR

Recommended next PR:

```text
Add source health recheck idempotency characterization tests
```

Recommended scope:

```text
test-only or test-mostly
existing source fixture
source_health:recheck actor
same idempotency_key_hash repeated request characterization
different idempotency_key_hash repeated request characterization
missing idempotency_key_hash characterization if currently accepted
response redaction assertions
no runtime dedupe implementation yet
no audit persistence implementation yet
```

## Non-goals

This PR does not implement:

```text
idempotency storage
job deduplication
audit log persistence
audit log response fields
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
returns raw actor/request/idempotency identifiers
returns unredacted reason
persists or returns secrets, headers, cookies, tokens, raw payloads, full article text, SQL details, stack traces, or unbounded diagnostics
changes public response shapes without a contract PR
calls provider clients inline
triggers materializers inline
mutates canonical data
```

## Validation

This PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_recheck_idempotency_audit_gate.md
```

No Codex test command is required for this docs-only decision PR.
