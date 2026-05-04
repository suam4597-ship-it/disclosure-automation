# Source Health Recheck Idempotency Enforcement Model

## Status

Decision/design gate for the future source health recheck idempotency enforcement model.

This document is docs-only. It does not change runtime behavior, tests, routes, controllers, providers, schedulers, materializers, canonical data, UI, audit persistence, idempotency storage, or public API/feed behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 4c94f9093a862be9d2c12af972b03e9da7ebbd89
base source: PR #208 Lock source health recheck idempotency characterization
stream: source health recheck idempotency enforcement model
status: docs-only decision/design
```

## Prior characterization

PR #207 characterized current repeated-call behavior at the HTTP layer:

```text
same idempotency_key_hash repeated calls -> bounded 202 behavior
different idempotency_key_hash repeated calls -> bounded 202 behavior
missing idempotency_key_hash -> bounded 202 behavior
source_key / health_checks characterization -> preserved
raw actor/request/idempotency identifiers -> not exposed
unredacted reason -> not exposed
raw/private/canonical material -> not exposed
```

That means the current system is permissive. It does not yet enforce deduplication or strict idempotency.

## Decision

Choose the future enforcement target:

```text
Model 2: best-effort dedupe by source_key + idempotency_key_hash
```

This model should not be implemented until storage, expiry, retry semantics, and response behavior are explicitly designed and tested.

## Why not strict idempotency yet?

Strict idempotency would require rejecting requests that omit `idempotency_key_hash`.

The current characterized behavior accepts missing idempotency hashes with a bounded 202 response. Changing that immediately would be a behavior break for the internal operator route.

Therefore, missing idempotency hashes should remain temporarily accepted until a separate migration/contract PR says otherwise.

## Why not keep permissive repeated enqueue forever?

Permissive repeated enqueue is simple, but it creates operational risk:

```text
operator retries can create extra jobs
client retry storms can amplify queue load
reason/request correlation becomes harder
future audit trails become less useful
```

The best-effort dedupe model reduces these risks without requiring strict rejection immediately.

## Target model

Future runtime behavior should treat this pair as the best-effort idempotency key:

```text
source_key + idempotency_key_hash
```

If an authorized request repeats the same pair inside the chosen dedupe window, the system should avoid creating duplicate source health recheck work when possible.

The response may still be a bounded 202 response as long as the response contract clearly documents whether the request created new work or reused existing work.

## Required future response decision

Before implementation, decide one of these response shapes:

```text
Option A: always 202 Accepted with bounded status only
Option B: 202 Accepted with bounded idempotency status, such as accepted/reused
Option C: 200 OK for reused requests and 202 Accepted for new requests
```

Recommended default:

```text
Option B: 202 Accepted with bounded idempotency status
```

Rationale:

```text
It preserves the existing 202 contract while allowing operators and tests to distinguish new work from reused work.
```

## Required future storage decision

Before implementation, choose a storage mechanism for idempotency records.

Required fields should be bounded and redacted:

```text
source_key
idempotency_key_hash
request_id_hash
actor_id_hash
created_at
expires_at
status
bounded job reference if safe
```

Forbidden fields:

```text
raw actor id
raw request id
raw idempotency key
unredacted reason
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

## Required future expiry decision

The dedupe window must be finite.

Candidate options:

```text
short operational window, such as 5 to 15 minutes
medium operational window, such as 1 hour
long audit-oriented window, such as 24 hours
```

Recommended default for the first implementation:

```text
short operational window
```

Rationale:

```text
The route is an operator-triggered bounded recheck. The first goal is retry safety, not long-term audit indexing.
```

## Required future tests

The next test/design PR should define tests before runtime enforcement.

Required tests:

```text
same source_key + same idempotency_key_hash returns bounded response and does not create duplicate work when enforcement exists
same source_key + different idempotency_key_hash remains allowed
missing idempotency_key_hash remains temporarily accepted or is explicitly migrated to rejection
response does not expose raw actor/request/idempotency values
response does not expose unredacted reason
read-only actor remains 403
unknown source remains 404
request body operation/queue/worker/payload override remains ignored
```

## Recommended next PR

Recommended next PR:

```text
Design source health recheck idempotency storage contract
```

Recommended scope:

```text
docs-only decision/design first
choose storage table or existing job metadata approach
choose expiry window
choose reused/new response shape
choose bounded audit fields
no runtime dedupe implementation yet
```

## Non-goals

This PR does not implement:

```text
idempotency storage
job deduplication
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
apps/backend/disclosure_api/docs/source_health_recheck_idempotency_enforcement_model.md
```

No Codex test command is required for this docs-only decision PR.
