# Source Health Recheck Positive Path Contract

## Status

This document defines the expected behavior for an authorized source health recheck request.

This is a docs-only decision. No runtime changes are included in this PR.

## Context

Previous work has already locked the following behaviors:

- Unknown source keys return a bounded 404 response
- Read-only actors are denied with a bounded 403 response
- Request-body operation overrides are ignored

However, the behavior for an authorized request using the `source_health:recheck` permission is not yet explicitly defined.

## Current Runtime Behavior

The current implementation calls:

```elixir
Sources.enqueue_source_health_recheck(source_key)
```

This results in a job being enqueued in the background queue.

## Decision

The system will explicitly support a **bounded enqueue model** for authorized recheck requests.

This means:

- The system will enqueue a background job
- The system will NOT perform provider calls inline
- The system will NOT trigger materializer or canonical updates directly

## Response Contract

Authorized requests will return a bounded accepted response.

Example response:

```json
{
  "job": {
    "status": "accepted"
  }
}
```

HTTP status:

```text
202 Accepted
```

## Guardrails

The following constraints remain enforced:

- No inline provider execution
- No scheduler expansion beyond the existing health check queue
- No materializer execution
- No canonical mutation
- No change to public response shape without a contract PR
- No exposure of raw or private data

## Non-goals

This PR does not define:

- Idempotency behavior
- Audit logging
- Polling or job result retrieval

These will be handled in future steps.

## Next Step

The next PR should introduce tests that validate the accepted response behavior for authorized requests.

## Validation

This is a docs-only PR. No test execution is required.
