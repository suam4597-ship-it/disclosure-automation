# Source Health Recheck Implementation Test Gate Decision

## Status

Decision/design lock for the next source health PR.

This document is docs-only. It does not change route behavior, controller code, source polling, source health recheck execution, or any authorization/runtime paths.

## Context

The source health route target verification track is complete and locked. The current verified route surface is:

```text
GET  /api/admin/source-health
GET  /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

The existing source health controllers are defined in:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers.ex
```

Do not add duplicate controller modules in separate files for:

```text
DisclosureAutomationWeb.AdminSourceHealthController
DisclosureAutomationWeb.AdminSourcePollController
```

The current `recheck` runtime may call:

```elixir
Sources.enqueue_source_health_recheck(source_key)
```

That creates a gap with the previously locked source health design expectation: by default, source health recheck should be treated as bounded stored-state evaluation unless a side effect is explicitly allowed, tested, and documented.

Before changing runtime behavior, the next implementation step should lock the tests and gates that define which behavior is acceptable.

## Decision

Choose the implementation path that adds a test gate before runtime changes.

```text
Track A: source health recheck behavior tests design
```

This means the next code-changing PR should define and run bounded behavior tests first, then adjust runtime only as needed to satisfy those tests.

## Why not start runtime implementation immediately?

Runtime implementation is not blocked forever, but it is too easy to change behavior before the operator boundary is pinned down.

The risky areas are:

```text
- authorization semantics for recheck
- request body operation override handling
- idempotency and repeated recheck behavior
- public response shape stability
- raw/private material exposure
- canonical mutation risk
- provider/scheduler/materializer side effects
```

Because the route may enqueue work today, the next safe step is to define exactly when enqueueing is allowed and how it is proven safe.

## Required gate before runtime implementation

The next implementation PR should include tests or explicit documentation for all of the following before changing recheck runtime behavior.

### 1. Request body operation override is rejected or ignored safely

A caller must not be able to change the operation by sending a request body override.

Examples of unsafe caller-controlled intent:

```json
{"operation":"poll"}
{"operation":"materialize"}
{"operation":"canonicalize"}
{"action":"provider_fetch"}
```

The route must remain a bounded source health recheck endpoint, not a generic source operation dispatcher.

### 2. Read-only permission cannot trigger recheck

A principal with read-only source health access may read source health state but must not be able to trigger recheck behavior.

The test gate should distinguish at least:

```text
source_health:read     => list/show only
source_health:recheck  => POST /api/admin/source-health/:source_key/recheck
source_health:poll     => POST /api/admin/sources/:source_key/poll, still gated/high-risk
```

If the current permission model does not yet support this separation, the next PR should document the gap and avoid expanding runtime behavior until it is resolved.

### 3. `source_health:recheck` permission model is explicit

The recheck route must have a named permission or gate. It should not inherit broad admin access accidentally unless that is explicitly documented as the current temporary behavior.

The test gate should clarify whether the route requires:

```text
- source_health:recheck
- a broader source_health:write permission
- a temporary admin-only capability
```

The selected model must be documented before runtime expansion.

### 4. Unknown `source_key` remains bounded 404

Unknown source keys should keep returning a bounded 404 response.

The 404 path must not:

```text
- create new source records
- enqueue provider work
- enqueue scheduler work
- enqueue materializer work
- mutate canonical data
- expose internal source lookup details
```

### 5. Response contains no raw/private material

The recheck response must not expose raw provider payloads, private source config, credentials, headers, tokens, scheduler internals, materializer internals, or canonical raw material.

Allowed response material should be bounded to public/admin-safe source health fields, such as:

```text
- source_key
- status or health state
- checked/rechecked timestamp when safe
- bounded reason/status code when safe
- accepted/queued marker when explicitly part of the contract
```

### 6. Public response shape does not drift accidentally

The public/admin response shape should stay compatible with the locked source health route contract.

Any intentional response shape change must be:

```text
- documented
- covered by tests
- treated as contract-affecting
```

### 7. Canonical mutation remains disallowed by default

Recheck must not mutate canonical disclosure data by default.

If any future implementation needs canonical mutation, that must become a separate explicit track with its own authorization, idempotency, audit, and rollback design.

### 8. Provider/scheduler/materializer side effects are explicit

If `Sources.enqueue_source_health_recheck(source_key)` or an equivalent function schedules work, the behavior must be classified explicitly.

The next implementation gate should answer:

```text
Does recheck only evaluate stored state synchronously?
Does recheck enqueue source health work asynchronously?
Does recheck touch provider fetch paths?
Does recheck touch scheduler paths?
Does recheck touch materializer paths?
```

Any provider, scheduler, or materializer side effect must be covered by either:

```text
- a focused test proving the side effect is absent, or
- a focused test proving the side effect is intentionally bounded, authorized, and idempotent, or
- an explicit docs lock saying the behavior remains out of scope and gated.
```

## Proposed next PR after this decision

Recommended next PR:

```text
Add source health recheck behavior test gate
```

Recommended scope:

```text
- test-only or mostly test-only
- no duplicate controller files
- no public response shape expansion unless documented
- no poll route implementation expansion
- no provider/materializer/canonical mutation
```

Candidate test names:

```text
source_health_recheck_behavior_test.exs
source_health_recheck_authorization_test.exs
source_health_recheck_side_effect_test.exs
```

The exact file split can be decided when inspecting the current test layout.

## Non-goals

This decision does not implement runtime behavior.

This decision does not unlock the poll route.

This decision does not add new controller modules.

This decision does not remove existing compile warnings or the existing Phoenix.ConnTest deprecation warning.

## Codex test command

No Codex test command is required for this docs-only decision PR.
