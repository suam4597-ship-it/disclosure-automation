# Source Health Recheck Positive Path Decision Gate

## Status

Corrected docs-only decision gate for the authorized `source_health:recheck` positive path.

This document does **not** approve a new runtime model and does **not** change runtime behavior.

## Correction

A prior draft of this document incorrectly selected a bounded enqueue model as the positive-path contract.

That was too aggressive.

The previously locked design says source health recheck should be treated as bounded stored-state evaluation by default unless a side effect is explicitly allowed, tested, and documented.

The current runtime may call:

```elixir
Sources.enqueue_source_health_recheck(source_key)
```

That call is still a behavior gap to classify. It should not be treated as an approved model until the side effect boundary and response contract are proven.

## Context

Previous source health recheck work has already locked these behaviors:

```text
unknown source key -> bounded 404
source_health:read -> bounded 403 for existing source recheck
request body operation override -> cannot bypass denial
raw/private response material -> forbidden
```

The remaining question is the authorized positive path:

```text
POST /api/admin/source-health/:source_key/recheck
actor permission: source_health:recheck
source_key: existing source
```

## Current implementation finding

The current controller delegates to:

```elixir
Sources.enqueue_source_health_recheck(source_key)
```

That appears to enqueue background work. It may be the intended final behavior, or it may be a transitional implementation that conflicts with the stored-state-by-default model.

This document intentionally does not decide that question.

## Decision

Do not bless the enqueue model yet.

Choose the next safe path:

```text
Track A: positive-path characterization and side-effect classification
```

The next PR should characterize what the authorized positive path currently does and classify it before expanding or relying on it.

## Models under consideration

### Model 1: stored-state evaluation by default

This model treats recheck as a bounded admin-safe evaluation of existing source health state.

Expected properties:

```text
no provider call
no scheduler enqueue
no materializer execution
no canonical mutation
bounded response shape
```

This remains the default safety model until another model is explicitly approved.

### Model 2: bounded enqueue

This model treats authorized recheck as a bounded background health-check enqueue.

This model may be acceptable only if the next PR proves and documents:

```text
queue is restricted to source health work
accepted response shape is stable and public/admin-safe
no provider fetch occurs inline
no materializer runs inline
no canonical data mutates inline
request body cannot alter operation, queue, worker, or payload shape
idempotency risk is acknowledged or gated
```

### Model 3: hybrid transitional behavior

This model acknowledges that current runtime enqueues, but keeps it classified as transitional until stronger tests exist.

This is acceptable only as a short-lived bridge if the next PR clearly documents the gap and adds focused characterization tests.

## Required next test or audit gate

The next implementation PR should not simply assert that 202 Accepted is correct.

It should first answer:

```text
Does source_health:recheck currently enqueue work?
Which queue is used?
Which worker is used?
What response fields are returned?
Can the request body alter queue, worker, operation, or payload?
Does any provider fetch happen inline?
Does any materializer run inline?
Does any canonical data change inline?
```

## Allowed next PR shape

Recommended next PR:

```text
Add source health recheck positive-path characterization tests
```

Recommended scope:

```text
test-first or test-mostly
existing source fixture only
source_health:recheck actor only
no poll behavior expansion
no duplicate controller modules
no provider/materializer/canonical mutation
```

If the characterization proves bounded enqueue is already safe, a later docs PR can explicitly approve the bounded enqueue model.

If the characterization exposes broader side effects, the next track should narrow runtime toward stored-state evaluation or split the side effect behind a more explicit operator action.

## Guardrails that remain locked

Future positive-path work must preserve:

```text
source_health:read cannot trigger recheck
unknown source keys remain bounded 404
request body operation override cannot select poll/materialize/canonicalize/provider fetch behavior
response does not expose raw/private material
public response shape does not drift without contract approval
canonical mutation remains disallowed by default
poll behavior remains out of scope
```

## Non-goals

This PR does not implement or approve:

```text
bounded enqueue as final model
stored-state rewrite
idempotency behavior
audit logging
job result polling
provider fetch behavior
materializer behavior
canonical mutation
```

## Validation

This PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_recheck_positive_path_contract.md
```

No Codex test command is required for this corrected docs-only decision gate.
