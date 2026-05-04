# Source Health Recheck Authorization Test Gate Close-out

This document closes out the source health recheck authorization test-gate PR after local validation and merge.

This close-out PR is documentation-only. It does not add or modify frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit before authorization test gate: 9e54b1c42c5b3be286a2700fd90b54ca7aa20939
base source: PR #197 Design source health recheck authorization gap
merged test gate: PR #198 Add source health recheck authorization test gate
merged test gate commit: 5151a4c8d5413f467b53942b5d2a597006bbbbca
stream: source health recheck authorization test-gate close-out
status: docs-only
```

## Evidence

```text
PR #198 Add source health recheck authorization test gate
initial failing head: 6ddc251ed303566b74abeaf78ad043332f47f205
fixed validated head: 1622d18d502b558cd1334efc13cd9d7483ac11f4
changed files: 3
runtime change: source health recheck authorization plug and route pipeline
router change: recheck POST route routed through authorization pipeline
added test: apps/backend/disclosure_api/test/source_health_recheck_authorization_test.exs
merge commit: 5151a4c8d5413f467b53942b5d2a597006bbbbca
```

## Initial validation failure

The first local validation failed before exercising authorization behavior because the test fixture used an invalid `source_type`.

Failure:

```text
Ecto.ConstraintError
source_registry_source_type_check
```

Invalid fixture value:

```elixir
"source_type" => "test_fixture"
```

Allowed source types include:

```text
rss
atom
json_feed
html
api
email
```

The fixture was fixed to use:

```elixir
"source_type" => "api"
```

## Final local validation recorded

Validated head:

```text
1622d18d502b558cd1334efc13cd9d7483ac11f4
```

Targeted authorization test:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_recheck_authorization_test.exs
```

Result:

```text
3 tests, 0 failures
```

Adjacent regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs
```

Result:

```text
14 tests, 0 failures
```

## Confirmed validation findings

Local validation confirmed:

```text
SourceHealthRecheckAuthorization compile error: none
authorization test: 3 tests, 0 failures
route contract drift: none
adjacent regression: 14 tests, 0 failures
new duplicate controller warning: none
```

Existing compile warnings and the existing `Phoenix.ConnTest` deprecation warning remain non-blocking for this track.

## Locked behavior from PR #198

The authorization test gate now covers an existing source record for:

```text
POST /api/admin/source-health/:source_key/recheck
```

The merged tests and route gate lock:

```text
source_health:read cannot trigger recheck for an existing source
request-body operation override cannot bypass read-only denial
unknown source still returns bounded 404 before authorization denial
denial responses are bounded and public/admin-safe
accepted job fields are not returned on denied or unknown-source paths
```

## Implementation shape locked

PR #198 added:

```text
DisclosureAutomationWeb.SourceHealthRecheckAuthorization
```

PR #198 routed only the source health recheck POST route through the authorization pipeline.

Existing source health controller modules remain in:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers.ex
```

No duplicate controller modules were added.

## What remains unimplemented

PR #198 does not complete the full recheck runtime track.

Still not locked by this close-out:

```text
positive source_health:recheck accepted/queued response contract
idempotency behavior for repeated authorized recheck calls
provider side-effect absence or explicit bounded enqueue behavior
scheduler side-effect absence or explicit bounded enqueue behavior
materializer side-effect absence instrumentation
canonical no-mutation instrumentation
audit log contract for authorized recheck
response contract for authorized existing-source recheck
```

## Recommended next track

Recommended next PR:

```text
Design source health recheck positive-path contract
```

Recommended scope:

```text
docs-only decision/design first
explicitly define whether authorized recheck returns accepted queued job or stored-state evaluation
lock response shape before changing more runtime behavior
classify Sources.enqueue_source_health_recheck(source_key) as either intentionally bounded scheduler enqueue or future implementation gap
keep poll behavior out of scope
keep provider/materializer/canonical mutation out of scope
```

Rationale:

```text
The read-only denial path is now locked for existing sources.
The unknown-source path remains bounded 404.
The next risk is the authorized positive path, because current runtime can enqueue source health recheck work.
That side effect must be explicitly accepted, narrowed, or replaced before expanding implementation.
```

## Stop conditions

Stop and re-scope if future source health recheck work:

```text
adds duplicate controller modules
lets source_health:read trigger recheck for existing source records
allows request-body operation override to select poll/materialize/canonicalize/provider fetch behavior
changes public response shapes without a contract PR
calls provider clients unexpectedly
triggers scheduler work unexpectedly without explicit design approval
triggers materializers unexpectedly
mutates canonical data unexpectedly
shows secrets, headers, cookies, tokens, raw payloads, full article text, SQL details, stack traces, or unbounded diagnostics
```

## Validation for this close-out PR

This close-out PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_recheck_authorization_test_gate_closeout.md
```

No Codex test command is required for this docs-only close-out PR.
