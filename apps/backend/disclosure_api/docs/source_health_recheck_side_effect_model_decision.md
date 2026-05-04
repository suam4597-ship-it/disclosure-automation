# Source Health Recheck Side-effect Model Decision

## Status

Decision/design lock for the source health recheck side-effect model.

This document is docs-only. It does not change runtime behavior, tests, routes, controllers, providers, schedulers, materializers, canonical data, UI, or public API/feed behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 3355ab4c09826624dbe80bd25753394dcf55317c
base source: PR #202 Lock source health recheck positive characterization
stream: source health recheck side-effect model
status: docs-only decision/design
```

## Prior locks

The source health recheck track has already locked:

```text
unknown source key -> bounded 404
source_health:read -> bounded 403 for existing source recheck
request body operation override -> cannot bypass denial
positive path characterization -> authorized request currently returns 202 Accepted
positive path characterization -> response includes source_key and health_checks
positive path characterization -> override values do not leak into response
positive path characterization -> raw/private/canonical material does not leak into response
```

## Original default posture

The original safety posture remains important:

```text
stored-state evaluation by default unless a side effect is explicitly allowed, tested, and documented
```

The current runtime appears to use:

```elixir
Sources.enqueue_source_health_recheck(source_key)
```

PR #201 characterized that behavior through the HTTP route, but PR #201 did not approve it as the final model.

This document makes that decision.

## Decision

Approve a bounded `health_checks` enqueue model for the authorized `source_health:recheck` positive path.

This approval is narrow.

Approved behavior:

```text
source_health:recheck may enqueue source health work to the health_checks path
source_health:recheck may return 202 Accepted for an existing source
source_health:recheck response may include source_key and bounded queue characterization
```

Not approved:

```text
inline provider fetch
inline materializer execution
inline canonical mutation
poll route behavior expansion
request-body operation override of queue, worker, operation, or payload
raw/private response material
public API/feed response changes
```

## Why bounded enqueue is acceptable here

The bounded enqueue model is acceptable because the prior test gates established:

```text
only source_health:recheck can reach the existing-source positive path
source_health:read is denied for existing source recheck
unknown sources remain bounded 404
request body override does not surface unsafe operation fields
positive path response is bounded and includes health_checks characterization
raw/private/canonical material is not exposed in response
```

This does not mean all scheduler behavior is globally approved. It only means the source health recheck positive path may use the existing health-check enqueue mechanism as the explicitly documented side effect.

## Contract to lock next

The next code PR should turn this decision into a stronger runtime contract test.

It should verify, as directly as the current test stack allows:

```text
authorized source_health:recheck returns 202 Accepted
response includes source_key
response includes health_checks queue/path characterization
response does not include request override fields
response does not include raw/private/canonical material
source_health:read still receives 403 for existing source
unknown source still receives 404
route contract remains stable
```

If a queue/job inspection helper is available, the next PR should also verify:

```text
queue is health_checks
worker is source-health specific
payload contains only source_key or other bounded source-health metadata
request body cannot select a different queue or worker
```

If no queue/job inspection helper is available, the next PR should document that limitation and keep the current HTTP-level characterization as the lock until the helper exists.

## Idempotency remains separate

This decision does not solve repeated-call behavior.

Repeated authorized recheck calls may enqueue multiple jobs until a future idempotency PR decides otherwise.

Future idempotency work should define:

```text
idempotency key source
repeat request response
job de-duplication behavior
operator retry behavior
audit behavior
```

## Audit remains separate

This decision does not define audit logging.

Future audit work should define:

```text
actor identity representation
request id representation
reason redaction requirements
allowed audit fields
forbidden raw/private audit fields
```

## Guardrails that remain locked

Future source health recheck work must preserve:

```text
no duplicate controller modules
source_health:read cannot trigger recheck
unknown source keys remain bounded 404
request-body operation override cannot select poll/materialize/canonicalize/provider fetch behavior
response does not expose raw/private material
public response shape does not drift without contract approval
canonical mutation remains disallowed by default
poll behavior remains out of scope
```

## Recommended next PR

Recommended next PR:

```text
Add source health recheck bounded enqueue contract tests
```

Recommended scope:

```text
test-only or test-mostly
existing source fixture
source_health:recheck actor
HTTP-level 202/response-shape assertions
queue/job-level assertions only if helper exists
no runtime expansion beyond satisfying the bounded enqueue contract
no poll behavior expansion
no provider/materializer/canonical mutation
```

## Stop conditions

Stop and re-scope if future work:

```text
adds duplicate controller modules
lets source_health:read trigger recheck for existing source records
allows request-body operation override to select poll/materialize/canonicalize/provider fetch behavior
allows request body to select queue, worker, or job payload shape
changes public response shapes without a contract PR
calls provider clients inline
triggers materializers inline
mutates canonical data
shows secrets, headers, cookies, tokens, raw payloads, full article text, SQL details, stack traces, or unbounded diagnostics
```

## Validation

This PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_recheck_side_effect_model_decision.md
```

No Codex test command is required for this docs-only decision PR.
