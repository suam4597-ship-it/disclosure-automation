# Source Health Recheck Authorization Gap Decision

## Status

Decision/design lock for the source health recheck authorization gap.

This document is docs-only. It does not change runtime behavior, tests, routes, controllers, providers, schedulers, materializers, canonical data, or public API/feed behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 91c2d95f6a09a982ca7ba30d724fcbb459805c2b
base source: PR #196 Lock source health recheck behavior test gate
stream: source health recheck authorization gap
status: docs-only decision/design
```

## Current route and controller target

The recheck route remains:

```text
POST /api/admin/source-health/:source_key/recheck
```

The existing controller remains in:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers.ex
```

Do not add duplicate controller modules for:

```text
DisclosureAutomationWeb.AdminSourceHealthController
DisclosureAutomationWeb.AdminSourcePollController
```

## Current implementation finding

The current controller action delegates directly to source health enqueue behavior:

```elixir
def recheck(conn, %{"source_key" => source_key}) do
  case Sources.enqueue_source_health_recheck(source_key) do
    {:ok, job} ->
      conn
      |> put_status(:accepted)
      |> json(SourceHealthJSON.accepted_job(%{job: job}))

    {:error, :not_found} ->
      render_error(conn, :not_found, "not_found", "source not found")

    {:error, reason} ->
      render_error(conn, :bad_request, "enqueue_failed", inspect(reason))
  end
end
```

That means the authorization model for an existing source record is not yet locked by tests.

PR #195 locked the unknown-source behavior gate, but it did not prove that a read-only actor is denied for an existing source record.

## Decision

Choose the next implementation path that locks authorization before runtime expansion:

```text
Track A: source health recheck authorization test design
```

The next code-changing PR should be focused on tests that prove the authorization boundary for recheck before changing runtime behavior beyond the minimum needed to satisfy the gate.

## Required authorization model

The source health permission model should distinguish read and mutation-like operations:

```text
source_health:read     => list/show only
source_health:recheck  => POST /api/admin/source-health/:source_key/recheck
source_health:poll     => POST /api/admin/sources/:source_key/poll, still gated/high-risk
```

A caller with only `source_health:read` must not trigger recheck behavior for an existing source record.

A caller with `source_health:recheck` may trigger recheck only within the locked bounded route contract.

If the repository currently uses broader admin-only authorization instead of named permissions, the next PR should document that explicitly and prevent accidental read-only escalation.

## Required behavior for the next test gate

The next test PR should cover an existing source record, not only an unknown source key.

It should prove:

```text
read-only actor payload does not enqueue recheck for an existing source
read-only actor payload receives a bounded denial response
source_health:recheck actor payload is the only accepted positive authorization path, unless a temporary broader admin capability is explicitly documented
request-body operation override does not change the route operation
bounded denial response exposes no raw/private material
public/admin response shape remains stable
no duplicate controller files are added
```

## Candidate response contract

Preferred denial response for unauthorized recheck:

```json
{
  "error": {
    "code": "forbidden",
    "message": "source health recheck not allowed"
  }
}
```

Preferred HTTP status:

```text
403 Forbidden
```

If the existing project has a different canonical forbidden response shape, use the existing shape and document the reason before implementation.

## Positive-path authorization contract

The positive path should require an explicit mutation-like capability.

Preferred capability:

```text
source_health:recheck
```

The positive path must still preserve the already locked guardrails:

```text
no request-body operation override
no raw/private response material
no public response shape drift
no canonical mutation by default
provider/scheduler/materializer effects must be explicit
unknown source keys remain bounded 404
```

## Open implementation questions

The next PR should inspect the current test fixtures and authorization helpers before deciding exact implementation shape.

Questions to answer:

```text
Where are actor permissions currently parsed?
Are source health admin routes currently protected only by route scope?
Is there an existing plug/helper for permission checks?
Should permission checks read actor_permissions from request body temporarily for test-gate purposes, or should they use an existing conn assign/session/auth mechanism?
Can a source registry fixture be created without triggering provider/scheduler/materializer behavior?
What is the canonical forbidden JSON shape in this app?
```

## Non-goals

This PR does not implement authorization.

This PR does not change `AdminSourceHealthController.recheck/2`.

This PR does not change `Sources.enqueue_source_health_recheck/1`.

This PR does not add tests.

This PR does not unlock poll behavior.

This PR does not introduce a new controller file.

## Recommended next PR

Recommended next PR:

```text
Add source health recheck authorization test gate
```

Recommended scope:

```text
test-first or test-mostly
existing source record fixture only if safe
minimal runtime change only if required to satisfy authorization gate
no duplicate controller modules
no poll behavior expansion
no provider/materializer/canonical mutation
```

Recommended Codex check after that future PR:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_recheck_authorization_test.exs
```

Adjacent regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs
```

## Stop conditions

Stop and re-scope if future source health recheck authorization work:

```text
adds duplicate controller modules
lets source_health:read trigger recheck for existing source records
allows request-body operation override to select poll/materialize/canonicalize/provider fetch behavior
changes public response shapes without a contract PR
calls provider clients unexpectedly
triggers scheduler work unexpectedly
triggers materializers unexpectedly
mutates canonical data unexpectedly
shows secrets, headers, cookies, tokens, raw payloads, full article text, SQL details, stack traces, or unbounded diagnostics
```

## Validation for this PR

This PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_recheck_authorization_gap_decision.md
```

No Codex test command is required for this docs-only decision PR.
